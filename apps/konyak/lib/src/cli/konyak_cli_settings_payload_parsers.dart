import 'dart:convert';

import '../bottles/bottle_summary.dart';
import '../settings/app_settings_summary.dart';
import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_settings_result_types.dart';

sealed class AppSettingsSummaryParseResult {
  const AppSettingsSummaryParseResult();
}

final class ParsedAppSettingsSummary extends AppSettingsSummaryParseResult {
  const ParsedAppSettingsSummary(this.settings);

  final AppSettingsSummary settings;
}

final class InvalidAppSettingsSummary extends AppSettingsSummaryParseResult {
  const InvalidAppSettingsSummary();
}

sealed class ProgramSettingsSummaryParseResult {
  const ProgramSettingsSummaryParseResult();
}

final class ParsedProgramSettingsSummary
    extends ProgramSettingsSummaryParseResult {
  const ParsedProgramSettingsSummary(this.settings);

  final ProgramSettingsSummary settings;
}

final class InvalidProgramSettingsSummary
    extends ProgramSettingsSummaryParseResult {
  const InvalidProgramSettingsSummary();
}

sealed class ProgramLoggingSettingsSummaryParseResult {
  const ProgramLoggingSettingsSummaryParseResult();
}

final class ParsedProgramLoggingSettingsSummary
    extends ProgramLoggingSettingsSummaryParseResult {
  const ParsedProgramLoggingSettingsSummary(this.logging);

  final ProgramLoggingSettingsSummary logging;
}

final class InvalidProgramLoggingSettingsSummary
    extends ProgramLoggingSettingsSummaryParseResult {
  const InvalidProgramLoggingSettingsSummary();
}

sealed class StringMapParseResult {
  const StringMapParseResult();
}

final class ParsedStringMap extends StringMapParseResult {
  const ParsedStringMap(this.value);

  final Map<String, String> value;
}

final class InvalidStringMap extends StringMapParseResult {
  const InvalidStringMap();
}

ProgramSettingsLoadResult parseProgramSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported program settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final code = error['code'];
    final bottleId = error['bottleId'];
    final message = error['message'];
    if (code == 'bottleNotFound' && bottleId is String && message is String) {
      return MissingProgramSettingsBottle(bottleId: bottleId, message: message);
    }

    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Program settings failed.',
      diagnostic: '',
    );
  }

  final programSettings = decoded['programSettings'];
  if (programSettings is! Map<String, Object?>) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Missing programSettings payload.',
      diagnostic: '',
    );
  }

  final bottleId = programSettings['bottleId'];
  final programPath = programSettings['programPath'];
  final settings = parseProgramSettingsSummary(programSettings['settings']);
  if (bottleId is! String || programPath is! String) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid programSettings payload.',
      diagnostic: '',
    );
  }

  return switch (settings) {
    ParsedProgramSettingsSummary(:final settings) => LoadedProgramSettings(
      bottleId: bottleId,
      programPath: programPath,
      settings: settings,
    ),
    InvalidProgramSettingsSummary() => const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid programSettings payload.',
      diagnostic: '',
    ),
  };
}

AppSettingsLoadResult parseAppSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported app settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'App settings failed.',
      diagnostic: '',
    );
  }

  final settings = parseAppSettingsSummary(decoded['appSettings']);
  return switch (settings) {
    ParsedAppSettingsSummary(:final settings) => LoadedAppSettings(settings),
    InvalidAppSettingsSummary() => const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid appSettings payload.',
      diagnostic: '',
    ),
  };
}

AppSettingsSummaryParseResult parseAppSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const InvalidAppSettingsSummary();
  }

  final terminateWineProcessesOnClose = value['terminateWineProcessesOnClose'];
  final defaultBottlePath = value['defaultBottlePath'];
  final appearanceMode = appAppearanceModeFromJson(value['appearanceMode']);
  final languageMode = appLanguageModeFromJson(value['languageMode']);
  final automaticallyCheckForKonyakUpdates =
      value['automaticallyCheckForKonyakUpdates'];
  final automaticallyCheckForWineUpdates =
      value['automaticallyCheckForWineUpdates'];
  final automaticallyPinNewInstalledPrograms =
      value['automaticallyPinNewInstalledPrograms'];

  if (terminateWineProcessesOnClose is! bool ||
      defaultBottlePath is! String ||
      defaultBottlePath.trim().isEmpty ||
      appearanceMode == null ||
      languageMode == null ||
      automaticallyCheckForKonyakUpdates is! bool ||
      automaticallyCheckForWineUpdates is! bool ||
      (automaticallyPinNewInstalledPrograms != null &&
          automaticallyPinNewInstalledPrograms is! bool)) {
    return const InvalidAppSettingsSummary();
  }

  return ParsedAppSettingsSummary(
    AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms is bool
          ? automaticallyPinNewInstalledPrograms
          : true,
    ),
  );
}

ProgramSettingsSummaryParseResult parseProgramSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const InvalidProgramSettingsSummary();
  }

  final locale = value['locale'];
  final arguments = value['arguments'];
  final workingDirectory = parseProgramWorkingDirectorySummary(
    value['workingDirectory'],
  );
  final environment = parseStringMap(value['environment']);
  final logging = parseProgramLoggingSettingsSummary(value['logging']);
  if (locale is! String || arguments is! String) {
    return const InvalidProgramSettingsSummary();
  }

  return switch ((workingDirectory, environment, logging)) {
    (
      final ProgramWorkingDirectorySummary workingDirectory,
      ParsedStringMap(value: final environment),
      ParsedProgramLoggingSettingsSummary(logging: final logging),
    ) =>
      ParsedProgramSettingsSummary(
        ProgramSettingsSummary(
          locale: locale,
          arguments: arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          logging: logging,
        ),
      ),
    _ => const InvalidProgramSettingsSummary(),
  };
}

ProgramWorkingDirectorySummary? parseProgramWorkingDirectorySummary(
  Object? value,
) {
  if (value == null) {
    return const ProgramWorkingDirectorySummary.executableDirectory();
  }
  if (value is! Map<String, Object?>) {
    return null;
  }
  final kind = value['kind'];
  final path = value['path'];
  return switch ((kind, path)) {
    ('executableDirectory', null) =>
      const ProgramWorkingDirectorySummary.executableDirectory(),
    ('custom', final String path)
        when isValidWindowsProgramWorkingDirectory(path) =>
      ProgramWorkingDirectorySummary.custom(path),
    _ => null,
  };
}

ProgramLoggingSettingsSummaryParseResult parseProgramLoggingSettingsSummary(
  Object? value,
) {
  if (value == null) {
    return const ParsedProgramLoggingSettingsSummary(
      ProgramLoggingSettingsSummary(),
    );
  }
  if (value is! Map<String, Object?>) {
    return const InvalidProgramLoggingSettingsSummary();
  }

  final createLogFile = value['createLogFile'];
  final additionalWineLoggingChannels = value['additionalWineLoggingChannels'];
  final logFilePath = value['logFilePath'];
  if ((createLogFile != null && createLogFile is! bool) ||
      (additionalWineLoggingChannels != null &&
          additionalWineLoggingChannels is! String) ||
      (logFilePath != null && logFilePath is! String)) {
    return const InvalidProgramLoggingSettingsSummary();
  }

  return ParsedProgramLoggingSettingsSummary(
    ProgramLoggingSettingsSummary(
      createLogFile: createLogFile is bool ? createLogFile : true,
      additionalWineLoggingChannels: additionalWineLoggingChannels is String
          ? additionalWineLoggingChannels
          : '',
      logFilePath: logFilePath is String ? logFilePath : '',
    ),
  );
}

StringMapParseResult parseStringMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return const InvalidStringMap();
  }

  final environment = <String, String>{};
  for (final entry in value.entries) {
    if (entry.value is! String) {
      return const InvalidStringMap();
    }
    environment[entry.key] = entry.value as String;
  }

  return ParsedStringMap(Map.unmodifiable(environment));
}

bool isOptionalString(Object? value) {
  return value == null || value is String;
}
