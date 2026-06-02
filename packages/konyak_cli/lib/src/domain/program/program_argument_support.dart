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
  final arguments = settings.arguments.trim();
  if (arguments.isEmpty) {
    return const <String>[];
  }

  return arguments.split(RegExp(r'\s+'));
}

Map<String, String> _programSettingsEnvironment(
  ProgramSettingsRecord settings,
) {
  final environment = <String, String>{...settings.environment.toMap()};
  if (settings.locale.trim().isNotEmpty) {
    environment['LC_ALL'] = settings.locale;
  }

  return environment;
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
    'terminal' ||
    'winetricks' => Option.of(normalized),
    _ => const Option.none(),
  };
}
