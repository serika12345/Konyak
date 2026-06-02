part of '../konyak_cli.dart';

class DartIoWinetricksVerbRepository implements WinetricksVerbRepository {
  const DartIoWinetricksVerbRepository({
    required this.runtimeRoot,
    this.hostPlatform = KonyakHostPlatform.macos,
    this.lister = const DartIoWinetricksVerbLister(),
    this.scriptInstaller = const DartIoWinetricksScriptInstaller(),
  });

  factory DartIoWinetricksVerbRepository.current({
    Map<String, String>? environment,
    KonyakHostPlatform? hostPlatform,
    WinetricksVerbLister lister = const DartIoWinetricksVerbLister(),
    WinetricksScriptInstaller scriptInstaller =
        const DartIoWinetricksScriptInstaller(),
  }) {
    final resolvedEnvironment = environment ?? Platform.environment;
    final resolvedHostPlatform = hostPlatform ?? _currentHostPlatform();
    return DartIoWinetricksVerbRepository(
      runtimeRoot: switch (resolvedHostPlatform) {
        KonyakHostPlatform.macos => _macosWineRuntimeRoot(resolvedEnvironment),
        KonyakHostPlatform.linux => _linuxWineRuntimeRoot(resolvedEnvironment),
      },
      hostPlatform: resolvedHostPlatform,
      lister: lister,
      scriptInstaller: scriptInstaller,
    );
  }

  final String runtimeRoot;
  final KonyakHostPlatform hostPlatform;
  final WinetricksVerbLister lister;
  final WinetricksScriptInstaller scriptInstaller;

  @override
  WinetricksVerbListResult listVerbs() {
    if (hostPlatform == KonyakHostPlatform.linux) {
      final managedExecutable = _joinPath(runtimeRoot, const ['winetricks']);
      return lister.listVerbs(
        executable: File(managedExecutable).existsSync()
            ? managedExecutable
            : 'winetricks',
      );
    }

    final verbsFile = File(_joinPath(runtimeRoot, const ['verbs.txt']));
    if (verbsFile.existsSync()) {
      try {
        return WinetricksVerbListCompleted(
          categories: parseWinetricksVerbs(verbsFile.readAsStringSync()),
        );
      } on FileSystemException catch (error) {
        return WinetricksVerbListFailed(error.message);
      }
    }

    final executable = _joinPath(runtimeRoot, const ['winetricks']);
    final installResult = scriptInstaller.installIfMissing(
      executable: executable,
    );
    switch (installResult) {
      case WinetricksScriptInstallCompleted():
        return lister.listVerbs(executable: executable);
      case WinetricksScriptInstallFailed(:final message):
        return WinetricksVerbListFailed(message);
    }
  }
}

class DartIoWinetricksScriptInstaller implements WinetricksScriptInstaller {
  const DartIoWinetricksScriptInstaller();

  @override
  WinetricksScriptInstallResult installIfMissing({required String executable}) {
    final target = File(executable);
    if (target.existsSync()) {
      return const WinetricksScriptInstallCompleted();
    }

    final temporaryPath = '$executable.download';
    final temporaryFile = File(temporaryPath);

    try {
      target.parent.createSync(recursive: true);
      final downloadResult = Process.runSync('curl', <String>[
        '--fail',
        '--location',
        '--silent',
        '--show-error',
        '--output',
        temporaryPath,
        winetricksScriptUrl,
      ], runInShell: false);

      if (downloadResult.exitCode != 0) {
        _deleteFileIfPresent(temporaryFile);
        return WinetricksScriptInstallFailed(
          _commandFailureMessage('download Winetricks', downloadResult),
        );
      }

      temporaryFile.renameSync(executable);

      final chmodResult = Process.runSync('chmod', <String>[
        '755',
        executable,
      ], runInShell: false);
      if (chmodResult.exitCode != 0) {
        return WinetricksScriptInstallFailed(
          _commandFailureMessage('mark Winetricks executable', chmodResult),
        );
      }

      return const WinetricksScriptInstallCompleted();
    } on ProcessException catch (error) {
      _deleteFileIfPresent(temporaryFile);
      return WinetricksScriptInstallFailed(
        _programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    } on FileSystemException catch (error) {
      _deleteFileIfPresent(temporaryFile);
      return WinetricksScriptInstallFailed(error.message);
    }
  }
}

void _deleteFileIfPresent(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup only; the original failure is more useful.
  }
}

class DartIoWinetricksVerbLister implements WinetricksVerbLister {
  const DartIoWinetricksVerbLister();

  @override
  WinetricksVerbListResult listVerbs({required String executable}) {
    try {
      final result = Process.runSync(
        executable,
        const <String>['list-all'],
        environment: const <String, String>{'LANG': 'C'},
        runInShell: false,
      );

      if (result.exitCode != 0) {
        return WinetricksVerbListFailed(
          _commandFailureMessage('winetricks list-all', result),
        );
      }

      return WinetricksVerbListCompleted(
        categories: parseWinetricksVerbs(_processOutputToString(result.stdout)),
      );
    } on ProcessException catch (error) {
      return WinetricksVerbListFailed(
        _programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    }
  }
}
