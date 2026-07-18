import 'dart:convert';

import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_wine_process_payload_parsers.dart';
import 'program_profile_install_contract.dart';

export 'konyak_cli_program_profile_install_progress_parser.dart';

const _maxPreInstallActions = 64;
const _maxPreInstallActionIdLength = 128;

sealed class _GraphicsBackendSignalParseResult {
  const _GraphicsBackendSignalParseResult();
}

final class _ParsedGraphicsBackendSignal
    extends _GraphicsBackendSignalParseResult {
  const _ParsedGraphicsBackendSignal(this.signal);

  final ProgramGraphicsBackendSignalSummary signal;
}

final class _InvalidGraphicsBackendSignal
    extends _GraphicsBackendSignalParseResult {
  const _InvalidGraphicsBackendSignal();
}

sealed class _GraphicsBackendSuggestionParseResult {
  const _GraphicsBackendSuggestionParseResult();
}

final class _ParsedGraphicsBackendSuggestion
    extends _GraphicsBackendSuggestionParseResult {
  const _ParsedGraphicsBackendSuggestion(this.suggestion);

  final ProgramGraphicsBackendSuggestionSummary suggestion;
}

final class _InvalidGraphicsBackendSuggestion
    extends _GraphicsBackendSuggestionParseResult {
  const _InvalidGraphicsBackendSuggestion();
}

sealed class _InstallProfileParseResult<T> {
  const _InstallProfileParseResult();
}

final class _ParsedInstallProfileValue<T>
    extends _InstallProfileParseResult<T> {
  const _ParsedInstallProfileValue(this.value);

  final T value;
}

final class _InvalidInstallProfileValue<T>
    extends _InstallProfileParseResult<T> {
  const _InvalidInstallProfileValue();
}

InstallProfileListLoadResult parseInstallProfileListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return InstallProfileListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const InstallProfileListLoadFailure(
      exitCode: 0,
      message: 'Unsupported install profile list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return InstallProfileListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Install profile list failed.',
      diagnostic: '',
    );
  }

  final profiles = decoded['installProfiles'];
  if (profiles is! List<Object?>) {
    return const InstallProfileListLoadFailure(
      exitCode: 0,
      message: 'Missing installProfiles payload.',
      diagnostic: '',
    );
  }

  final parsedProfiles = <InstallProfileListItem>[];
  for (final profile in profiles) {
    switch (_parseInstallProfileListItem(profile)) {
      case _ParsedInstallProfileValue(value: final profile):
        parsedProfiles.add(profile);
      case _InvalidInstallProfileValue():
        return const InstallProfileListLoadFailure(
          exitCode: 0,
          message: 'Invalid install profile record.',
          diagnostic: '',
        );
    }
  }

  return LoadedInstallProfiles(profiles: parsedProfiles);
}

InstallProfileInspectLoadResult parseInstallProfileInspectPayload(
  String payload,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return InstallProfileInspectLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const InstallProfileInspectLoadFailure(
      exitCode: 0,
      message: 'Unsupported install profile inspect payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return InstallProfileInspectLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Install profile inspect failed.',
      diagnostic: '',
    );
  }

  return switch (_parseInstallProfileDetails(decoded['installProfile'])) {
    _ParsedInstallProfileValue(value: final profile) => InspectedInstallProfile(
      profile,
    ),
    _InvalidInstallProfileValue() => const InstallProfileInspectLoadFailure(
      exitCode: 0,
      message: 'Invalid installProfile payload.',
      diagnostic: '',
    ),
  };
}

InstallProfileMutationLoadResult parseInstallProfileMutationPayload(
  String payload,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return InstallProfileMutationLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const InstallProfileMutationLoadFailure(
      exitCode: 0,
      message: 'Unsupported install profile mutation payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    return InstallProfileMutationLoadFailure(
      exitCode: 0,
      message: _installProfileMutationErrorMessage(error),
      diagnostic: '',
    );
  }

  final mutation = decoded['installProfileMutation'];
  if (mutation is! Map<String, Object?>) {
    return const InstallProfileMutationLoadFailure(
      exitCode: 0,
      message: 'Missing installProfileMutation payload.',
      diagnostic: '',
    );
  }

  final operation = mutation['operation'];
  return switch (operation) {
    'validate' => switch (_parseInstallProfileDetails(
      mutation['installProfile'],
    )) {
      _ParsedInstallProfileValue(value: final profile)
          when profile.profileSourceKind == 'user' =>
        ValidatedInstallProfile(profile),
      _ => const InstallProfileMutationLoadFailure(
        exitCode: 0,
        message: 'Invalid validated install profile payload.',
        diagnostic: '',
      ),
    },
    'import' => switch (_parseInstallProfileDetails(
      mutation['installProfile'],
    )) {
      _ParsedInstallProfileValue(value: final profile)
          when profile.profileSourceKind == 'user' =>
        ImportedInstallProfile(profile),
      _ => const InstallProfileMutationLoadFailure(
        exitCode: 0,
        message: 'Invalid imported install profile payload.',
        diagnostic: '',
      ),
    },
    'update' => switch (_parseInstallProfileDetails(
      mutation['installProfile'],
    )) {
      _ParsedInstallProfileValue(value: final profile)
          when profile.profileSourceKind == 'user' =>
        UpdatedInstallProfile(profile),
      _ => const InstallProfileMutationLoadFailure(
        exitCode: 0,
        message: 'Invalid updated install profile payload.',
        diagnostic: '',
      ),
    },
    'export' => switch ((
      _parseInstallProfileDetails(mutation['installProfile']),
      mutation['path'],
    )) {
      (_ParsedInstallProfileValue(value: final profile), final String path)
          when path.isNotEmpty =>
        ExportedInstallProfile(profile: profile, path: path),
      _ => const InstallProfileMutationLoadFailure(
        exitCode: 0,
        message: 'Invalid exported install profile payload.',
        diagnostic: '',
      ),
    },
    'delete' => switch ((mutation['profileId'], mutation['profileDigest'])) {
      (final String profileId, final String profileDigest)
          when profileId.isNotEmpty &&
              RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(profileDigest) =>
        DeletedInstallProfile(
          profileId: profileId,
          profileDigest: profileDigest.toLowerCase(),
        ),
      _ => const InstallProfileMutationLoadFailure(
        exitCode: 0,
        message: 'Invalid deleted install profile payload.',
        diagnostic: '',
      ),
    },
    _ => const InstallProfileMutationLoadFailure(
      exitCode: 0,
      message: 'Unsupported install profile mutation operation.',
      diagnostic: '',
    ),
  };
}

String _installProfileMutationErrorMessage(Map<String, Object?> error) {
  final message = switch (error['message']) {
    final String value when value.isNotEmpty => value,
    _ => 'Install profile mutation failed.',
  };
  final validationErrors = error['validationErrors'];
  if (validationErrors is! List<Object?> || validationErrors.isEmpty) {
    return message;
  }

  final issueLabels = validationErrors
      .whereType<Map<String, Object?>>()
      .map((issue) {
        final path = issue['path'];
        final issueMessage = issue['message'];
        return switch ((path, issueMessage)) {
          (final String path, final String issueMessage)
              when path.isNotEmpty && issueMessage.isNotEmpty =>
            '$path: $issueMessage',
          _ => '',
        };
      })
      .where((label) => label.isNotEmpty)
      .take(8)
      .toList(growable: false);
  return issueLabels.isEmpty ? message : '$message\n${issueLabels.join('\n')}';
}

ProgramProfileApplyLoadResult parseProgramProfileApplyPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramProfileApplyLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramProfileApplyLoadFailure(
      exitCode: 0,
      message: 'Unsupported program profile apply payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return ProgramProfileApplyLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Program profile apply failed.',
      diagnostic: '',
    );
  }

  return switch (_parseProgramProfileSummary(decoded['programProfile'])) {
    _ParsedInstallProfileValue(value: final profile) => AppliedProgramProfile(
      profile,
    ),
    _InvalidInstallProfileValue() => const ProgramProfileApplyLoadFailure(
      exitCode: 0,
      message: 'Invalid programProfile payload.',
      diagnostic: '',
    ),
  };
}

ProgramProfileInstallParseResult parseProgramProfileInstallPayload(
  String payload,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramProfileInstallParseFailure(error.message);
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramProfileInstallParseFailure(
      'Unsupported program profile install payload.',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return ProgramProfileInstallCommandFailure(
      message is String ? message : 'Program profile install failed.',
    );
  }

  final install = decoded['programProfileInstall'];
  if (install is! Map<String, Object?>) {
    return const ProgramProfileInstallParseFailure(
      'Missing programProfileInstall payload.',
    );
  }

  return switch (_parseProgramProfileSummary(install['programProfile'])) {
    _ParsedInstallProfileValue(value: final profile) =>
      ParsedProgramProfileInstall(profile),
    _InvalidInstallProfileValue() => const ProgramProfileInstallParseFailure(
      'Invalid programProfileInstall payload.',
    ),
  };
}

_InstallProfileParseResult<InstallProfileListItem> _parseInstallProfileListItem(
  Object? value,
) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final id = value['id'];
  final name = value['name'];
  final profileVersion = value['profileVersion'];
  final profileSourceKind = value['profileSourceKind'] ?? 'builtin';
  final profileDigest = value['profileDigest'] ?? '';
  final canEdit = value['canEdit'] ?? false;
  final canDelete = value['canDelete'] ?? false;
  if (id is! String ||
      name is! String ||
      profileVersion is! int ||
      profileSourceKind is! String ||
      !const <String>{'builtin', 'user'}.contains(profileSourceKind) ||
      profileDigest is! String ||
      (profileDigest.isNotEmpty &&
          !RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(profileDigest)) ||
      canEdit is! bool ||
      canDelete is! bool ||
      (profileSourceKind == 'builtin' && (canEdit || canDelete))) {
    return const _InvalidInstallProfileValue();
  }

  return _ParsedInstallProfileValue(
    InstallProfileListItem(
      id: id,
      name: name,
      profileVersion: profileVersion,
      profileSourceKind: profileSourceKind,
      profileDigest: profileDigest.toLowerCase(),
      canEdit: canEdit,
      canDelete: canDelete,
    ),
  );
}

_InstallProfileParseResult<InstallProfileDetails> _parseInstallProfileDetails(
  Object? value,
) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final id = value['id'];
  final name = value['name'];
  final profileVersion = value['profileVersion'];
  final profileSourceKind = value['profileSourceKind'];
  final profileSourceId = value['profileSourceId'];
  final profileDigest = value['profileDigest'];
  final summary = value['summary'];
  final platforms = _parseInstallProfileStringList(value['platforms']);
  final bottleTemplate = value['bottleTemplate'];
  final managedProgramPath = value['managedProgramPath'];
  final installerResource = _parseInstallerResourceSummary(
    value['installerResource'],
  );
  final preInstallActions = _parsePreInstallActions(value['preInstallActions']);
  final runCompletionPolicy = value['runCompletionPolicy'];
  final compatibilityProfile = _parseCompatibilityProfileSummary(
    value['compatibilityProfile'],
  );
  final manifest = value['manifest'];

  if (id is! String ||
      name is! String ||
      profileVersion is! int ||
      profileSourceKind is! String ||
      profileSourceId is! String ||
      profileDigest is! String ||
      !const <String>{'builtin', 'user'}.contains(profileSourceKind) ||
      profileSourceId.isEmpty ||
      !RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(profileDigest) ||
      summary is! String ||
      bottleTemplate is! Map<String, Object?> ||
      managedProgramPath is! String ||
      runCompletionPolicy is! String ||
      (manifest != null && manifest is! Map<String, Object?>)) {
    return const _InvalidInstallProfileValue();
  }

  final windowsVersion = bottleTemplate['windowsVersion'];
  if (windowsVersion is! String) {
    return const _InvalidInstallProfileValue();
  }

  return switch ((
    platforms,
    installerResource,
    preInstallActions,
    compatibilityProfile,
  )) {
    (
      _ParsedInstallProfileValue(value: final platforms),
      _ParsedInstallProfileValue(value: final installerResource),
      _ParsedInstallProfileValue(value: final preInstallActions),
      _ParsedInstallProfileValue(value: final compatibilityProfile),
    ) =>
      _ParsedInstallProfileValue(
        InstallProfileDetails(
          id: id,
          name: name,
          profileVersion: profileVersion,
          profileSourceKind: profileSourceKind,
          profileSourceId: profileSourceId,
          profileDigest: profileDigest.toLowerCase(),
          summary: summary,
          platforms: platforms,
          windowsVersion: windowsVersion,
          managedProgramPath: managedProgramPath,
          installerResource: installerResource,
          preInstallActions: preInstallActions,
          runCompletionPolicy: runCompletionPolicy,
          compatibilityProfile: compatibilityProfile,
          manifestJson: switch (manifest) {
            final Map<String, Object?> value => const JsonEncoder.withIndent(
              '  ',
            ).convert(value),
            _ => '',
          },
        ),
      ),
    _ => const _InvalidInstallProfileValue(),
  };
}

_InstallProfileParseResult<List<PreInstallActionSummary>>
_parsePreInstallActions(Object? value) {
  if (value is! List<Object?> || value.length > _maxPreInstallActions) {
    return const _InvalidInstallProfileValue();
  }
  final actions = <PreInstallActionSummary>[];
  final winetricksVerbs = <String>{};
  final nativeTargets = <String>{};
  for (final item in value) {
    if (item is! Map<String, Object?>) {
      return const _InvalidInstallProfileValue();
    }
    final kind = item['kind'];
    if (kind == 'winetricks') {
      final verb = item['verb'];
      if (verb is! String ||
          !_isPreInstallActionId(verb) ||
          !winetricksVerbs.add(verb)) {
        return const _InvalidInstallProfileValue();
      }
      actions.add(WinetricksPreInstallActionSummary(verb));
      continue;
    }
    if (kind != 'nativeDll') {
      return const _InvalidInstallProfileValue();
    }
    final componentId = item['componentId'];
    final machine = item['machine'];
    final destination = item['destination'];
    final targetFileName = item['targetFileName'];
    final resourceResult = _parseNativeDllResourceSummary(item['resource']);
    final machineDestinationMatches =
        (machine == 'x86' && destination == 'windowsSysWow64') ||
        (machine == 'x64' && destination == 'windowsSystem32');
    if (componentId is! String ||
        componentId.length > _maxPreInstallActionIdLength ||
        !RegExp(r'^[a-z0-9][a-z0-9_.-]*$').hasMatch(componentId) ||
        !machineDestinationMatches ||
        targetFileName is! String ||
        !isSafeNativeDllFileName(targetFileName) ||
        resourceResult
            is! _ParsedInstallProfileValue<NativeDllResourceSummary>) {
      return const _InvalidInstallProfileValue();
    }
    final nativeTarget = '$destination/${targetFileName.toLowerCase()}';
    if (!nativeTargets.add(nativeTarget)) {
      return const _InvalidInstallProfileValue();
    }
    actions.add(
      NativeDllPreInstallActionSummary(
        componentId: componentId,
        machine: machine as String,
        destination: destination as String,
        targetFileName: targetFileName,
        resource: resourceResult.value,
      ),
    );
  }
  return _ParsedInstallProfileValue(List.unmodifiable(actions));
}

bool _isPreInstallActionId(String value) =>
    value.length <= _maxPreInstallActionIdLength &&
    RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(value);

_InstallProfileParseResult<NativeDllResourceSummary>
_parseNativeDllResourceSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }
  try {
    final kind = value['kind'];
    final url = value['url'];
    final sha256 = value['sha256'];
    final fileName = value['fileName'];
    if (kind is! String ||
        url is! String ||
        sha256 is! String ||
        fileName is! String) {
      return const _InvalidInstallProfileValue();
    }
    return _ParsedInstallProfileValue(
      NativeDllResourceSummary(
        kind: kind,
        url: url,
        sha256: sha256,
        fileName: fileName,
      ),
    );
  } on ArgumentError {
    return const _InvalidInstallProfileValue();
  }
}

_InstallProfileParseResult<InstallerResourceSummary>
_parseInstallerResourceSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final kind = value['kind'];
  final url = value['url'];
  final sha256 = value['sha256'];
  final fileName = value['fileName'];
  if (kind is! String ||
      url is! String ||
      sha256 is! String ||
      fileName is! String) {
    return const _InvalidInstallProfileValue();
  }

  try {
    return _ParsedInstallProfileValue(
      InstallerResourceSummary(
        kind: kind,
        url: url,
        sha256: sha256,
        fileName: fileName,
      ),
    );
  } on ArgumentError {
    return const _InvalidInstallProfileValue();
  }
}

_InstallProfileParseResult<CompatibilityProfileSummary>
_parseCompatibilityProfileSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final id = value['id'];
  final profileVersion = value['profileVersion'];
  final childProcessRules = value['childProcessRules'];
  if (id is! String ||
      profileVersion is! int ||
      childProcessRules is! List<Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final parsedRules = <ChildProcessCompatibilityRuleSummary>[];
  for (final rule in childProcessRules) {
    switch (_parseChildProcessCompatibilityRuleSummary(rule)) {
      case _ParsedInstallProfileValue(value: final rule):
        parsedRules.add(rule);
      case _InvalidInstallProfileValue():
        return const _InvalidInstallProfileValue();
    }
  }

  return _ParsedInstallProfileValue(
    CompatibilityProfileSummary(
      id: id,
      profileVersion: profileVersion,
      childProcessRules: parsedRules,
    ),
  );
}

_InstallProfileParseResult<ChildProcessCompatibilityRuleSummary>
_parseChildProcessCompatibilityRuleSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final executableSuffix = value['executableSuffix'];
  final appendArgumentsIfMissing = _parseInstallProfileStringList(
    value['appendArgumentsIfMissing'],
  );
  if (executableSuffix is! String) {
    return const _InvalidInstallProfileValue();
  }

  return switch (appendArgumentsIfMissing) {
    _ParsedInstallProfileValue(value: final appendArgumentsIfMissing) =>
      _ParsedInstallProfileValue(
        ChildProcessCompatibilityRuleSummary(
          executableSuffix: executableSuffix,
          appendArgumentsIfMissing: appendArgumentsIfMissing,
        ),
      ),
    _InvalidInstallProfileValue() => const _InvalidInstallProfileValue(),
  };
}

_InstallProfileParseResult<ProgramProfileSummary> _parseProgramProfileSummary(
  Object? value,
) {
  if (value is! Map<String, Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final bottleId = value['bottleId'];
  final profileId = value['profileId'];
  final profileVersion = value['profileVersion'];
  final managedProgramPath = value['managedProgramPath'];
  final compatibilityProfileId = value['compatibilityProfileId'];
  final compatibilityProfileVersion = value['compatibilityProfileVersion'];

  if (bottleId is! String ||
      profileId is! String ||
      profileVersion is! int ||
      managedProgramPath is! String ||
      compatibilityProfileId is! String ||
      compatibilityProfileVersion is! int) {
    return const _InvalidInstallProfileValue();
  }

  return _ParsedInstallProfileValue(
    ProgramProfileSummary(
      bottleId: bottleId,
      profileId: profileId,
      profileVersion: profileVersion,
      managedProgramPath: managedProgramPath,
      compatibilityProfileId: compatibilityProfileId,
      compatibilityProfileVersion: compatibilityProfileVersion,
    ),
  );
}

_InstallProfileParseResult<List<String>> _parseInstallProfileStringList(
  Object? value,
) {
  if (value is! List<Object?>) {
    return const _InvalidInstallProfileValue();
  }

  final strings = value.whereType<String>().toList(growable: false);
  if (strings.length != value.length) {
    return const _InvalidInstallProfileValue();
  }

  return _ParsedInstallProfileValue(List.unmodifiable(strings));
}

BottleProgramListLoadResult parseBottleProgramListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle program list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle program list failed.',
      diagnostic: '',
    );
  }

  final bottlePrograms = decoded['bottlePrograms'];
  if (bottlePrograms is! Map<String, Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Missing bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final bottleId = bottlePrograms['bottleId'];
  final programs = bottlePrograms['programs'];
  if (bottleId is! String || programs is! List<Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Invalid bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final parsedPrograms = <BottleProgramSummary>[];
  for (final program in programs) {
    if (program is! Map<String, Object?>) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final id = program['id'];
    final name = program['name'];
    final path = program['path'];
    final source = program['source'];
    if (id is! String ||
        name is! String ||
        path is! String ||
        source is! String) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    switch (parseProgramMetadata(program['metadata'])) {
      case ParsedProgramMetadata(:final metadata):
        parsedPrograms.add(
          BottleProgramSummary(
            id: id,
            name: name,
            path: path,
            source: source,
            metadata: metadata,
          ),
        );
      case NoProgramMetadata():
        parsedPrograms.add(
          BottleProgramSummary(id: id, name: name, path: path, source: source),
        );
      case InvalidProgramMetadata():
        return const BottleProgramListLoadFailure(
          exitCode: 0,
          message: 'Invalid bottle program record.',
          diagnostic: '',
        );
    }
  }

  return LoadedBottlePrograms(
    bottleId: bottleId,
    programs: List.unmodifiable(parsedPrograms),
  );
}

GraphicsBackendHintsLoadResult parseGraphicsBackendHintsPayload(
  String payload,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: 'Unsupported graphics backend hints payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Graphics backend hint failed.',
      diagnostic: '',
    );
  }

  final hints = decoded['graphicsBackendHints'];
  if (hints is! Map<String, Object?>) {
    return const GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: 'Missing graphicsBackendHints payload.',
      diagnostic: '',
    );
  }

  final programPath = hints['programPath'];
  final hostPlatform = hints['hostPlatform'];
  final signals = hints['signals'];
  final suggestions = hints['suggestions'];
  if (programPath is! String ||
      hostPlatform is! String ||
      signals is! List<Object?> ||
      suggestions is! List<Object?>) {
    return const GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: 'Invalid graphicsBackendHints payload.',
      diagnostic: '',
    );
  }

  final parsedSignals = <ProgramGraphicsBackendSignalSummary>[];
  for (final signal in signals) {
    switch (_parseGraphicsBackendSignal(signal)) {
      case _ParsedGraphicsBackendSignal(:final signal):
        parsedSignals.add(signal);
      case _InvalidGraphicsBackendSignal():
        return const GraphicsBackendHintsLoadFailure(
          exitCode: 0,
          message: 'Invalid graphics backend signal.',
          diagnostic: '',
        );
    }
  }

  final parsedSuggestions = <ProgramGraphicsBackendSuggestionSummary>[];
  for (final suggestion in suggestions) {
    switch (_parseGraphicsBackendSuggestion(suggestion)) {
      case _ParsedGraphicsBackendSuggestion(:final suggestion):
        parsedSuggestions.add(suggestion);
      case _InvalidGraphicsBackendSuggestion():
        return const GraphicsBackendHintsLoadFailure(
          exitCode: 0,
          message: 'Invalid graphics backend suggestion.',
          diagnostic: '',
        );
    }
  }

  return LoadedGraphicsBackendHints(
    ProgramGraphicsBackendHintsSummary(
      programPath: programPath,
      hostPlatform: hostPlatform,
      signals: parsedSignals,
      suggestions: parsedSuggestions,
    ),
  );
}

_GraphicsBackendSignalParseResult _parseGraphicsBackendSignal(Object? signal) {
  if (signal is! Map<String, Object?>) {
    return const _InvalidGraphicsBackendSignal();
  }

  final kind = signal['kind'];
  final value = signal['value'];
  if (kind is! String || value is! String) {
    return const _InvalidGraphicsBackendSignal();
  }

  return _ParsedGraphicsBackendSignal(
    ProgramGraphicsBackendSignalSummary(kind: kind, value: value),
  );
}

_GraphicsBackendSuggestionParseResult _parseGraphicsBackendSuggestion(
  Object? suggestion,
) {
  if (suggestion is! Map<String, Object?>) {
    return const _InvalidGraphicsBackendSuggestion();
  }

  final backend = suggestion['backend'];
  final confidence = suggestion['confidence'];
  final reason = suggestion['reason'];
  if (backend is! String || confidence is! String || reason is! String) {
    return const _InvalidGraphicsBackendSuggestion();
  }

  return _ParsedGraphicsBackendSuggestion(
    ProgramGraphicsBackendSuggestionSummary(
      backend: backend,
      confidence: confidence,
      reason: reason,
    ),
  );
}
