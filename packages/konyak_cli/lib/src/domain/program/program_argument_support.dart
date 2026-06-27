part of '../../../konyak_cli.dart';

List<String> _wineArgumentsForProgramPath(String programPath) {
  final lowerCasePath = programPath.toLowerCase();

  if (lowerCasePath.endsWith('.exe')) {
    return <String>[programPath];
  }

  if (lowerCasePath.endsWith('.msi')) {
    return <String>['msiexec', '/i', programPath];
  }

  if (lowerCasePath.endsWith('.bat') || lowerCasePath.endsWith('.cmd')) {
    return <String>['cmd', '/c', programPath];
  }

  if (lowerCasePath.endsWith('.lnk')) {
    return <String>['start', '/unix', programPath];
  }

  throw StateError('Unsupported program path: $programPath');
}

List<String> _programSettingsArguments(ProgramSettingsRecord settings) {
  final arguments = settings.arguments.value.trim();
  if (arguments.isEmpty) {
    return const <String>[];
  }

  return arguments.split(RegExp(r'\s+'));
}

List<String> _wineArgumentsForBottleCommand(String command) {
  return switch (command) {
    'dxdiag' => const <String>[
      'cmd',
      '/c',
      'dxdiag /t C:\\konyak-dxdiag.txt && start "" notepad C:\\konyak-dxdiag.txt',
    ],
    _ => <String>[command],
  };
}

ProgramRunEnvironment _programSettingsEnvironment(
  ProgramSettingsRecord settings,
) {
  final environment = <String, String>{...settings.environment.toMap()};
  if (settings.locale.value.trim().isNotEmpty) {
    environment['LC_ALL'] = settings.locale.value;
  }
  final logging = _programSettingsLogging(settings);
  final loggingChannels = logging.additionalWineLoggingChannels.value.trim();
  if (loggingChannels.isNotEmpty) {
    environment['WINEDEBUG'] = _combinedWineDebugChannels(
      existingChannels: environment['WINEDEBUG'],
      additionalChannels: loggingChannels,
    );
  }

  return ProgramRunEnvironment(environment);
}

ProgramLoggingSettingsRecord _programSettingsLogging(
  ProgramSettingsRecord settings,
) {
  return settings.logging.getOrElse(ProgramLoggingSettingsRecord.new);
}

String _programSettingsLogPath({
  required BottleRecord bottle,
  required ProgramSettingsRecord settings,
}) {
  final logFilePath = _programSettingsLogging(
    settings,
  ).logFilePath.value.trim();
  if (logFilePath.isNotEmpty) {
    return logFilePath;
  }

  return _joinPath(bottle.path.value, const ['logs', 'latest.log']);
}

String _combinedWineDebugChannels({
  required String? existingChannels,
  required String additionalChannels,
}) {
  final existing = existingChannels?.trim() ?? '';
  final additional = additionalChannels.trim();
  if (existing.isEmpty) {
    return additional;
  }
  if (additional.isEmpty) {
    return existing;
  }

  return '$existing,$additional';
}

bool _isSupportedProgramPath(String programPath) {
  final lowerCasePath = programPath.toLowerCase();

  return lowerCasePath.endsWith('.exe') ||
      lowerCasePath.endsWith('.msi') ||
      lowerCasePath.endsWith('.bat') ||
      lowerCasePath.endsWith('.cmd') ||
      lowerCasePath.endsWith('.lnk');
}

Option<String> _supportedBottleCommand(String command) {
  final normalized = command.trim().toLowerCase();
  return switch (normalized) {
    'winecfg' ||
    'regedit' ||
    'control' ||
    'uninstaller' ||
    'simulate-reboot' ||
    'taskmgr' ||
    'cmd' ||
    'explorer' ||
    'dxdiag' ||
    'winver' ||
    'terminal' ||
    'winetricks' => Option.of(normalized),
    _ => const Option.none(),
  };
}
