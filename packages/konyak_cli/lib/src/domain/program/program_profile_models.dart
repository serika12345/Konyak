import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'program_run_command_support.dart';
import 'program_run_models.dart';

part 'program_profile_models.freezed.dart';

const konyakMaxChildProcessRuleArguments = 64;
const konyakMaxChildProcessRulesLength = 65535;
const konyakMaxChildProcessExecutableSuffixLength = 1024;
const konyakMaxChildProcessArgumentLength = 8192;
const konyakMaxPreInstallActions = 64;
const konyakMaxPreInstallActionIdLength = 128;
const konyakMaxInstallerResourceUrlLength = 8192;
const konyakMaxInstallerResourceFileNameLength = 255;
const konyakMaxInstallerCompletionChildExecutableNameLength = 255;
const konyakProfileSchemaVersion = 1;
const konyakMaxProfileSourceIdLength = 1024;

enum ProfileSourceKind {
  builtin('builtin');

  const ProfileSourceKind(this.value);

  final String value;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileSchemaVersion with _$ProfileSchemaVersion {
  const ProfileSchemaVersion._();

  factory ProfileSchemaVersion(int value) {
    if (value != konyakProfileSchemaVersion) {
      throw ArgumentError.value(
        value,
        'profileSchemaVersion',
        'must be $konyakProfileSchemaVersion',
      );
    }
    return ProfileSchemaVersion._validated(value);
  }

  const factory ProfileSchemaVersion._validated(int value) =
      _ProfileSchemaVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileSourceId with _$ProfileSourceId {
  const ProfileSourceId._();

  factory ProfileSourceId(String value) {
    final components = value.split('/');
    if (value.isEmpty ||
        value.length > konyakMaxProfileSourceIdLength ||
        value.startsWith('/') ||
        value.contains('\\') ||
        !RegExp(r'^[A-Za-z0-9._+/-]+$').hasMatch(value) ||
        components.any(
          (component) =>
              component.isEmpty || component == '.' || component == '..',
        )) {
      throw ArgumentError.value(
        value,
        'sourceId',
        'must be a safe non-empty relative source identifier',
      );
    }
    return ProfileSourceId._validated(value);
  }

  const factory ProfileSourceId._validated(String value) = _ProfileSourceId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileManifestDigest with _$ProfileManifestDigest {
  const ProfileManifestDigest._();

  factory ProfileManifestDigest(String value) {
    if (!RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'manifestDigest',
        'must contain exactly 64 hexadecimal characters',
      );
    }
    return ProfileManifestDigest._validated(value.toLowerCase());
  }

  const factory ProfileManifestDigest._validated(String value) =
      _ProfileManifestDigest;
}

enum InstallerResourceKind {
  https('https');

  const InstallerResourceKind(this.value);

  final String value;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class InstallerResourceRecord with _$InstallerResourceRecord {
  const InstallerResourceRecord._();

  factory InstallerResourceRecord({
    required String kind,
    required String url,
    required String sha256,
    required String fileName,
  }) {
    if (kind != InstallerResourceKind.https.value) {
      throw ArgumentError.value(
        kind,
        'kind',
        'must be ${InstallerResourceKind.https.value}',
      );
    }
    return InstallerResourceRecord._validated(
      kind: InstallerResourceKind.https,
      url: InstallerResourceUrl(url),
      sha256: InstallerResourceSha256(sha256),
      fileName: InstallerResourceFileName(fileName),
    );
  }

  const factory InstallerResourceRecord._validated({
    required InstallerResourceKind kind,
    required InstallerResourceUrl url,
    required InstallerResourceSha256 sha256,
    required InstallerResourceFileName fileName,
  }) = _InstallerResourceRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InstallerResourceUrl with _$InstallerResourceUrl {
  const InstallerResourceUrl._();

  factory InstallerResourceUrl(String value) {
    final uri = _parseInstallerResourceUri(value);
    if (value.isEmpty ||
        value.length > konyakMaxInstallerResourceUrlLength ||
        value.codeUnits.any(
          (codeUnit) => codeUnit <= 0x20 || codeUnit == 0x7f,
        ) ||
        uri.scheme != InstallerResourceKind.https.value ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.authority.contains('@') ||
        uri.hasFragment) {
      throw ArgumentError.value(
        value,
        'url',
        'must be an HTTPS URL with a host and no userinfo or fragment',
      );
    }
    return InstallerResourceUrl._validated(value);
  }

  const factory InstallerResourceUrl._validated(String value) =
      _InstallerResourceUrl;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InstallerResourceSha256 with _$InstallerResourceSha256 {
  const InstallerResourceSha256._();

  factory InstallerResourceSha256(String value) {
    if (!RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'sha256',
        'must contain exactly 64 hexadecimal characters',
      );
    }
    return InstallerResourceSha256._validated(value);
  }

  const factory InstallerResourceSha256._validated(String value) =
      _InstallerResourceSha256;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InstallerResourceFileName with _$InstallerResourceFileName {
  const InstallerResourceFileName._();

  factory InstallerResourceFileName(String value) {
    final lowerCaseValue = value.toLowerCase();
    final hasInstallerExtension =
        lowerCaseValue.endsWith('.exe') || lowerCaseValue.endsWith('.msi');
    if (value.length <= '.exe'.length ||
        value.length > konyakMaxInstallerResourceFileNameLength ||
        value.contains('/') ||
        value.contains('\\') ||
        value.codeUnits.any(
          (codeUnit) => codeUnit <= 0x1f || codeUnit == 0x7f,
        ) ||
        !hasInstallerExtension) {
      throw ArgumentError.value(
        value,
        'fileName',
        'must be a basename of at most '
            '$konyakMaxInstallerResourceFileNameLength characters ending in '
            '.exe or .msi',
      );
    }
    return InstallerResourceFileName._validated(value);
  }

  const factory InstallerResourceFileName._validated(String value) =
      _InstallerResourceFileName;
}

enum NativeDllMachine {
  x86('x86', 0x014c),
  x64('x64', 0x8664);

  const NativeDllMachine(this.value, this.peCoffMachine);

  final String value;
  final int peCoffMachine;
}

enum NativeDllDestination {
  windowsSysWow64('windowsSysWow64'),
  windowsSystem32('windowsSystem32');

  const NativeDllDestination(this.value);

  final String value;
}

enum PreInstallActionKind {
  winetricks('winetricks'),
  nativeDll('nativeDll');

  const PreInstallActionKind(this.value);

  final String value;
}

PreInstallActionKind preInstallActionKind(PreInstallActionRecord action) =>
    switch (action) {
      WinetricksPreInstallAction() => PreInstallActionKind.winetricks,
      NativeDllPreInstallAction() => PreInstallActionKind.nativeDll,
    };

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PreInstallActionId with _$PreInstallActionId {
  const PreInstallActionId._();

  factory PreInstallActionId(String value) {
    if (value.isEmpty ||
        value.length > konyakMaxPreInstallActionIdLength ||
        !RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(value)) {
      throw ArgumentError.value(value, 'preInstallActionId');
    }
    return PreInstallActionId._validated(value);
  }

  const factory PreInstallActionId._validated(String value) =
      _PreInstallActionId;
}

PreInstallActionId preInstallActionId(PreInstallActionRecord action) =>
    switch (action) {
      WinetricksPreInstallAction(:final verb) => PreInstallActionId(verb.value),
      NativeDllPreInstallAction(:final componentId) => componentId,
    };

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class NativeDllFileName with _$NativeDllFileName {
  const NativeDllFileName._();

  factory NativeDllFileName(String value) {
    if (value.length <= '.dll'.length ||
        value.length > konyakMaxInstallerResourceFileNameLength ||
        value.contains('/') ||
        value.contains('\\') ||
        value.codeUnits.any(
          (codeUnit) => codeUnit <= 0x1f || codeUnit == 0x7f,
        ) ||
        !value.toLowerCase().endsWith('.dll')) {
      throw ArgumentError.value(
        value,
        'fileName',
        'must be a safe .dll basename',
      );
    }
    return NativeDllFileName._validated(value);
  }

  const factory NativeDllFileName._validated(String value) = _NativeDllFileName;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class NativeDllResourceRecord with _$NativeDllResourceRecord {
  const NativeDllResourceRecord._();

  factory NativeDllResourceRecord({
    required String kind,
    required String url,
    required String sha256,
    required String fileName,
  }) {
    if (kind != InstallerResourceKind.https.value) {
      throw ArgumentError.value(kind, 'kind', 'must be https');
    }
    return NativeDllResourceRecord._validated(
      kind: InstallerResourceKind.https,
      url: InstallerResourceUrl(url),
      sha256: InstallerResourceSha256(sha256),
      fileName: NativeDllFileName(fileName),
    );
  }

  const factory NativeDllResourceRecord._validated({
    required InstallerResourceKind kind,
    required InstallerResourceUrl url,
    required InstallerResourceSha256 sha256,
    required NativeDllFileName fileName,
  }) = _NativeDllResourceRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
sealed class PreInstallActionRecord with _$PreInstallActionRecord {
  const PreInstallActionRecord._();

  factory PreInstallActionRecord.winetricks({required String verb}) {
    return PreInstallActionRecord._winetricks(verb: WinetricksVerbId(verb));
  }

  const factory PreInstallActionRecord._winetricks({
    required WinetricksVerbId verb,
  }) = WinetricksPreInstallAction;

  factory PreInstallActionRecord.nativeDll({
    required String componentId,
    required String machine,
    required String destination,
    required String targetFileName,
    required NativeDllResourceRecord resource,
  }) {
    if (componentId.length > konyakMaxPreInstallActionIdLength ||
        !RegExp(r'^[a-z0-9][a-z0-9_.-]*$').hasMatch(componentId)) {
      throw ArgumentError.value(
        componentId,
        'componentId',
        'must be at most $konyakMaxPreInstallActionIdLength characters and '
            r'match [a-z0-9][a-z0-9_.-]*',
      );
    }
    final parsedMachine = NativeDllMachine.values.singleWhere(
      (candidate) => candidate.value == machine,
      orElse: () => throw ArgumentError.value(machine, 'machine'),
    );
    final parsedDestination = NativeDllDestination.values.singleWhere(
      (candidate) => candidate.value == destination,
      orElse: () => throw ArgumentError.value(destination, 'destination'),
    );
    final expectedDestination = switch (parsedMachine) {
      NativeDllMachine.x86 => NativeDllDestination.windowsSysWow64,
      NativeDllMachine.x64 => NativeDllDestination.windowsSystem32,
    };
    if (parsedDestination != expectedDestination) {
      throw ArgumentError.value(
        destination,
        'destination',
        'does not match $machine',
      );
    }
    return PreInstallActionRecord._nativeDll(
      componentId: PreInstallActionId(componentId),
      machine: parsedMachine,
      destination: parsedDestination,
      targetFileName: NativeDllFileName(targetFileName),
      resource: resource,
    );
  }

  const factory PreInstallActionRecord._nativeDll({
    required PreInstallActionId componentId,
    required NativeDllMachine machine,
    required NativeDllDestination destination,
    required NativeDllFileName targetFileName,
    required NativeDllResourceRecord resource,
  }) = NativeDllPreInstallAction;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InstallerCompletionChildExecutableName
    with _$InstallerCompletionChildExecutableName {
  const InstallerCompletionChildExecutableName._();

  factory InstallerCompletionChildExecutableName(String value) {
    final hasExeExtension = value.toLowerCase().endsWith('.exe');
    if (value.length <= '.exe'.length ||
        value.length > konyakMaxInstallerCompletionChildExecutableNameLength ||
        value.contains('/') ||
        value.contains('\\') ||
        value.codeUnits.any(
          (codeUnit) => codeUnit <= 0x1f || codeUnit == 0x7f,
        ) ||
        !hasExeExtension) {
      throw ArgumentError.value(
        value,
        'ignoreChildExecutable',
        'must be a basename of at most '
            '$konyakMaxInstallerCompletionChildExecutableNameLength '
            'characters ending in .exe',
      );
    }
    return InstallerCompletionChildExecutableName._validated(value);
  }

  const factory InstallerCompletionChildExecutableName._validated(
    String value,
  ) = _InstallerCompletionChildExecutableName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InstallerCompletionRecord with _$InstallerCompletionRecord {
  const InstallerCompletionRecord._();

  factory InstallerCompletionRecord({required String ignoreChildExecutable}) {
    return InstallerCompletionRecord._validated(
      ignoreChildExecutable: InstallerCompletionChildExecutableName(
        ignoreChildExecutable,
      ),
    );
  }

  const factory InstallerCompletionRecord._validated({
    required InstallerCompletionChildExecutableName ignoreChildExecutable,
  }) = _InstallerCompletionRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class InstallProfileRecord with _$InstallProfileRecord {
  const InstallProfileRecord._();

  factory InstallProfileRecord({
    required String id,
    required String sourceId,
    required String manifestDigest,
    required String name,
    required int profileVersion,
    required String summary,
    required Iterable<String> platforms,
    required String windowsVersion,
    required String managedProgramPath,
    required InstallerResourceRecord installerResource,
    required Iterable<PreInstallActionRecord> preInstallActions,
    required CompatibilityProfileRecord compatibilityProfile,
    Option<InstallerCompletionRecord> installerCompletion = const Option.none(),
    ProfileSourceKind sourceKind = ProfileSourceKind.builtin,
    ProgramRunCompletionPolicy runCompletionPolicy =
        ProgramRunCompletionPolicy.waitForExit,
  }) {
    final validatedPreInstallActions = preInstallActions.toIList();
    final validatedPlatforms = platforms.map(RuntimePlatformName.new).toIList();
    _validatePreInstallActions(validatedPreInstallActions);
    _validateInstallerCompletionPlatforms(
      installerCompletion,
      validatedPlatforms,
    );
    return InstallProfileRecord._validated(
      id: ProfileId(id),
      sourceId: ProfileSourceId(sourceId),
      manifestDigest: ProfileManifestDigest(manifestDigest),
      name: ProfileName(name),
      profileVersion: ProfileVersion(profileVersion),
      summary: ProfileSummary(summary),
      platforms: validatedPlatforms,
      windowsVersion: WindowsVersion(windowsVersion),
      managedProgramPath: ProgramPath(
        _validateManagedProgramPath(managedProgramPath),
      ),
      installerResource: installerResource,
      installerCompletion: installerCompletion,
      preInstallActions: validatedPreInstallActions,
      compatibilityProfile: compatibilityProfile,
      sourceKind: sourceKind,
      runCompletionPolicy: runCompletionPolicy,
    );
  }

  const factory InstallProfileRecord._validated({
    required ProfileId id,
    required ProfileSourceId sourceId,
    required ProfileManifestDigest manifestDigest,
    required ProfileName name,
    required ProfileVersion profileVersion,
    required ProfileSummary summary,
    required IList<RuntimePlatformName> platforms,
    required WindowsVersion windowsVersion,
    required ProgramPath managedProgramPath,
    required InstallerResourceRecord installerResource,
    required Option<InstallerCompletionRecord> installerCompletion,
    required IList<PreInstallActionRecord> preInstallActions,
    required CompatibilityProfileRecord compatibilityProfile,
    required ProfileSourceKind sourceKind,
    required ProgramRunCompletionPolicy runCompletionPolicy,
  }) = _InstallProfileRecord;
}

void _validateInstallerCompletionPlatforms(
  Option<InstallerCompletionRecord> installerCompletion,
  IList<RuntimePlatformName> platforms,
) {
  installerCompletion.match(() {}, (_) {
    if (platforms.any((platform) => platform.value != 'macos')) {
      throw ArgumentError.value(
        platforms.map((platform) => platform.value).toList(growable: false),
        'platforms',
        'installerCompletion is supported only by macOS profiles',
      );
    }
  });
}

Uri _parseInstallerResourceUri(String value) {
  try {
    return Uri.parse(value);
  } on FormatException {
    throw ArgumentError.value(
      value,
      'url',
      'must be an HTTPS URL with a host and no userinfo or fragment',
    );
  }
}

String _validateManagedProgramPath(String value) {
  final hasAbsoluteCDriveRoot = RegExp(r'^[Cc]:[\\/]').hasMatch(value);
  final components = value.length >= 3
      ? value.substring(3).split(RegExp(r'[\\/]'))
      : const <String>[];
  final hasUnsafeComponent = components.any(
    (component) => component.isEmpty || component == '.' || component == '..',
  );
  final hasExeFileName =
      components.isNotEmpty &&
      components.last.length > '.exe'.length &&
      components.last.toLowerCase().endsWith('.exe');
  if (!hasAbsoluteCDriveRoot ||
      value.contains('\u0000') ||
      hasUnsafeComponent ||
      !hasExeFileName) {
    throw ArgumentError.value(
      value,
      'managedProgramPath',
      'must be an absolute C-drive Windows .exe path without empty, dot, or '
          'dot-dot components',
    );
  }
  return value;
}

void _validatePreInstallActions(IList<PreInstallActionRecord> actions) {
  if (actions.length > konyakMaxPreInstallActions) {
    throw ArgumentError.value(
      actions.length,
      'preInstallActions',
      'must contain at most $konyakMaxPreInstallActions actions',
    );
  }
  final verbs = actions.whereType<WinetricksPreInstallAction>().map(
    (action) => action.verb,
  );
  final invalidVerb = verbs.where(
    (verb) =>
        verb.value.length > konyakMaxPreInstallActionIdLength ||
        !isSupportedWinetricksVerb(verb),
  );
  if (invalidVerb.isNotEmpty) {
    throw ArgumentError.value(
      invalidVerb.first.value,
      'preInstallActions',
      'each verb must be at most '
          '$konyakMaxPreInstallActionIdLength characters and match '
          r'[A-Za-z0-9_.+-]+',
    );
  }
  final values = verbs.map((verb) => verb.value).toList(growable: false);
  if (values.toSet().length != values.length) {
    throw ArgumentError.value(
      values,
      'preInstallActions',
      'must not contain duplicate verbs',
    );
  }
  final nativeTargets = actions
      .whereType<NativeDllPreInstallAction>()
      .map(
        (action) =>
            '${action.destination.value}/${action.targetFileName.value.toLowerCase()}',
      )
      .toList(growable: false);
  if (nativeTargets.toSet().length != nativeTargets.length) {
    throw ArgumentError.value(
      nativeTargets,
      'preInstallActions',
      'must not contain duplicate native DLL destinations',
    );
  }
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class CompatibilityProfileRecord with _$CompatibilityProfileRecord {
  const CompatibilityProfileRecord._();

  factory CompatibilityProfileRecord({
    required String id,
    required int profileVersion,
    required Iterable<ChildProcessCompatibilityRule> childProcessRules,
  }) {
    final validatedRules = childProcessRules.toIList();
    _validateChildProcessRuleSet(validatedRules);
    return CompatibilityProfileRecord._validated(
      id: ProfileId(id),
      profileVersion: ProfileVersion(profileVersion),
      childProcessRules: validatedRules,
    );
  }

  const factory CompatibilityProfileRecord._validated({
    required ProfileId id,
    required ProfileVersion profileVersion,
    required IList<ChildProcessCompatibilityRule> childProcessRules,
  }) = _CompatibilityProfileRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ChildProcessCompatibilityRule
    with _$ChildProcessCompatibilityRule {
  const ChildProcessCompatibilityRule._();

  factory ChildProcessCompatibilityRule({
    required String executableSuffix,
    required Iterable<String> appendArgumentsIfMissing,
  }) {
    final validatedSuffix = _validateChildProcessExecutableSuffix(
      executableSuffix,
    );
    final validatedArguments = appendArgumentsIfMissing
        .map(_validateChildProcessArgument)
        .toList(growable: false);
    if (validatedArguments.isEmpty) {
      throw ArgumentError.value(
        validatedArguments,
        'appendArgumentsIfMissing',
        'must contain at least one argument',
      );
    }
    if (validatedArguments.length > konyakMaxChildProcessRuleArguments) {
      throw ArgumentError.value(
        validatedArguments.length,
        'appendArgumentsIfMissing',
        'must contain at most $konyakMaxChildProcessRuleArguments arguments',
      );
    }
    if (validatedArguments.toSet().length != validatedArguments.length) {
      throw ArgumentError.value(
        validatedArguments,
        'appendArgumentsIfMissing',
        'must not contain duplicate arguments',
      );
    }
    return ChildProcessCompatibilityRule._validated(
      executableSuffix: ProgramExecutable(validatedSuffix),
      appendArgumentsIfMissing: ProgramRunArguments(validatedArguments),
    );
  }

  const factory ChildProcessCompatibilityRule._validated({
    required ProgramExecutable executableSuffix,
    required ProgramRunArguments appendArgumentsIfMissing,
  }) = _ChildProcessCompatibilityRule;
}

String _validateChildProcessExecutableSuffix(String value) {
  if (value.trim().isEmpty ||
      value.length > konyakMaxChildProcessExecutableSuffixLength ||
      !value.codeUnits.every(
        (codeUnit) => codeUnit >= 0x20 && codeUnit <= 0x7e,
      )) {
    throw ArgumentError.value(
      value,
      'executableSuffix',
      'must be non-blank, at most '
          '$konyakMaxChildProcessExecutableSuffixLength printable ASCII '
          'characters',
    );
  }
  return value;
}

String _validateChildProcessArgument(String value) {
  if (value.isEmpty ||
      value.length > konyakMaxChildProcessArgumentLength ||
      value.contains('\u0000') ||
      value.contains('\t') ||
      value.contains('\n') ||
      value.contains('\r') ||
      value.contains(' ') ||
      value.contains('"')) {
    throw ArgumentError.value(
      value,
      'appendArgumentsIfMissing',
      'each argument must be a non-empty unquoted token of at most '
          '$konyakMaxChildProcessArgumentLength characters',
    );
  }
  return value;
}

void _validateChildProcessRuleSet(IList<ChildProcessCompatibilityRule> rules) {
  final argumentCount = rules.fold<int>(
    0,
    (count, rule) => count + rule.appendArgumentsIfMissing.length,
  );
  if (argumentCount > konyakMaxChildProcessRuleArguments) {
    throw ArgumentError.value(
      argumentCount,
      'childProcessRules',
      'must contain at most $konyakMaxChildProcessRuleArguments '
          'child-process arguments',
    );
  }

  final entryLengths = rules
      .expand(
        (rule) => rule.appendArgumentsIfMissing.map(
          (argument) =>
              rule.executableSuffix.value.length + 1 + argument.length,
        ),
      )
      .toList(growable: false);
  final serializedLength =
      entryLengths.fold<int>(0, (length, entry) => length + entry) +
      (entryLengths.isEmpty ? 0 : entryLengths.length - 1);
  if (serializedLength > konyakMaxChildProcessRulesLength) {
    throw ArgumentError.value(
      serializedLength,
      'childProcessRules',
      'serialized rules must contain at most '
          '$konyakMaxChildProcessRulesLength UTF-16 code units',
    );
  }
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ProgramProfileRecord with _$ProgramProfileRecord {
  const ProgramProfileRecord._();

  factory ProgramProfileRecord({
    required String profileId,
    required int profileVersion,
    required String managedProgramPath,
    required String compatibilityProfileId,
    required int compatibilityProfileVersion,
    required InstallerResourceRecord installerResource,
    Iterable<PreInstallActionRecord> preInstallActions = const [],
    required String profileSourceId,
    required String profileDigest,
    int profileSchemaVersion = konyakProfileSchemaVersion,
    ProfileSourceKind profileSourceKind = ProfileSourceKind.builtin,
  }) {
    final validatedPreInstallActions = preInstallActions.toIList();
    _validatePreInstallActions(validatedPreInstallActions);
    return ProgramProfileRecord._validated(
      profileSchemaVersion: ProfileSchemaVersion(profileSchemaVersion),
      profileId: ProfileId(profileId),
      profileVersion: ProfileVersion(profileVersion),
      profileSourceKind: profileSourceKind,
      profileSourceId: ProfileSourceId(profileSourceId),
      profileDigest: ProfileManifestDigest(profileDigest),
      managedProgramPath: ProgramPath(managedProgramPath),
      installerResource: installerResource,
      preInstallActions: validatedPreInstallActions,
      compatibilityProfileId: ProfileId(compatibilityProfileId),
      compatibilityProfileVersion: ProfileVersion(compatibilityProfileVersion),
    );
  }

  const factory ProgramProfileRecord._validated({
    required ProfileSchemaVersion profileSchemaVersion,
    required ProfileId profileId,
    required ProfileVersion profileVersion,
    required ProfileSourceKind profileSourceKind,
    required ProfileSourceId profileSourceId,
    required ProfileManifestDigest profileDigest,
    required ProgramPath managedProgramPath,
    required InstallerResourceRecord installerResource,
    required IList<PreInstallActionRecord> preInstallActions,
    required ProfileId compatibilityProfileId,
    required ProfileVersion compatibilityProfileVersion,
  }) = _ProgramProfileRecord;
}
