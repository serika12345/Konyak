import 'dart:io';

import '../cli/cli_json_helpers.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../repository/repository_interfaces.dart';
import '../shared/common_helpers.dart';
import 'external_payload_helpers.dart';
import 'platform_host_paths.dart';
import 'program_winetricks_support.dart';

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
    final resolvedHostPlatform = hostPlatform ?? currentHostPlatform();
    final hostEnvironment = HostEnvironment(resolvedEnvironment);
    return DartIoWinetricksVerbRepository(
      runtimeRoot: switch (resolvedHostPlatform) {
        KonyakHostPlatform.macos => macosWineRuntimeRoot(hostEnvironment),
        KonyakHostPlatform.linux => linuxWineRuntimeRoot(hostEnvironment),
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
      final managedExecutable = joinPath(runtimeRoot, const ['winetricks']);
      if (!File(managedExecutable).existsSync()) {
        return WinetricksVerbListResult.failed(
          'Managed Winetricks executable is missing from runtime: '
          '$managedExecutable',
        );
      }

      return lister.listVerbs(executable: managedExecutable);
    }

    final verbsFile = File(joinPath(runtimeRoot, const ['verbs.txt']));
    if (verbsFile.existsSync()) {
      try {
        return WinetricksVerbListResult.completed(
          categories: parseWinetricksVerbs(verbsFile.readAsStringSync()),
        );
      } on FileSystemException catch (error) {
        return WinetricksVerbListResult.failed(error.message);
      }
    }

    return WinetricksVerbListResult.failed(
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
        return WinetricksVerbListResult.failed(
          commandFailureMessage('winetricks list-all', result),
        );
      }

      return WinetricksVerbListResult.completed(
        categories: parseWinetricksVerbs(processOutputToString(result.stdout)),
      );
    } on ProcessException catch (error) {
      return WinetricksVerbListResult.failed(
        programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    }
  }
}
