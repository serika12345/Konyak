import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:json_schema/json_schema.dart';

import '../domain/program/program_profile_catalog.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import '../storage/storage_paths.dart';
import 'platform_host_paths.dart';

const konyakProfileDirectoryEnvironmentVariable = 'KONYAK_PROFILE_DIRECTORY';
const konyakUserProfileDirectoryEnvironmentVariable =
    'KONYAK_USER_PROFILE_DIRECTORY';
const konyakProfileSchemaFileName = 'profile.schema.json';
const konyakProfileSchemaUri =
    'https://raw.githubusercontent.com/serika12345/Konyak/main/'
    'packages/konyak_cli/profiles/profile.schema.json';

class DartIoInstallProfileCatalog {
  const DartIoInstallProfileCatalog._();

  static InstallProfileCatalog deferredCurrent() {
    return InstallProfileCatalog.deferred(() {
      try {
        return current();
      } on FileSystemException catch (error) {
        throw InstallProfileCatalogException(error.toString());
      } on FormatException catch (error) {
        throw InstallProfileCatalogException(error.message);
      } on ArgumentError catch (error) {
        throw InstallProfileCatalogException(error.message.toString());
      }
    });
  }

  static InstallProfileCatalog current() {
    return DartIoInstallProfileLibrary.current().loadCatalog();
  }

  static InstallProfileCatalog fromDirectory(
    String directoryPath, {
    required String schemaPath,
  }) {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException(
        'Profile directory does not exist.',
        directoryPath,
      );
    }

    final schema = _profileSchemaFromFile(File(schemaPath));

    final profileFiles =
        directory
            .listSync(followLinks: false)
            .whereType<File>()
            .where(
              (file) =>
                  file.uri.pathSegments.last != konyakProfileSchemaFileName,
            )
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList(growable: false)
          ..sort((left, right) => left.path.compareTo(right.path));
    return InstallProfileCatalog(
      profileFiles.map((file) => _installProfileFromFile(file, schema)),
    );
  }
}

const konyakMaxProfileManifestBytes = 1024 * 1024;

enum InstallProfileLibraryFailureCode {
  invalidProfile('invalidProfile'),
  profileConflict('profileConflict'),
  profileModified('profileModified'),
  profileNotFound('profileNotFound'),
  profileReadOnly('profileReadOnly'),
  profileIoFailure('profileIoFailure');

  const InstallProfileLibraryFailureCode(this.value);

  final String value;
}

final class ProfileValidationIssue {
  const ProfileValidationIssue({required this.path, required this.message});

  final String path;
  final String message;
}

sealed class InstallProfileLibraryResult {
  const InstallProfileLibraryResult();
}

final class InstallProfileValidated extends InstallProfileLibraryResult {
  const InstallProfileValidated(this.profile);

  final InstallProfileRecord profile;
}

final class InstallProfileImported extends InstallProfileLibraryResult {
  const InstallProfileImported(this.profile);

  final InstallProfileRecord profile;
}

final class InstallProfileUpdated extends InstallProfileLibraryResult {
  const InstallProfileUpdated(this.profile);

  final InstallProfileRecord profile;
}

final class InstallProfileExported extends InstallProfileLibraryResult {
  const InstallProfileExported({required this.profile, required this.path});

  final InstallProfileRecord profile;
  final String path;
}

final class InstallProfileDeleted extends InstallProfileLibraryResult {
  const InstallProfileDeleted({
    required this.profileId,
    required this.profileDigest,
  });

  final ProfileId profileId;
  final ProfileManifestDigest profileDigest;
}

final class InstallProfileLibraryFailure extends InstallProfileLibraryResult {
  InstallProfileLibraryFailure({
    required this.code,
    required this.message,
    Iterable<ProfileValidationIssue> issues = const <ProfileValidationIssue>[],
  }) : issues = List.unmodifiable(issues);

  final InstallProfileLibraryFailureCode code;
  final String message;
  final List<ProfileValidationIssue> issues;
}

abstract interface class InstallProfileLibrary {
  InstallProfileCatalog loadCatalog();

  InstallProfileLibraryResult validateProfile(String sourcePath);

  InstallProfileLibraryResult importProfile(String sourcePath);

  InstallProfileLibraryResult updateProfile({
    required ProfileId profileId,
    required ProfileManifestDigest expectedDigest,
    required String sourcePath,
  });

  InstallProfileLibraryResult exportProfile({
    required ProfileId profileId,
    required String destinationPath,
  });

  InstallProfileLibraryResult deleteProfile({
    required ProfileId profileId,
    required ProfileManifestDigest expectedDigest,
  });
}

final class DeferredInstallProfileLibrary implements InstallProfileLibrary {
  DeferredInstallProfileLibrary(this._loader);

  final InstallProfileLibrary Function() _loader;
  late final InstallProfileLibrary _loaded = _loader();

  @override
  InstallProfileCatalog loadCatalog() => _loaded.loadCatalog();

  @override
  InstallProfileLibraryResult validateProfile(String sourcePath) =>
      _loaded.validateProfile(sourcePath);

  @override
  InstallProfileLibraryResult importProfile(String sourcePath) =>
      _loaded.importProfile(sourcePath);

  @override
  InstallProfileLibraryResult updateProfile({
    required ProfileId profileId,
    required ProfileManifestDigest expectedDigest,
    required String sourcePath,
  }) => _loaded.updateProfile(
    profileId: profileId,
    expectedDigest: expectedDigest,
    sourcePath: sourcePath,
  );

  @override
  InstallProfileLibraryResult exportProfile({
    required ProfileId profileId,
    required String destinationPath,
  }) => _loaded.exportProfile(
    profileId: profileId,
    destinationPath: destinationPath,
  );

  @override
  InstallProfileLibraryResult deleteProfile({
    required ProfileId profileId,
    required ProfileManifestDigest expectedDigest,
  }) => _loaded.deleteProfile(
    profileId: profileId,
    expectedDigest: expectedDigest,
  );
}

class DartIoInstallProfileLibrary implements InstallProfileLibrary {
  const DartIoInstallProfileLibrary({
    required this.builtinDirectory,
    required this.userDirectory,
    required this.schemaPath,
  });

  factory DartIoInstallProfileLibrary.current({
    Map<String, String>? environment,
    KonyakHostPlatform? hostPlatform,
  }) {
    final resolvedEnvironment = environment ?? Platform.environment;
    return DartIoInstallProfileLibrary(
      builtinDirectory: resolveBuiltinInstallProfileDirectory(
        environment: resolvedEnvironment,
      ),
      userDirectory: resolveUserInstallProfileDirectory(
        environment: resolvedEnvironment,
        hostPlatform: hostPlatform ?? currentHostPlatform(),
      ),
      schemaPath: resolveBuiltinInstallProfileSchemaPath(),
    );
  }

  final String builtinDirectory;
  final String userDirectory;
  final String schemaPath;

  @override
  InstallProfileCatalog loadCatalog() {
    final builtinCatalog = DartIoInstallProfileCatalog.fromDirectory(
      builtinDirectory,
      schemaPath: schemaPath,
    );
    final directory = Directory(userDirectory);
    if (!directory.existsSync()) {
      return builtinCatalog;
    }

    final schema = _profileSchemaFromFile(File(schemaPath));
    final loadedIds = builtinCatalog.profiles
        .map((profile) => profile.id)
        .toSet();
    final userProfiles = <InstallProfileRecord>[];
    final issues = <InstallProfileCatalogIssue>[];
    final userFiles =
        directory
            .listSync(followLinks: false)
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList(growable: false)
          ..sort((left, right) => left.path.compareTo(right.path));
    for (final file in userFiles) {
      final sourceId = file.uri.pathSegments.last;
      try {
        final profile = _installProfileFromFile(
          file,
          schema,
          sourceKind: ProfileSourceKind.user,
        );
        if (sourceId != '${profile.id.value}.json') {
          issues.add(
            InstallProfileCatalogIssue(
              sourceId: sourceId,
              message: 'The user profile filename does not match its ID.',
            ),
          );
        } else if (loadedIds.contains(profile.id)) {
          issues.add(
            InstallProfileCatalogIssue(
              sourceId: sourceId,
              message: 'The user profile ID conflicts with another profile.',
            ),
          );
        } else {
          loadedIds.add(profile.id);
          userProfiles.add(profile);
        }
      } on FileSystemException catch (error) {
        issues.add(
          InstallProfileCatalogIssue(
            sourceId: sourceId,
            message: error.message,
          ),
        );
      } on FormatException catch (error) {
        issues.add(
          InstallProfileCatalogIssue(
            sourceId: sourceId,
            message: error.message,
          ),
        );
      }
    }
    userProfiles.sort((left, right) => left.id.value.compareTo(right.id.value));
    return InstallProfileCatalog(<InstallProfileRecord>[
      ...builtinCatalog.profiles,
      ...userProfiles,
    ], issues: issues);
  }

  @override
  InstallProfileLibraryResult validateProfile(String sourcePath) {
    return switch (_validatedUserProfile(sourcePath)) {
      _ValidUserProfile(:final profile) => InstallProfileValidated(profile),
      _InvalidUserProfile(:final failure) => failure,
    };
  }

  @override
  InstallProfileLibraryResult importProfile(String sourcePath) {
    return switch (_validatedUserProfile(sourcePath)) {
      _InvalidUserProfile(:final failure) => failure,
      _ValidUserProfile(profile: final candidate, :final canonicalBytes) => () {
        if (_builtinProfile(candidate.id).isSome()) {
          return InstallProfileLibraryFailure(
            code: InstallProfileLibraryFailureCode.profileReadOnly,
            message: 'A bundled profile with the same ID already exists.',
          );
        }
        final target = _userProfileFile(candidate.id);
        if (target.existsSync()) {
          final existing = _readStoredUserProfile(target);
          return switch (existing) {
            _ValidUserProfile(profile: final existingProfile)
                when existingProfile.manifestDigest ==
                    candidate.manifestDigest =>
              InstallProfileImported(existingProfile),
            _ValidUserProfile() => InstallProfileLibraryFailure(
              code: InstallProfileLibraryFailureCode.profileConflict,
              message: 'A different user profile with the same ID exists.',
            ),
            _InvalidUserProfile(:final failure) => failure,
          };
        }
        return _writeCanonicalFile(
          target,
          canonicalBytes,
        ).match((failure) => failure, (_) => InstallProfileImported(candidate));
      }(),
    };
  }

  @override
  InstallProfileLibraryResult updateProfile({
    required ProfileId profileId,
    required ProfileManifestDigest expectedDigest,
    required String sourcePath,
  }) {
    if (_builtinProfile(profileId).isSome()) {
      return InstallProfileLibraryFailure(
        code: InstallProfileLibraryFailureCode.profileReadOnly,
        message: 'Bundled profiles cannot be updated.',
      );
    }
    final target = _userProfileFile(profileId);
    if (!target.existsSync()) {
      return InstallProfileLibraryFailure(
        code: InstallProfileLibraryFailureCode.profileNotFound,
        message: 'The user profile does not exist.',
      );
    }
    final existing = _readStoredUserProfile(target);
    return switch (existing) {
      _InvalidUserProfile(:final failure) => failure,
      _ValidUserProfile(profile: final existingProfile)
          when existingProfile.manifestDigest != expectedDigest =>
        InstallProfileLibraryFailure(
          code: InstallProfileLibraryFailureCode.profileModified,
          message: 'The user profile changed after it was opened.',
        ),
      _ValidUserProfile() => switch (_validatedUserProfile(sourcePath)) {
        _InvalidUserProfile(:final failure) => failure,
        _ValidUserProfile(profile: final candidate)
            when candidate.id != profileId =>
          InstallProfileLibraryFailure(
            code: InstallProfileLibraryFailureCode.profileConflict,
            message: 'A profile ID cannot be changed during an update.',
          ),
        _ValidUserProfile(profile: final candidate, :final canonicalBytes) =>
          _writeCanonicalFile(target, canonicalBytes).match(
            (failure) => failure,
            (_) => InstallProfileUpdated(candidate),
          ),
      },
    };
  }

  @override
  InstallProfileLibraryResult exportProfile({
    required ProfileId profileId,
    required String destinationPath,
  }) {
    final profile = loadCatalog().find(profileId);
    return profile.match(
      () => InstallProfileLibraryFailure(
        code: InstallProfileLibraryFailureCode.profileNotFound,
        message: 'The profile does not exist.',
      ),
      (profile) {
        final bytes = _canonicalProfileBytes(profile);
        return _writeCanonicalFile(File(destinationPath), bytes).match(
          (failure) => failure,
          (_) =>
              InstallProfileExported(profile: profile, path: destinationPath),
        );
      },
    );
  }

  @override
  InstallProfileLibraryResult deleteProfile({
    required ProfileId profileId,
    required ProfileManifestDigest expectedDigest,
  }) {
    if (_builtinProfile(profileId).isSome()) {
      return InstallProfileLibraryFailure(
        code: InstallProfileLibraryFailureCode.profileReadOnly,
        message: 'Bundled profiles cannot be deleted.',
      );
    }
    final target = _userProfileFile(profileId);
    if (!target.existsSync()) {
      return InstallProfileLibraryFailure(
        code: InstallProfileLibraryFailureCode.profileNotFound,
        message: 'The user profile does not exist.',
      );
    }
    return switch (_readStoredUserProfile(target)) {
      _InvalidUserProfile(:final failure) => failure,
      _ValidUserProfile(:final profile)
          when profile.manifestDigest != expectedDigest =>
        InstallProfileLibraryFailure(
          code: InstallProfileLibraryFailureCode.profileModified,
          message: 'The user profile changed after it was opened.',
        ),
      _ValidUserProfile(:final profile) => () {
        try {
          target.deleteSync();
          return InstallProfileDeleted(
            profileId: profile.id,
            profileDigest: profile.manifestDigest,
          );
        } on FileSystemException catch (error) {
          return _ioFailure(error.message);
        }
      }(),
    };
  }

  Option<InstallProfileRecord> _builtinProfile(ProfileId profileId) {
    return DartIoInstallProfileCatalog.fromDirectory(
      builtinDirectory,
      schemaPath: schemaPath,
    ).find(profileId);
  }

  File _userProfileFile(ProfileId profileId) {
    return File(_joinPath(userDirectory, '${profileId.value}.json'));
  }

  _UserProfileValidationResult _readStoredUserProfile(File file) {
    return _validatedUserProfile(file.path);
  }

  _UserProfileValidationResult _validatedUserProfile(String sourcePath) {
    final file = File(sourcePath);
    try {
      if (!file.existsSync()) {
        return _InvalidUserProfile(
          _ioFailure('The profile manifest does not exist.'),
        );
      }
      if (file.lengthSync() > konyakMaxProfileManifestBytes) {
        return _InvalidUserProfile(
          _invalidProfileFailure(<ProfileValidationIssue>[
            const ProfileValidationIssue(
              path: '/',
              message: 'The profile manifest exceeds the size limit.',
            ),
          ]),
        );
      }
      final bytes = file.readAsBytesSync();
      final decoded = jsonDecode(utf8.decode(bytes));
      final schema = _profileSchemaFromFile(File(schemaPath));
      final validation = schema.validate(decoded);
      if (validation.errors.isNotEmpty) {
        return _InvalidUserProfile(
          _invalidProfileFailure(
            validation.errors.map(
              (error) => ProfileValidationIssue(
                path: error.instancePath.isEmpty ? '/' : error.instancePath,
                message: error.message,
              ),
            ),
          ),
        );
      }
      final parsed = _installProfileFromJson(
        decoded,
        sourceId: 'import.json',
        manifestDigest: sha256.convert(bytes).toString(),
        sourceKind: ProfileSourceKind.user,
      );
      final canonicalBytes = _canonicalProfileBytes(parsed);
      final canonicalProfile = _installProfileFromJson(
        jsonDecode(utf8.decode(canonicalBytes)),
        sourceId: '${parsed.id.value}.json',
        manifestDigest: sha256.convert(canonicalBytes).toString(),
        sourceKind: ProfileSourceKind.user,
      );
      return _ValidUserProfile(
        profile: canonicalProfile,
        canonicalBytes: canonicalBytes,
      );
    } on FileSystemException catch (error) {
      return _InvalidUserProfile(_ioFailure(error.message));
    } on FormatException catch (error) {
      return _InvalidUserProfile(
        _invalidProfileFailure(<ProfileValidationIssue>[
          ProfileValidationIssue(path: '/', message: error.message),
        ]),
      );
    } on ArgumentError catch (error) {
      return _InvalidUserProfile(
        _invalidProfileFailure(<ProfileValidationIssue>[
          ProfileValidationIssue(
            path: '/${error.name ?? ''}',
            message: error.message.toString(),
          ),
        ]),
      );
    }
  }
}

String resolveUserInstallProfileDirectory({
  required Map<String, String> environment,
  required KonyakHostPlatform hostPlatform,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return hostEnvironment
      .nonEmptyValue(konyakUserProfileDirectoryEnvironmentVariable)
      .match(
        () => joinPath(
          resolveBottleDataHome(hostEnvironment, hostPlatform: hostPlatform),
          const <String>['profiles'],
        ),
        (override) => override,
      );
}

sealed class _UserProfileValidationResult {
  const _UserProfileValidationResult();
}

final class _ValidUserProfile extends _UserProfileValidationResult {
  const _ValidUserProfile({
    required this.profile,
    required this.canonicalBytes,
  });

  final InstallProfileRecord profile;
  final List<int> canonicalBytes;
}

final class _InvalidUserProfile extends _UserProfileValidationResult {
  const _InvalidUserProfile(this.failure);

  final InstallProfileLibraryFailure failure;
}

InstallProfileLibraryFailure _invalidProfileFailure(
  Iterable<ProfileValidationIssue> issues,
) {
  return InstallProfileLibraryFailure(
    code: InstallProfileLibraryFailureCode.invalidProfile,
    message: 'The profile manifest is invalid.',
    issues: issues,
  );
}

InstallProfileLibraryFailure _ioFailure(String message) {
  return InstallProfileLibraryFailure(
    code: InstallProfileLibraryFailureCode.profileIoFailure,
    message: message,
  );
}

List<int> _canonicalProfileBytes(InstallProfileRecord profile) {
  const encoder = JsonEncoder.withIndent('  ');
  return utf8.encode('${encoder.convert(_canonicalProfileJson(profile))}\n');
}

Map<String, Object?> _canonicalProfileJson(InstallProfileRecord profile) {
  return <String, Object?>{
    r'$schema': konyakProfileSchemaUri,
    'schemaVersion': konyakProfileSchemaVersion,
    'id': profile.id.value,
    'name': profile.name.value,
    'profileVersion': profile.profileVersion.value,
    'summary': profile.summary.value,
    'platforms': profile.platforms
        .map((platform) => platform.value)
        .toList(growable: false),
    'windowsVersion': profile.windowsVersion.value,
    'managedProgramPath': profile.managedProgramPath.value,
    'installerResource': <String, Object?>{
      'kind': profile.installerResource.kind.value,
      'url': profile.installerResource.url.value,
      'sha256': profile.installerResource.sha256.value,
      'fileName': profile.installerResource.fileName.value,
    },
    ...profile.installerCompletion.match(
      () => const <String, Object?>{},
      (completion) => <String, Object?>{
        'installerCompletion': <String, Object?>{
          'ignoreChildExecutable': completion.ignoreChildExecutable.value,
        },
      },
    ),
    'preInstallActions': profile.preInstallActions
        .map(_canonicalPreInstallActionJson)
        .toList(growable: false),
    'runCompletionPolicy': profile.runCompletionPolicy.value,
    'compatibilityProfile': <String, Object?>{
      'id': profile.compatibilityProfile.id.value,
      'profileVersion': profile.compatibilityProfile.profileVersion.value,
      'childProcessRules': profile.compatibilityProfile.childProcessRules
          .map(
            (rule) => <String, Object?>{
              'executableSuffix': rule.executableSuffix.value,
              'appendArgumentsIfMissing': rule.appendArgumentsIfMissing.value,
            },
          )
          .toList(growable: false),
    },
  };
}

Map<String, Object?> _canonicalPreInstallActionJson(
  PreInstallActionRecord action,
) {
  return switch (action) {
    WinetricksPreInstallAction(:final verb) => <String, Object?>{
      'kind': 'winetricks',
      'verb': verb.value,
    },
    NativeDllPreInstallAction(
      :final componentId,
      :final machine,
      :final destination,
      :final targetFileName,
      :final resource,
    ) =>
      <String, Object?>{
        'kind': 'nativeDll',
        'componentId': componentId.value,
        'machine': machine.value,
        'destination': destination.value,
        'targetFileName': targetFileName.value,
        'resource': <String, Object?>{
          'kind': resource.kind.value,
          'url': resource.url.value,
          'sha256': resource.sha256.value,
          'fileName': resource.fileName.value,
        },
      },
  };
}

Either<InstallProfileLibraryFailure, Unit> _writeCanonicalFile(
  File target,
  List<int> bytes,
) {
  final temporary = File('${target.path}.part-${pid.toString()}');
  try {
    target.parent.createSync(recursive: true);
    if (temporary.existsSync()) {
      temporary.deleteSync();
    }
    temporary.writeAsBytesSync(bytes, flush: true);
    temporary.renameSync(target.path);
    return const Right<InstallProfileLibraryFailure, Unit>(unit);
  } on FileSystemException catch (error) {
    if (temporary.existsSync()) {
      temporary.deleteSync();
    }
    return Left<InstallProfileLibraryFailure, Unit>(_ioFailure(error.message));
  }
}

String resolveBuiltinInstallProfileSchemaPath({
  String? resolvedExecutable,
  Uri? script,
}) {
  final candidates = <String>[
    if (_nonEmpty(resolvedExecutable ?? Platform.resolvedExecutable))
      _joinPath(
        File(resolvedExecutable ?? Platform.resolvedExecutable).parent.path,
        'profiles/$konyakProfileSchemaFileName',
      ),
    if ((script ?? Platform.script).scheme == 'file')
      _joinPath(
        File.fromUri(script ?? Platform.script).parent.parent.path,
        'profiles/$konyakProfileSchemaFileName',
      ),
  ];

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  throw FileSystemException(
    'Could not locate the canonical profile schema.',
    candidates.join(', '),
  );
}

String resolveBuiltinInstallProfileDirectory({
  Map<String, String>? environment,
  String? currentDirectory,
  String? resolvedExecutable,
  Uri? script,
}) {
  final activeEnvironment = environment ?? Platform.environment;
  final candidates = <String>[
    if (_nonEmpty(activeEnvironment[konyakProfileDirectoryEnvironmentVariable]))
      activeEnvironment[konyakProfileDirectoryEnvironmentVariable]!,
    if (_nonEmpty(activeEnvironment['KONYAK_BUNDLE_RESOURCES']))
      _joinPath(activeEnvironment['KONYAK_BUNDLE_RESOURCES']!, 'profiles'),
    if (_nonEmpty(resolvedExecutable ?? Platform.resolvedExecutable))
      _joinPath(
        File(resolvedExecutable ?? Platform.resolvedExecutable).parent.path,
        'profiles',
      ),
    if ((script ?? Platform.script).scheme == 'file')
      _joinPath(
        File.fromUri(script ?? Platform.script).parent.parent.path,
        'profiles',
      ),
    _joinPath(currentDirectory ?? Directory.current.path, 'profiles'),
    _joinPath(
      currentDirectory ?? Directory.current.path,
      'packages/konyak_cli/profiles',
    ),
  ];

  for (final candidate in candidates) {
    if (Directory(candidate).existsSync()) {
      return candidate;
    }
  }

  throw FileSystemException(
    'Could not locate the built-in profile directory.',
    candidates.join(', '),
  );
}

JsonSchema _profileSchemaFromFile(File file) {
  if (!file.existsSync()) {
    throw FileSystemException(
      'Canonical profile schema does not exist.',
      file.path,
    );
  }

  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Profile schema must be an object.');
    }
    if (decoded[r'$id'] != konyakProfileSchemaUri) {
      throw const FormatException(
        'Profile schema does not use the canonical schema URI.',
      );
    }
    return JsonSchema.create(decoded);
  } on FileSystemException {
    rethrow;
  } on FormatException catch (error) {
    throw FormatException('${file.path}: ${error.message}');
  } on ArgumentError catch (error) {
    throw FormatException('${file.path}: ${error.message}');
  }
}

InstallProfileRecord _installProfileFromFile(
  File file,
  JsonSchema schema, {
  ProfileSourceKind sourceKind = ProfileSourceKind.builtin,
}) {
  try {
    final bytes = file.readAsBytesSync();
    final decoded = jsonDecode(utf8.decode(bytes));
    _validateProfileJson(file, schema, decoded);
    return _installProfileFromJson(
      decoded,
      sourceId: file.uri.pathSegments.last,
      manifestDigest: sha256.convert(bytes).toString(),
      sourceKind: sourceKind,
    );
  } on FileSystemException {
    rethrow;
  } on FormatException catch (error) {
    throw FormatException('${file.path}: ${error.message}');
  } on ArgumentError catch (error) {
    throw FormatException('${file.path}: ${error.message}');
  }
}

void _validateProfileJson(File file, JsonSchema schema, Object? profile) {
  final result = schema.validate(profile);
  if (result.errors.isEmpty) {
    return;
  }

  throw FormatException(
    '${file.path}: Profile does not match $konyakProfileSchemaFileName: '
    '${result.errors.join('; ')}',
  );
}

InstallProfileRecord _installProfileFromJson(
  Object? value, {
  required String sourceId,
  required String manifestDigest,
  ProfileSourceKind sourceKind = ProfileSourceKind.builtin,
}) {
  final profile = _requiredObject(value, 'Profile must be an object.');
  if (_requiredInt(profile, 'schemaVersion') != 1) {
    throw const FormatException('Unsupported profile schema version.');
  }
  final compatibilityProfile = _requiredObject(
    profile['compatibilityProfile'],
    'compatibilityProfile must be an object.',
  );
  final installerResource = _requiredObject(
    profile['installerResource'],
    'installerResource must be an object.',
  );

  return InstallProfileRecord(
    id: _requiredString(profile, 'id'),
    sourceId: sourceId,
    manifestDigest: manifestDigest,
    name: _requiredString(profile, 'name'),
    profileVersion: _requiredInt(profile, 'profileVersion'),
    summary: _requiredString(profile, 'summary'),
    platforms: _requiredStringList(profile, 'platforms'),
    windowsVersion: _requiredString(profile, 'windowsVersion'),
    managedProgramPath: _requiredString(profile, 'managedProgramPath'),
    installerResource: InstallerResourceRecord(
      kind: _requiredString(installerResource, 'kind'),
      url: _requiredString(installerResource, 'url'),
      sha256: _requiredString(installerResource, 'sha256'),
      fileName: _requiredString(installerResource, 'fileName'),
    ),
    installerCompletion: _installerCompletion(profile),
    preInstallActions: _requiredObjectList(
      profile,
      'preInstallActions',
    ).map(_preInstallAction),
    runCompletionPolicy: _completionPolicy(
      _requiredString(profile, 'runCompletionPolicy'),
    ),
    compatibilityProfile: CompatibilityProfileRecord(
      id: _requiredString(compatibilityProfile, 'id'),
      profileVersion: _requiredInt(compatibilityProfile, 'profileVersion'),
      childProcessRules:
          _requiredObjectList(compatibilityProfile, 'childProcessRules').map(
            (rule) => ChildProcessCompatibilityRule(
              executableSuffix: _requiredString(rule, 'executableSuffix'),
              appendArgumentsIfMissing: _requiredStringList(
                rule,
                'appendArgumentsIfMissing',
              ),
            ),
          ),
    ),
    sourceKind: sourceKind,
  );
}

PreInstallActionRecord _preInstallAction(Map<String, Object?> action) {
  return switch (_requiredString(action, 'kind')) {
    'winetricks' => PreInstallActionRecord.winetricks(
      verb: _requiredString(action, 'verb'),
    ),
    'nativeDll' => () {
      final resource = _requiredObject(
        action['resource'],
        'nativeDll resource must be an object.',
      );
      return PreInstallActionRecord.nativeDll(
        componentId: _requiredString(action, 'componentId'),
        machine: _requiredString(action, 'machine'),
        destination: _requiredString(action, 'destination'),
        targetFileName: _requiredString(action, 'targetFileName'),
        resource: NativeDllResourceRecord(
          kind: _requiredString(resource, 'kind'),
          url: _requiredString(resource, 'url'),
          sha256: _requiredString(resource, 'sha256'),
          fileName: _requiredString(resource, 'fileName'),
        ),
      );
    }(),
    final kind => throw FormatException('Unsupported preInstallAction $kind.'),
  };
}

Option<InstallerCompletionRecord> _installerCompletion(
  Map<String, Object?> profile,
) {
  if (!profile.containsKey('installerCompletion')) {
    return const Option.none();
  }
  final completion = _requiredObject(
    profile['installerCompletion'],
    'installerCompletion must be an object.',
  );
  return Option.of(
    InstallerCompletionRecord(
      ignoreChildExecutable: _requiredString(
        completion,
        'ignoreChildExecutable',
      ),
    ),
  );
}

Map<String, Object?> _requiredObject(Object? value, String message) {
  if (value is! Map<String, Object?>) {
    throw FormatException(message);
  }
  return value;
}

String _requiredString(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! String) {
    throw FormatException('$key must be a string.');
  }
  return field;
}

int _requiredInt(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! int) {
    throw FormatException('$key must be an integer.');
  }
  return field;
}

List<String> _requiredStringList(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! List<Object?> || field.any((item) => item is! String)) {
    throw FormatException('$key must be a list of strings.');
  }
  return field.cast<String>();
}

List<Map<String, Object?>> _requiredObjectList(
  Map<String, Object?> value,
  String key,
) {
  final field = value[key];
  if (field is! List<Object?> ||
      field.any((item) => item is! Map<String, Object?>)) {
    throw FormatException('$key must be a list of objects.');
  }
  return field.cast<Map<String, Object?>>();
}

ProgramRunCompletionPolicy _completionPolicy(String value) {
  for (final policy in ProgramRunCompletionPolicy.values) {
    if (policy.value == value) {
      return policy;
    }
  }
  throw FormatException('Unsupported runCompletionPolicy: $value.');
}

bool _nonEmpty(String? value) => value != null && value.trim().isNotEmpty;

String _joinPath(String root, String relativePath) {
  return '${root.replaceAll(RegExp(r'/+$'), '')}/$relativePath';
}
