import 'dart:async';
import 'dart:io';

import 'package:konyak_cli/konyak_cli.dart';

Future<void> main(List<String> arguments) async {
  final environment = Platform.environment;
  final runtimeCatalog = KonyakRuntimeCatalog.current();
  final programRunPlanner = ProgramRunPlanner.current();
  final appSettingsRepository = defaultAppSettingsRepositoryFromEnvironment(
    environment,
  );
  final appSettings = appSettingsRepository.read().fold<AppSettingsRecord?>(
    (_) => null,
    (settings) => settings,
  );
  const programRunner = DartIoProgramRunner();
  final result = await runCliStreaming(
    arguments,
    bottleRepository: defaultBottleRepositoryFromEnvironment(
      environment,
      appSettings: appSettings,
    ),
    appSettingsRepository: appSettingsRepository,
    runtimeCatalog: runtimeCatalog,
    programRunPlanner: programRunPlanner,
    programRunner: programRunner,
    bottlePrefixInitializer: DartIoBottlePrefixInitializer(
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    ),
    pathOpener: const DartIoPathOpener(),
    macosWineInstaller: DartIoMacosWineInstaller.current(),
    linuxWineInstaller: DartIoLinuxWineInstaller.current(),
    gptkWineInstaller: DartIoGptkWineInstaller.current(),
    runtimeUpdateChecker: DartIoRuntimeUpdateChecker(
      runtimeCatalog: runtimeCatalog,
    ),
    appUpdateChecker: DartIoAppUpdateChecker.fromEnvironment(
      HostEnvironment(environment),
    ),
    appUpdateInstaller: DartIoAppUpdateInstaller.fromEnvironment(environment),
    runtimeValidator: DartIoMacosWineRuntimeValidator(
      runtimeCatalog: runtimeCatalog,
    ),
    macosSetupChecker: DartIoMacosSetupChecker.current(runtimeCatalog),
    runtimeInstallProgressSink: JsonRuntimeInstallProgressSink(stdout),
  );

  if (result.stdout.isNotEmpty) {
    stdout.writeln(result.stdout);
  }

  if (result.stderr.isNotEmpty) {
    stderr.write(result.stderr);
  }

  exitCode = result.exitCode;
}
