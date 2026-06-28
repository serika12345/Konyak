part of '../../../konyak_cli.dart';

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
    required String programPath,
    Option<ProgramSettingsRecord> programSettings = const Option.none(),
  }) {
    final supportedProgramPath = _isSupportedProgramPath(programPath);
    if (!supportedProgramPath) {
      return const Option.none();
    }

    return Option.of(switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment,
        programSettings: programSettings.getOrElse(ProgramSettingsRecord.new),
      ),
      KonyakHostPlatform.macos => _macosWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
        programSettings: programSettings.getOrElse(ProgramSettingsRecord.new),
      ),
    });
  }

  Option<ProgramRunRequest> planBottleCommand({
    required BottleRecord bottle,
    required String command,
  }) {
    return _supportedBottleCommand(command).match(
      () => const Option.none(),
      (supportedCommand) => _planSupportedBottleCommand(
        bottle: bottle,
        supportedCommand: supportedCommand,
      ),
    );
  }

  Option<ProgramRunRequest> _planSupportedBottleCommand({
    required BottleRecord bottle,
    required String supportedCommand,
  }) {
    if (supportedCommand == 'terminal') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
      });
    }

    if (supportedCommand == 'cmd') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
          initialWineCommand: Option.of(supportedCommand),
        ),
        KonyakHostPlatform.macos => _macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
          initialWineCommand: Option.of(supportedCommand),
        ),
      });
    }

    if (supportedCommand == 'simulate-reboot') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxWinebootRestartRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosWinebootRestartRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
      });
    }

    if (supportedCommand == 'winetricks') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
          verb: const Option.none(),
        ),
      });
    }

    return Option.of(switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ),
    });
  }

  ProgramRunRequest planPrefixInitialization({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinebootRequest(
        bottle: bottle,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWinebootRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ),
    };
  }

  List<ProgramRunRequest> planPrefixBootstrap({required BottleRecord bottle}) {
    return List.unmodifiable(switch (hostPlatform) {
      KonyakHostPlatform.linux => <ProgramRunRequest>[
        _linuxWinebootRequest(bottle: bottle, environment: environment),
      ],
      KonyakHostPlatform.macos => <ProgramRunRequest>[
        _macosWineMonoInstallRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
        _macosWinebootRequest(
          bottle: bottle,
          environment: environment,
          macosMajorVersion: macosMajorVersion,
        ),
      ],
    });
  }

  ProgramRunRequest planWineProcessTermination({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineserverKillRequest(
        bottle: bottle,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWineserverKillRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ),
    };
  }

  ProgramRunRequest planWineProcessList({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinedbgRequest(
        bottle: bottle,
        environment: environment,
        command: 'info proc',
        logName: 'wine-processes.log',
      ),
      KonyakHostPlatform.macos => _macosWinedbgRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
        command: 'info proc',
        logName: 'wine-processes.log',
      ),
    };
  }

  ProgramRunRequest planWineProcessKill({
    required BottleRecord bottle,
    required String processId,
  }) {
    final attachProcessId = _winedbgAttachProcessId(processId);
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinedbgRequest(
        bottle: bottle,
        environment: environment,
        command: 'kill',
        logName: 'wine-process-kill.log',
        trailingArguments: <String>[attachProcessId],
      ),
      KonyakHostPlatform.macos => _macosWinedbgRequest(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
        command: 'kill',
        logName: 'wine-process-kill.log',
        trailingArguments: <String>[attachProcessId],
      ),
    };
  }

  Option<ProgramRunRequest> planWinetricksVerb({
    required BottleRecord bottle,
    required String verb,
  }) {
    if (!_isSupportedWinetricksVerb(verb)) {
      return const Option.none();
    }

    return Option.of(switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        verb: Option.of(verb),
      ),
      KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
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
    final updates = _windowsVersionRegistryUpdates(windowsVersion);

    return List.unmodifiable(
      updates.map((update) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => _linuxRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
          KonyakHostPlatform.macos => _macosRegistryUpdateRequest(
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
    final updates = _runtimeSettingsRegistryUpdates(
      currentRuntimeSettings: currentRuntimeSettings,
      runtimeSettings: runtimeSettings,
      includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos,
    );

    return List.unmodifiable(
      updates.map((update) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => _linuxRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
          KonyakHostPlatform.macos => _macosRegistryUpdateRequest(
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
    final queries = _bottleSettingsRegistryQueries(
      includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos,
    );

    return List.unmodifiable(
      queries.map((query) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => _linuxRegistryQueryRequest(
            bottle: bottle,
            query: query,
            environment: environment,
          ),
          KonyakHostPlatform.macos => _macosRegistryQueryRequest(
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

Option<int> _macosMajorVersionFromOperatingSystemVersion(String value) {
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
