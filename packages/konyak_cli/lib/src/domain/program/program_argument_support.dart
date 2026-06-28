import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_helpers.dart';
import 'program_run_environment.dart';
import 'program_settings_models.dart';

Option<List<String>> wineArgumentsForProgramPath(String programPath) {
  final lowerCasePath = programPath.toLowerCase();

  if (lowerCasePath.endsWith('.exe')) {
    return Option.of(List.unmodifiable(<String>[programPath]));
  }

  if (lowerCasePath.endsWith('.msi')) {
    return Option.of(List.unmodifiable(<String>['msiexec', '/i', programPath]));
  }

  if (lowerCasePath.endsWith('.bat') || lowerCasePath.endsWith('.cmd')) {
    return Option.of(List.unmodifiable(<String>['cmd', '/c', programPath]));
  }

  if (lowerCasePath.endsWith('.lnk')) {
    return Option.of(
      List.unmodifiable(<String>['start', '/unix', programPath]),
    );
  }

  return const Option.none();
}

List<String> programSettingsArguments(ProgramSettingsRecord settings) {
  final arguments = settings.arguments.value.trim();
  if (arguments.isEmpty) {
    return const <String>[];
  }

  return arguments.split(RegExp(r'\s+'));
}

List<String> wineArgumentsForBottleCommand(String command) {
  return switch (command) {
    'dxdiag' => const <String>[
      'cmd',
      '/c',
      'dxdiag /t C:\\konyak-dxdiag.txt && start "" notepad C:\\konyak-dxdiag.txt',
    ],
    _ => <String>[command],
  };
}

ProgramRunEnvironment programSettingsEnvironment(
  ProgramSettingsRecord settings,
) {
  final baseEnvironment = ProgramRunEnvironment(settings.environment.toMap());
  final localizedEnvironment = settings.locale.value.trim().isEmpty
      ? baseEnvironment
      : baseEnvironment.add('LC_ALL', settings.locale.value);
  final logging = programSettingsLogging(settings);
  final loggingChannels = logging.additionalWineLoggingChannels.value.trim();
  return loggingChannels.isEmpty
      ? localizedEnvironment
      : localizedEnvironment.add(
          'WINEDEBUG',
          _combinedWineDebugChannels(
            existingChannels: localizedEnvironment['WINEDEBUG'],
            additionalChannels: loggingChannels,
          ),
        );
}

ProgramLoggingSettingsRecord programSettingsLogging(
  ProgramSettingsRecord settings,
) {
  return settings.logging.getOrElse(ProgramLoggingSettingsRecord.new);
}

String programSettingsLogPath({
  required BottleRecord bottle,
  required ProgramSettingsRecord settings,
}) {
  final logFilePath = programSettingsLogging(settings).logFilePath.value.trim();
  if (logFilePath.isNotEmpty) {
    return logFilePath;
  }

  return domainJoinPath(bottle.path.value, const ['logs', 'latest.log']);
}

String _combinedWineDebugChannels({
  required Option<String> existingChannels,
  required String additionalChannels,
}) {
  final existing = existingChannels.match(() => '', (value) => value.trim());
  final additional = additionalChannels.trim();
  if (existing.isEmpty) {
    return additional;
  }
  if (additional.isEmpty) {
    return existing;
  }

  return '$existing,$additional';
}

bool isSupportedProgramPath(String programPath) {
  return wineArgumentsForProgramPath(programPath).isSome();
}

Option<String> supportedBottleCommand(String command) {
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
