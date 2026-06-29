import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../bottle/bottle_runtime_settings_models.dart';
import '../runtime/host_environment.dart';
import '../shared/domain_value_objects.dart';
import 'program_argument_support.dart';
import 'program_registry_plans.dart';
import 'program_run_models.dart';
import 'program_run_request_builders.dart';
import 'program_settings_models.dart';

abstract interface class ProgramRunner {
  ProgramRunResult run(ProgramRunRequest request);
}

abstract interface class AsyncProgramRunner {
  Future<ProgramRunResult> run(ProgramRunRequest request);
}

abstract interface class HostProcessSnapshotReader {
  Future<String> read();
}

abstract interface class PathOpener {
  PathOpenResult openPath(String path);

  PathOpenResult revealPath(String path);
}

enum KonyakHostPlatform { linux, macos }

class ProgramRunPlanner {
  ProgramRunPlanner({
    required this.hostPlatform,
    this.environment = const HostEnvironment.empty(),
    this.macosMajorVersion = const Option.none(),
  });

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
  final Option<int> macosMajorVersion;

  Option<ProgramRunRequest> plan({
    required BottleRecord bottle,
    required ProgramPath programPath,
    Option<ProgramSettingsRecord> programSettings = const Option.none(),
  }) {
    return wineArgumentsForProgramPath(programPath).map(
      (wineArguments) => switch (hostPlatform) {
        KonyakHostPlatform.linux => linuxWineRequest(
          bottle: bottle,
          programPath: programPath,
          wineArguments: wineArguments,
          environment: environment,
          programSettings: programSettings.getOrElse(ProgramSettingsRecord.new),
        ),
        KonyakHostPlatform.macos => macosWineRequest(
          bottle: bottle,
          programPath: programPath,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
          programSettings: programSettings.getOrElse(ProgramSettingsRecord.new),
        ),
      },
    );
  }

  Option<ProgramRunRequest> planBottleCommand({
    required BottleRecord bottle,
    required BottleCommand command,
  }) {
    return supportedBottleCommand(command).match(
      () => const Option.none(),
      (supportedCommand) => _planSupportedBottleCommand(
        bottle: bottle,
        supportedCommand: supportedCommand,
      ),
    );
  }

  Option<ProgramRunRequest> _planSupportedBottleCommand({
    required BottleRecord bottle,
    required BottleCommand supportedCommand,
  }) {
    if (supportedCommand.value == 'terminal') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => linuxTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
      });
    }

    if (supportedCommand.value == 'cmd') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => linuxTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
          initialWineCommand: Option.of(supportedCommand),
        ),
        KonyakHostPlatform.macos => macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
          initialWineCommand: Option.of(supportedCommand),
        ),
      });
    }

    if (supportedCommand.value == 'simulate-reboot') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => linuxWinebootRestartRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => macosWinebootRestartRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
      });
    }

    if (supportedCommand.value == 'winetricks') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => linuxWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => macosWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
          verb: const Option.none(),
        ),
      });
    }

    return Option.of(switch (hostPlatform) {
      KonyakHostPlatform.linux => linuxWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
      ),
      KonyakHostPlatform.macos => macosWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ),
    });
  }

  ProgramRunRequest planPrefixInitialization({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => linuxWinebootRequest(
        bottle: bottle,
        environment: environment,
      ),
      KonyakHostPlatform.macos => macosWinebootRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ),
    };
  }

  List<ProgramRunRequest> planPrefixBootstrap({required BottleRecord bottle}) {
    return List.unmodifiable(switch (hostPlatform) {
      KonyakHostPlatform.linux => <ProgramRunRequest>[
        linuxWinebootRequest(bottle: bottle, environment: environment),
      ],
      KonyakHostPlatform.macos => <ProgramRunRequest>[
        macosWineMonoInstallRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
        macosWinebootRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
      ],
    });
  }

  ProgramRunRequest planWineProcessTermination({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => linuxWineserverKillRequest(
        bottle: bottle,
        environment: environment,
      ),
      KonyakHostPlatform.macos => macosWineserverKillRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ),
    };
  }

  ProgramRunRequest planWineProcessList({required BottleRecord bottle}) {
    final winedbgCommand = winedbgProcessListPlan();
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => linuxWinedbgRequest(
        bottle: bottle,
        environment: environment,
        winedbgCommand: winedbgCommand,
      ),
      KonyakHostPlatform.macos => macosWinedbgRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
        winedbgCommand: winedbgCommand,
      ),
    };
  }

  ProgramRunRequest planWineProcessKill({
    required BottleRecord bottle,
    required WineProcessId processId,
  }) {
    final winedbgCommand = winedbgProcessKillPlan(processId);
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => linuxWinedbgRequest(
        bottle: bottle,
        environment: environment,
        winedbgCommand: winedbgCommand,
      ),
      KonyakHostPlatform.macos => macosWinedbgRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
        winedbgCommand: winedbgCommand,
      ),
    };
  }

  Option<ProgramRunRequest> planWinetricksVerb({
    required BottleRecord bottle,
    required WinetricksVerbId verb,
  }) {
    if (!isSupportedWinetricksVerb(verb)) {
      return const Option.none();
    }

    return Option.of(switch (hostPlatform) {
      KonyakHostPlatform.linux => linuxWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        verb: Option.of(verb),
      ),
      KonyakHostPlatform.macos => macosWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
        verb: Option.of(verb),
      ),
    });
  }

  List<ProgramRunRequest> planWindowsVersionRegistryUpdates({
    required BottleRecord bottle,
    required String windowsVersion,
  }) {
    final updates = windowsVersionRegistryUpdates(windowsVersion);

    return List.unmodifiable(
      updates.map((update) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => linuxRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
          KonyakHostPlatform.macos => macosRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
            macosMajorVersion: macosMajorVersion,
          ),
        };
      }),
    );
  }

  List<ProgramRunRequest> planRuntimeSettingsRegistryUpdates({
    required BottleRecord bottle,
    required BottleRuntimeSettings currentRuntimeSettings,
    required BottleRuntimeSettings runtimeSettings,
  }) {
    final updates = runtimeSettingsRegistryUpdates(
      currentRuntimeSettings: currentRuntimeSettings,
      runtimeSettings: runtimeSettings,
      includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos,
    );

    return List.unmodifiable(
      updates.map((update) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => linuxRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
          KonyakHostPlatform.macos => macosRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
            macosMajorVersion: macosMajorVersion,
          ),
        };
      }),
    );
  }

  List<ProgramRunRequest> planBottleSettingsRegistryQueries({
    required BottleRecord bottle,
  }) {
    final queries = bottleSettingsRegistryQueries(
      includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos,
    );

    return List.unmodifiable(
      queries.map((query) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => linuxRegistryQueryRequest(
            bottle: bottle,
            query: query,
            environment: environment,
          ),
          KonyakHostPlatform.macos => macosRegistryQueryRequest(
            bottle: bottle,
            query: query,
            environment: environment,
            macosMajorVersion: macosMajorVersion,
          ),
        };
      }),
    );
  }
}

Option<int> macosMajorVersionFromOperatingSystemVersion(String value) {
  return _firstDigitToken(value).flatMap(_integerFromDigits);
}

Option<String> _firstDigitToken(String value) {
  return _firstDigitIndex(value: value, index: 0).flatMap((start) {
    final token = value.substring(
      start,
      _firstNonDigitIndex(value: value, index: start),
    );
    return token.isEmpty ? const Option.none() : Option.of(token);
  });
}

Option<int> _firstDigitIndex({required String value, required int index}) {
  if (index >= value.length) {
    return const Option.none();
  }

  return _isAsciiDigit(value.codeUnitAt(index))
      ? Option.of(index)
      : _firstDigitIndex(value: value, index: index + 1);
}

int _firstNonDigitIndex({required String value, required int index}) {
  if (index >= value.length || !_isAsciiDigit(value.codeUnitAt(index))) {
    return index;
  }

  return _firstNonDigitIndex(value: value, index: index + 1);
}

bool _isAsciiDigit(int codeUnit) {
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}

Option<int> _integerFromDigits(String value) {
  try {
    return Option.of(int.parse(value));
  } on FormatException {
    return const Option.none();
  }
}
