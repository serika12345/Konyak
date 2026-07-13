import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';
import 'program_settings_models.dart';

enum BottleCommandPlanKind {
  terminal,
  terminalWithInitialCommand,
  prefixRestart,
  winetricks,
  wineCommand,
}

typedef SupportedBottleCommand = ({
  BottleCommand command,
  BottleCommandPlanKind planKind,
});

Option<ProgramRunArguments> wineArgumentsForProgramPath(
  ProgramPath programPath,
) {
  final rawProgramPath = programPath.value;
  final lowerCasePath = rawProgramPath.toLowerCase();

  if (lowerCasePath.endsWith('.exe')) {
    return Option.of(ProgramRunArguments(<String>[programPath.value]));
  }

  if (lowerCasePath.endsWith('.msi')) {
    return Option.of(
      ProgramRunArguments(<String>['msiexec', '/i', rawProgramPath]),
    );
  }

  if (lowerCasePath.endsWith('.bat') || lowerCasePath.endsWith('.cmd')) {
    return Option.of(
      ProgramRunArguments(<String>['cmd', '/c', rawProgramPath]),
    );
  }

  if (lowerCasePath.endsWith('.lnk')) {
    return Option.of(
      ProgramRunArguments(<String>['start', '/unix', rawProgramPath]),
    );
  }

  return const Option.none();
}

Option<ProgramRunArguments> macosWineArgumentsForProgramPath(
  ProgramPath programPath, {
  Option<BottlePath> bottlePath = const Option.none(),
}) {
  final rawProgramPath = _macosWineLaunchPath(
    bottlePath: bottlePath,
    programPath: programPath,
  );
  final lowerCasePath = rawProgramPath.toLowerCase();

  if (lowerCasePath.endsWith('.exe')) {
    return Option.of(
      ProgramRunArguments(<String>[
        if (!_looksLikeWindowsPath(rawProgramPath)) ...['start', '/unix'],
        rawProgramPath,
      ]),
    );
  }

  return wineArgumentsForProgramPath(programPath);
}

Option<ProgramRunArguments> macosInstallerArgumentsForProgramPath(
  ProgramPath installerPath,
) {
  final path = installerPath.value;
  final lowerCasePath = path.toLowerCase();
  if (lowerCasePath.endsWith('.exe')) {
    return Option.of(
      ProgramRunArguments(<String>['start', '/wait', '/unix', path]),
    );
  }
  if (lowerCasePath.endsWith('.msi')) {
    return Option.of(ProgramRunArguments(<String>['msiexec', '/i', path]));
  }
  return const Option.none();
}

bool _looksLikeWindowsPath(String path) {
  return RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
}

String _macosWineLaunchPath({
  required Option<BottlePath> bottlePath,
  required ProgramPath programPath,
}) {
  final path = programPath.value;
  if (!path.toLowerCase().endsWith('.exe')) {
    return path;
  }

  return bottlePath.match(() => path, (bottlePath) {
    final driveCPrefix = '${bottlePath.value}/drive_c/';
    if (!path.startsWith(driveCPrefix)) {
      return path;
    }

    final relativePath = path.substring(driveCPrefix.length);
    return 'C:\\${relativePath.replaceAll('/', '\\')}';
  });
}

ProgramRunArguments programSettingsArguments(ProgramSettingsRecord settings) {
  final arguments = settings.arguments.value.trim();
  if (arguments.isEmpty) {
    return ProgramRunArguments(const <String>[]);
  }

  return ProgramRunArguments(arguments.split(RegExp(r'\s+')));
}

ProgramRunArguments wineArgumentsForBottleCommand(BottleCommand command) {
  return switch (command.value) {
    'dxdiag' => ProgramRunArguments(const <String>[
      'cmd',
      '/c',
      'dxdiag /t C:\\konyak-dxdiag.txt && start "" notepad C:\\konyak-dxdiag.txt',
    ]),
    _ => ProgramRunArguments(<String>[command.value]),
  };
}

ProgramRunEnvironment programSettingsEnvironment(
  ProgramSettingsRecord settings,
) {
  final baseEnvironment = settings.environment.toRunEnvironmentWhere(
    (name) => !isKonyakChildProcessRulesEnvironmentVariable(name.value),
  );
  final localizedEnvironment = settings.locale.value.trim().isEmpty
      ? baseEnvironment
      : baseEnvironment.add(
          ProgramEnvironmentVariableName('LC_ALL'),
          ProgramEnvironmentVariableValue(settings.locale.value),
        );
  final logging = programSettingsLogging(settings);
  final loggingChannels = logging.additionalWineLoggingChannels.value.trim();
  return loggingChannels.isEmpty
      ? localizedEnvironment
      : localizedEnvironment.add(
          ProgramEnvironmentVariableName('WINEDEBUG'),
          ProgramEnvironmentVariableValue(
            _combinedWineDebugChannels(
              existingChannels: localizedEnvironment['WINEDEBUG'],
              additionalChannels: loggingChannels,
            ),
          ),
        );
}

ProgramLoggingSettingsRecord programSettingsLogging(
  ProgramSettingsRecord settings,
) {
  return settings.logging.getOrElse(ProgramLoggingSettingsRecord.new);
}

ProgramLogPath programSettingsLogPath({
  required BottleRecord bottle,
  required ProgramSettingsRecord settings,
}) {
  final logFilePath = programSettingsLogging(settings).logFilePath.value.trim();
  if (logFilePath.isNotEmpty) {
    return ProgramLogPath(logFilePath);
  }

  return ProgramLogPath(
    domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
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

bool isSupportedProgramPath(ProgramPath programPath) {
  return wineArgumentsForProgramPath(programPath).isSome();
}

Option<SupportedBottleCommand> supportedBottleCommand(BottleCommand command) {
  final normalized = command.value.trim().toLowerCase();
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
    'winetricks' => _supportedBottleCommand(BottleCommand(normalized)),
    _ => const Option.none(),
  };
}

Option<SupportedBottleCommand> _supportedBottleCommand(BottleCommand command) {
  return Option.of((
    command: command,
    planKind: _bottleCommandPlanKind(command),
  ));
}

BottleCommandPlanKind _bottleCommandPlanKind(BottleCommand command) {
  return switch (command.value) {
    'terminal' => BottleCommandPlanKind.terminal,
    'cmd' => BottleCommandPlanKind.terminalWithInitialCommand,
    'simulate-reboot' => BottleCommandPlanKind.prefixRestart,
    'winetricks' => BottleCommandPlanKind.winetricks,
    _ => BottleCommandPlanKind.wineCommand,
  };
}
