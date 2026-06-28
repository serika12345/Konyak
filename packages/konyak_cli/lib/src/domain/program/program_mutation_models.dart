import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';
import 'program_settings_models.dart';

class ProgramPinRequest {
  ProgramPinRequest({
    required String bottleId,
    required String name,
    required String programPath,
  }) : bottleId = BottleId(bottleId),
       name = ProgramName(name),
       programPath = ProgramPath(programPath);

  final BottleId bottleId;
  final ProgramName name;
  final ProgramPath programPath;
}

sealed class ProgramPinResult {
  const ProgramPinResult();
}

class ProgramPinned extends ProgramPinResult {
  const ProgramPinned(this.bottle);

  final BottleRecord bottle;
}

class ProgramPinMissing extends ProgramPinResult {
  ProgramPinMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class ProgramPinConflict extends ProgramPinResult {
  ProgramPinConflict(String programPath)
    : programPath = ProgramPath(programPath);

  final ProgramPath programPath;
}

class ProgramPinFailed extends ProgramPinResult {
  const ProgramPinFailed(this.message);

  final String message;
}

class ProgramUnpinRequest {
  ProgramUnpinRequest({required String bottleId, required String programPath})
    : bottleId = BottleId(bottleId),
      programPath = ProgramPath(programPath);

  final BottleId bottleId;
  final ProgramPath programPath;
}

class ProgramRenameRequest {
  ProgramRenameRequest({
    required String bottleId,
    required String programPath,
    required String name,
  }) : bottleId = BottleId(bottleId),
       programPath = ProgramPath(programPath),
       name = ProgramName(name);

  final BottleId bottleId;
  final ProgramPath programPath;
  final ProgramName name;
}

class PinnedProgramLauncherManifest {
  PinnedProgramLauncherManifest({
    required String launcherId,
    required String bottleId,
    required String programPath,
    required String programName,
  }) : launcherId = ProgramLauncherId(launcherId),
       bottleId = BottleId(bottleId),
       programPath = ProgramPath(programPath),
       programName = ProgramName(programName);

  final ProgramLauncherId launcherId;
  final BottleId bottleId;
  final ProgramPath programPath;
  final ProgramName programName;
}

class WineProcessTerminationRequest {
  WineProcessTerminationRequest({
    required String bottleId,
    required String processId,
  }) : bottleId = BottleId(bottleId),
       processId = WineProcessId(processId);

  final BottleId bottleId;
  final WineProcessId processId;
}

class WineProcessGroupTerminationRequest {
  WineProcessGroupTerminationRequest({
    Option<String> bottleId = const Option.none(),
  }) : bottleId = bottleId.map(BottleId.new);

  final Option<BottleId> bottleId;
}

sealed class ProgramUpdateResult {
  const ProgramUpdateResult();
}

class ProgramUpdated extends ProgramUpdateResult {
  const ProgramUpdated(this.bottle);

  final BottleRecord bottle;
}

class ProgramUpdateMissingBottle extends ProgramUpdateResult {
  ProgramUpdateMissingBottle(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class ProgramUpdateMissingProgram extends ProgramUpdateResult {
  ProgramUpdateMissingProgram(String programPath)
    : programPath = ProgramPath(programPath);

  final ProgramPath programPath;
}

class ProgramUpdateFailed extends ProgramUpdateResult {
  const ProgramUpdateFailed(this.message);

  final String message;
}

class ProgramSettingsRequest {
  ProgramSettingsRequest({
    required String bottleId,
    required String programPath,
  }) : bottleId = BottleId(bottleId),
       programPath = ProgramPath(programPath);

  final BottleId bottleId;
  final ProgramPath programPath;
}

class ProgramSettingsUpdateRequest {
  ProgramSettingsUpdateRequest({
    required String bottleId,
    required String programPath,
    required this.settings,
  }) : bottleId = BottleId(bottleId),
       programPath = ProgramPath(programPath);

  final BottleId bottleId;
  final ProgramPath programPath;
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
  ProgramSettingsReadMissingBottle(String bottleId)
    : bottleId = BottleId(bottleId);

  final BottleId bottleId;
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
  ProgramSettingsUpdateMissingBottle(String bottleId)
    : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class ProgramSettingsUpdateFailed extends ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateFailed(this.message);

  final String message;
}
