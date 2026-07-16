import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';

part 'program_settings_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramWorkingDirectorySetting
    with _$ProgramWorkingDirectorySetting {
  const ProgramWorkingDirectorySetting._();

  const factory ProgramWorkingDirectorySetting.executableDirectory() =
      ExecutableDirectoryProgramWorkingDirectorySetting;

  const factory ProgramWorkingDirectorySetting.custom(
    WindowsProgramWorkingDirectoryPath path,
  ) = CustomProgramWorkingDirectorySetting;
}

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
    ProgramWorkingDirectorySetting workingDirectory =
        const ProgramWorkingDirectorySetting.executableDirectory(),
    ProgramEnvironmentOverrides environment =
        const ProgramEnvironmentOverrides.empty(),
    Option<ProgramLoggingSettingsRecord> logging = const Option.none(),
  }) {
    return ProgramSettingsRecord._validated(
      locale: locale,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      logging: logging,
    );
  }

  const factory ProgramSettingsRecord._validated({
    required ProgramLocale locale,
    required ProgramArguments arguments,
    required ProgramWorkingDirectorySetting workingDirectory,
    required ProgramEnvironmentOverrides environment,
    required Option<ProgramLoggingSettingsRecord> logging,
  }) = _ProgramSettingsRecord;
}

Option<ProgramWorkingDirectoryPath> resolveProgramWorkingDirectory({
  required BottleRecord bottle,
  required ProgramPath executableHostPath,
  required ProgramWorkingDirectorySetting setting,
}) {
  return switch (setting) {
    ExecutableDirectoryProgramWorkingDirectorySetting() =>
      _programExecutableHostPath(
        bottle: bottle,
        programPath: executableHostPath,
      ).flatMap(_parentProgramWorkingDirectory),
    CustomProgramWorkingDirectorySetting(:final path) => Option.of(
      ProgramWorkingDirectoryPath(
        domainJoinPath(bottle.path.value, <String>[
          'drive_c',
          ...path.value
              .substring(3)
              .split('\\')
              .where((part) => part.isNotEmpty),
        ]),
      ),
    ),
  };
}

Option<String> _programExecutableHostPath({
  required BottleRecord bottle,
  required ProgramPath programPath,
}) {
  final normalized = programPath.value.trim().replaceAll('\\', '/');
  final hasControlCharacter = RegExp(
    r'[\x00-\x1F\x7F-\x9F]',
  ).hasMatch(programPath.value);
  final hasDotSegment = normalized
      .split('/')
      .any((part) => part == '.' || part == '..');
  final cDrivePath = RegExp(r'^C:/', caseSensitive: false).hasMatch(normalized);
  final zDrivePath = RegExp(r'^Z:/', caseSensitive: false).hasMatch(normalized);
  return switch (normalized) {
    _ when hasControlCharacter || hasDotSegment => const Option.none(),
    _ when cDrivePath => Option.of(
      domainJoinPath(bottle.path.value, <String>[
        'drive_c',
        ...normalized.substring(3).split('/').where((part) => part.isNotEmpty),
      ]),
    ),
    _ when zDrivePath => Option.of('/${normalized.substring(3)}'),
    _ when normalized.startsWith('/') => Option.of(normalized),
    _ => const Option.none(),
  };
}

Option<ProgramWorkingDirectoryPath> _parentProgramWorkingDirectory(
  String path,
) {
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final separator = normalized.lastIndexOf('/');
  return switch (separator) {
    < 0 => const Option.none(),
    0 => Option.of(ProgramWorkingDirectoryPath('/')),
    _ => Option.of(
      ProgramWorkingDirectoryPath(normalized.substring(0, separator)),
    ),
  };
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
