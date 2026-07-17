import 'dart:convert';

import 'program_profile_install_contract.dart';

const _maxPreInstallActions = 64;
const _maxPreInstallActionIdLength = 128;

ProgramProfileInstallProgressParseResult
parseProgramProfileInstallProgressPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const InvalidProgramProfileInstallProgress();
  }
  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != programProfileInstallSchemaVersion) {
    return const InvalidProgramProfileInstallProgress();
  }

  final progress = decoded['programProfileInstallProgress'];
  if (progress is! Map<String, dynamic>) {
    return const InvalidProgramProfileInstallProgress();
  }
  final stage = _parseProgramProfileInstallStage(progress['stage']);
  final state = progress['state'];
  final action = _parseProgramProfileInstallAction(progress);
  if (stage == null || state is! String || action == null) {
    return const InvalidProgramProfileInstallProgress();
  }

  return switch (state) {
    'started' => ParsedProgramProfileInstallProgress(
      StartedProgramProfileInstallStage(stage: stage, action: action),
    ),
    'completed' => ParsedProgramProfileInstallProgress(
      CompletedProgramProfileInstallStage(stage: stage, action: action),
    ),
    'failed' => switch (progress['code']) {
      final String code when code.isNotEmpty =>
        ParsedProgramProfileInstallProgress(
          FailedProgramProfileInstallStage(
            stage: stage,
            action: action,
            code: code,
          ),
        ),
      _ => const InvalidProgramProfileInstallProgress(),
    },
    _ => const InvalidProgramProfileInstallProgress(),
  };
}

ProgramProfileInstallStage? _parseProgramProfileInstallStage(Object? value) {
  return switch (value) {
    'preflight' => ProgramProfileInstallStage.preflight,
    'download' => ProgramProfileInstallStage.download,
    'verification' => ProgramProfileInstallStage.verification,
    'installer' => ProgramProfileInstallStage.installer,
    'resourceCleanup' => ProgramProfileInstallStage.resourceCleanup,
    'preInstallAction' => ProgramProfileInstallStage.preInstallAction,
    'managedProgram' => ProgramProfileInstallStage.managedProgram,
    'persistence' => ProgramProfileInstallStage.persistence,
    _ => null,
  };
}

ProgramProfileInstallActionContext? _parseProgramProfileInstallAction(
  Map<String, dynamic> progress,
) {
  final index = progress['actionIndex'];
  final kind = progress['actionKind'];
  final id = progress['actionId'];
  return switch ((index, kind, id)) {
    (null, null, null) => const NoProgramProfileInstallAction(),
    (final int index, final String kind, final String id)
        when index >= 0 &&
            index < _maxPreInstallActions &&
            (kind == 'winetricks' || kind == 'nativeDll') &&
            _isPreInstallActionId(id) =>
      ProgramProfileInstallAction(index: index, kind: kind, id: id),
    _ => null,
  };
}

bool _isPreInstallActionId(String value) {
  return value.isNotEmpty &&
      value.length <= _maxPreInstallActionIdLength &&
      !value.contains(RegExp(r'[\\/\x00-\x1f\x7f]'));
}
