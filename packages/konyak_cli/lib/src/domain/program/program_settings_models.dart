import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';

part 'program_settings_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramSettingsRecord with _$ProgramSettingsRecord {
  const ProgramSettingsRecord._();

  factory ProgramSettingsRecord({
    ProgramLocale locale = ProgramLocale.empty,
    ProgramArguments arguments = ProgramArguments.empty,
    ProgramEnvironmentOverrides environment =
        const ProgramEnvironmentOverrides.empty(),
    Option<ProgramLoggingSettingsRecord> logging = const Option.none(),
  }) {
    return ProgramSettingsRecord._validated(
      locale: locale,
      arguments: arguments,
      environment: environment,
      logging: logging,
    );
  }

  const factory ProgramSettingsRecord._validated({
    required ProgramLocale locale,
    required ProgramArguments arguments,
    required ProgramEnvironmentOverrides environment,
    required Option<ProgramLoggingSettingsRecord> logging,
  }) = _ProgramSettingsRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramLoggingSettingsRecord
    with _$ProgramLoggingSettingsRecord {
  const ProgramLoggingSettingsRecord._();

  factory ProgramLoggingSettingsRecord({
    bool createLogFile = true,
    WineDebugChannels additionalWineLoggingChannels = WineDebugChannels.empty,
    ProgramLogPath logFilePath = ProgramLogPath.empty,
  }) {
    return ProgramLoggingSettingsRecord._validated(
      createLogFile: createLogFile,
      additionalWineLoggingChannels: additionalWineLoggingChannels,
      logFilePath: logFilePath,
    );
  }

  const factory ProgramLoggingSettingsRecord._validated({
    required bool createLogFile,
    required WineDebugChannels additionalWineLoggingChannels,
    required ProgramLogPath logFilePath,
  }) = _ProgramLoggingSettingsRecord;
}
