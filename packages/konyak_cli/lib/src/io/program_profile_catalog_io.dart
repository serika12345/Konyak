import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';

import '../domain/program/program_profile_catalog.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_run_models.dart';

const konyakProfileDirectoryEnvironmentVariable = 'KONYAK_PROFILE_DIRECTORY';
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
    return fromDirectory(
      resolveBuiltinInstallProfileDirectory(),
      schemaPath: resolveBuiltinInstallProfileSchemaPath(),
    );
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

InstallProfileRecord _installProfileFromFile(File file, JsonSchema schema) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    _validateProfileJson(file, schema, decoded);
    return _installProfileFromJson(decoded);
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

InstallProfileRecord _installProfileFromJson(Object? value) {
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
    dependencyWinetricksVerbs: _requiredStringList(
      profile,
      'dependencyWinetricksVerbs',
    ),
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
