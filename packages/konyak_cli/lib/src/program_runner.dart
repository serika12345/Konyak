part of '../konyak_cli.dart';

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
  }) : environment = Map.unmodifiable(environment);

  factory ProgramRunPlanner.current() {
    return ProgramRunPlanner(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;

  ProgramRunRequest? plan({
    required BottleRecord bottle,
    required String programPath,
    ProgramSettingsRecord programSettings = const ProgramSettingsRecord(),
  }) {
    final supportedProgramPath = _isSupportedProgramPath(programPath);
    if (!supportedProgramPath) {
      return null;
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment,
        programSettings: programSettings,
      ),
      KonyakHostPlatform.macos => _macosWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment,
        programSettings: programSettings,
      ),
    };
  }

  ProgramRunRequest? planBottleCommand({
    required BottleRecord bottle,
    required String command,
  }) {
    final supportedCommand = _supportedBottleCommand(command);
    if (supportedCommand == null) {
      return null;
    }

    if (supportedCommand == 'terminal') {
      return switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
      };
    }

    if (supportedCommand == 'winetricks') {
      return switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
          verb: null,
        ),
      };
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
      ),
    };
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
      ),
    };
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
        command: 'kill',
        logName: 'wine-process-kill.log',
        trailingArguments: <String>[attachProcessId],
      ),
    };
  }

  ProgramRunRequest? planWinetricksVerb({
    required BottleRecord bottle,
    required String verb,
  }) {
    if (!_isSupportedWinetricksVerb(verb)) {
      return null;
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        verb: verb,
      ),
      KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        verb: verb,
      ),
    };
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
          ),
        };
      }),
    );
  }
}

class ProgramRunRequest {
  ProgramRunRequest({
    required this.bottleId,
    required this.programPath,
    required this.runnerKind,
    required this.executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required this.logPath,
    this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments),
       environment = Map.unmodifiable(environment);

  final String bottleId;
  final String programPath;
  final String runnerKind;
  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String logPath;
  final String? workingDirectory;

  List<String> get argv {
    return List.unmodifiable(<String>[executable, ...arguments]);
  }
}

sealed class ProgramRunResult {
  const ProgramRunResult();
}

class ProgramRunCompleted extends ProgramRunResult {
  const ProgramRunCompleted({
    required this.processExitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int processExitCode;
  final String stdout;
  final String stderr;
}

class ProgramRunFailed extends ProgramRunResult {
  const ProgramRunFailed({required this.message});

  final String message;
}

class WineProcessTerminationRecord {
  const WineProcessTerminationRecord({
    required this.bottleId,
    required this.status,
    required this.runnerKind,
    required this.executable,
    required this.argv,
    this.processId,
    this.processExitCode,
    this.message,
  });

  final String bottleId;
  final String status;
  final String runnerKind;
  final String executable;
  final List<String> argv;
  final String? processId;
  final int? processExitCode;
  final String? message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bottleId': bottleId,
      if (processId != null) 'processId': processId,
      'status': status,
      'runnerKind': runnerKind,
      'executable': executable,
      'argv': argv,
      if (processExitCode != null) 'processExitCode': processExitCode,
      if (message != null) 'message': message,
    };
  }
}

sealed class PathOpenResult {
  const PathOpenResult();
}

class PathOpenCompleted extends PathOpenResult {
  const PathOpenCompleted();
}

class PathOpenFailed extends PathOpenResult {
  const PathOpenFailed(this.message);

  final String message;
}

sealed class DetachedProcessStartResult {
  const DetachedProcessStartResult();
}

class DetachedProcessStartCompleted extends DetachedProcessStartResult {
  const DetachedProcessStartCompleted();
}

class DetachedProcessStartFailed extends DetachedProcessStartResult {
  const DetachedProcessStartFailed(this.message);

  final String message;
}

abstract interface class DetachedProcessStarter {
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  });
}

class DartIoProgramRunner implements ProgramRunner {
  const DartIoProgramRunner();

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    try {
      final result = Process.runSync(
        request.executable,
        request.arguments,
        environment: request.environment,
        workingDirectory: request.workingDirectory,
        runInShell: false,
      );

      final logFile = File(request.logPath);
      logFile.parent.createSync(recursive: true);
      logFile.writeAsStringSync(_programRunLog(request, result));

      return ProgramRunCompleted(
        processExitCode: result.exitCode,
        stdout: _processOutputToString(result.stdout),
        stderr: _processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      final message = _programRunnerFailureMessage(
        executable: request.executable,
        message: error.message,
      );
      final logFile = File(request.logPath);
      logFile.parent.createSync(recursive: true);
      logFile.writeAsStringSync(_programRunStartupFailureLog(request, message));

      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    }
  }
}

class DartIoPathOpener implements PathOpener {
  const DartIoPathOpener();

  @override
  PathOpenResult openPath(String path) {
    return _runPathOpenCommand(<String>[path]);
  }

  @override
  PathOpenResult revealPath(String path) {
    return switch (_currentHostPlatform()) {
      KonyakHostPlatform.macos => _runPathOpenCommand(<String>['-R', path]),
      KonyakHostPlatform.linux => _runPathOpenCommand(<String>[
        _programLocationPath(path),
      ]),
    };
  }

  PathOpenResult _runPathOpenCommand(List<String> arguments) {
    try {
      final result = Process.runSync(
        _pathOpenExecutable(),
        arguments,
        runInShell: false,
      );
      if (result.exitCode != 0) {
        return PathOpenFailed(_processOutputToString(result.stderr));
      }

      return const PathOpenCompleted();
    } on ProcessException catch (error) {
      return PathOpenFailed(error.message);
    }
  }
}

class DartIoDetachedProcessStarter implements DetachedProcessStarter {
  const DartIoDetachedProcessStarter();

  @override
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  }) {
    try {
      final result = Process.runSync('bash', <String>[
        '-lc',
        r'nohup "$1" "${@:2}" >/dev/null 2>&1 &',
        '_',
        executable,
        ...arguments,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return DetachedProcessStartFailed(
          _processOutputToString(result.stderr),
        );
      }

      return const DetachedProcessStartCompleted();
    } on ProcessException catch (error) {
      return DetachedProcessStartFailed(error.message);
    }
  }
}
