part of '../../../konyak_cli.dart';

abstract interface class ProgramRunner {
  ProgramRunResult run(ProgramRunRequest request);
}

abstract interface class PathOpener {
  PathOpenResult openPath(String path);

  PathOpenResult revealPath(String path);
}

enum KonyakHostPlatform { linux, macos }

class ProgramRunPlanner {
  ProgramRunPlanner({
    required this.hostPlatform,
    Map<String, String> environment = const <String, String>{},
  }) : environment = HostEnvironment(environment);

  factory ProgramRunPlanner.current() {
    return ProgramRunPlanner(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;

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
        environment: environment.toMap(),
        programSettings: programSettings.getOrElse(ProgramSettingsRecord.new),
      ),
      KonyakHostPlatform.macos => _macosWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment.toMap(),
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
          environment: environment.toMap(),
        ),
        KonyakHostPlatform.macos => _macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment.toMap(),
        ),
      });
    }

    if (supportedCommand == 'winetricks') {
      return Option.of(switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
          bottle: bottle,
          environment: environment.toMap(),
        ),
        KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
          bottle: bottle,
          environment: environment.toMap(),
          verb: null,
        ),
      });
    }

    return Option.of(switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment.toMap(),
      ),
      KonyakHostPlatform.macos => _macosWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment.toMap(),
      ),
    });
  }

  ProgramRunRequest planPrefixInitialization({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinebootRequest(
        bottle: bottle,
        environment: environment.toMap(),
      ),
      KonyakHostPlatform.macos => _macosWinebootRequest(
        bottle: bottle,
        environment: environment.toMap(),
      ),
    };
  }

  ProgramRunRequest planWineProcessTermination({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineserverKillRequest(
        bottle: bottle,
        environment: environment.toMap(),
      ),
      KonyakHostPlatform.macos => _macosWineserverKillRequest(
        bottle: bottle,
        environment: environment.toMap(),
      ),
    };
  }

  ProgramRunRequest planWineProcessList({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinedbgRequest(
        bottle: bottle,
        environment: environment.toMap(),
        command: 'info proc',
        logName: 'wine-processes.log',
      ),
      KonyakHostPlatform.macos => _macosWinedbgRequest(
        bottle: bottle,
        environment: environment.toMap(),
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
        environment: environment.toMap(),
        command: 'kill',
        logName: 'wine-process-kill.log',
        trailingArguments: <String>[attachProcessId],
      ),
      KonyakHostPlatform.macos => _macosWinedbgRequest(
        bottle: bottle,
        environment: environment.toMap(),
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
        environment: environment.toMap(),
        verb: verb,
      ),
      KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
        bottle: bottle,
        environment: environment.toMap(),
        verb: verb,
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
            environment: environment.toMap(),
          ),
          KonyakHostPlatform.macos => _macosRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment.toMap(),
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
            environment: environment.toMap(),
          ),
          KonyakHostPlatform.macos => _macosRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment.toMap(),
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
            environment: environment.toMap(),
          ),
          KonyakHostPlatform.macos => _macosRegistryQueryRequest(
            bottle: bottle,
            query: query,
            environment: environment.toMap(),
          ),
        };
      }),
    );
  }
}
