part of '../../konyak_cli.dart';

class DartIoWinetricksVerbRepository implements WinetricksVerbRepository {
  const DartIoWinetricksVerbRepository({
    required this.runtimeRoot,
    this.hostPlatform = KonyakHostPlatform.macos,
    this.lister = const DartIoWinetricksVerbLister(),
  });

  factory DartIoWinetricksVerbRepository.current({
    Map<String, String>? environment,
    KonyakHostPlatform? hostPlatform,
    WinetricksVerbLister lister = const DartIoWinetricksVerbLister(),
  }) {
    final resolvedEnvironment = environment ?? Platform.environment;
    final resolvedHostPlatform = hostPlatform ?? _currentHostPlatform();
    final hostEnvironment = HostEnvironment(resolvedEnvironment);
    return DartIoWinetricksVerbRepository(
      runtimeRoot: switch (resolvedHostPlatform) {
        KonyakHostPlatform.macos => _macosWineRuntimeRoot(hostEnvironment),
        KonyakHostPlatform.linux => _linuxWineRuntimeRoot(hostEnvironment),
      },
      hostPlatform: resolvedHostPlatform,
      lister: lister,
    );
  }

  final String runtimeRoot;
  final KonyakHostPlatform hostPlatform;
  final WinetricksVerbLister lister;

  @override
  WinetricksVerbListResult listVerbs() {
    if (hostPlatform == KonyakHostPlatform.linux) {
      final managedExecutable = _joinPath(runtimeRoot, const ['winetricks']);
      if (!File(managedExecutable).existsSync()) {
        return WinetricksVerbListFailed(
          'Managed Winetricks executable is missing from runtime: '
          '$managedExecutable',
        );
      }

      return lister.listVerbs(executable: managedExecutable);
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

    return WinetricksVerbListFailed(
      'Managed Winetricks verb catalog is missing from runtime: '
      '${verbsFile.path}',
    );
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
