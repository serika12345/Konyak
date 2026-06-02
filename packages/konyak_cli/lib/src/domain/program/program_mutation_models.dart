part of '../../../konyak_cli.dart';

class ProgramPinRequest {
  const ProgramPinRequest({
    required this.bottleId,
    required this.name,
    required this.programPath,
  });

  final String bottleId;
  final String name;
  final String programPath;
}

sealed class ProgramPinResult {
  const ProgramPinResult();
}

class ProgramPinned extends ProgramPinResult {
  const ProgramPinned(this.bottle);

  final BottleRecord bottle;
}

class ProgramPinMissing extends ProgramPinResult {
  const ProgramPinMissing(this.bottleId);

  final String bottleId;
}

class ProgramPinConflict extends ProgramPinResult {
  const ProgramPinConflict(this.programPath);

  final String programPath;
}

class ProgramPinFailed extends ProgramPinResult {
  const ProgramPinFailed(this.message);

  final String message;
}

class ProgramUnpinRequest {
  const ProgramUnpinRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

class ProgramRenameRequest {
  const ProgramRenameRequest({
    required this.bottleId,
    required this.programPath,
    required this.name,
  });

  final String bottleId;
  final String programPath;
  final String name;
}

class _PinnedProgramLauncherManifest {
  const _PinnedProgramLauncherManifest({
    required this.launcherId,
    required this.bottleId,
    required this.programPath,
    required this.programName,
  });

  final String launcherId;
  final String bottleId;
  final String programPath;
  final String programName;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'createdBy': konyakMacosBundleIdentifier,
      'launcherId': launcherId,
      'bottleId': bottleId,
      'programPath': programPath,
      'programName': programName,
    };
  }
}

class WineProcessTerminationRequest {
  const WineProcessTerminationRequest({
    required this.bottleId,
    required this.processId,
  });

  final String bottleId;
  final String processId;
}

class WineProcessGroupTerminationRequest {
  const WineProcessGroupTerminationRequest({
    this.bottleId = const Option.none(),
  });

  final Option<String> bottleId;
}

sealed class ProgramUpdateResult {
  const ProgramUpdateResult();
}

class ProgramUpdated extends ProgramUpdateResult {
  const ProgramUpdated(this.bottle);

  final BottleRecord bottle;
}

class ProgramUpdateMissingBottle extends ProgramUpdateResult {
  const ProgramUpdateMissingBottle(this.bottleId);

  final String bottleId;
}

class ProgramUpdateMissingProgram extends ProgramUpdateResult {
  const ProgramUpdateMissingProgram(this.programPath);

  final String programPath;
}

class ProgramUpdateFailed extends ProgramUpdateResult {
  const ProgramUpdateFailed(this.message);

  final String message;
}

class ProgramSettingsRequest {
  const ProgramSettingsRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

class ProgramSettingsUpdateRequest {
  const ProgramSettingsUpdateRequest({
    required this.bottleId,
    required this.programPath,
    required this.settings,
  });

  final String bottleId;
  final String programPath;
  final ProgramSettingsRecord settings;
}

sealed class ProgramSettingsReadResult {
  const ProgramSettingsReadResult();
}

class ProgramSettingsRead extends ProgramSettingsReadResult {
  const ProgramSettingsRead(this.settings);

  final ProgramSettingsRecord settings;
}

class ProgramSettingsReadMissingBottle extends ProgramSettingsReadResult {
  const ProgramSettingsReadMissingBottle(this.bottleId);

  final String bottleId;
}

class ProgramSettingsReadFailed extends ProgramSettingsReadResult {
  const ProgramSettingsReadFailed(this.message);

  final String message;
}

sealed class ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateResult();
}

class ProgramSettingsUpdated extends ProgramSettingsUpdateResult {
  const ProgramSettingsUpdated(this.settings);

  final ProgramSettingsRecord settings;
}

class ProgramSettingsUpdateMissingBottle extends ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateMissingBottle(this.bottleId);

  final String bottleId;
}

class ProgramSettingsUpdateFailed extends ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateFailed(this.message);

  final String message;
}
