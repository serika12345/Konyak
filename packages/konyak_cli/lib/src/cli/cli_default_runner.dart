import 'dart:io';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/update/update_records.dart';
import '../io/app_settings_repositories.dart';
import '../io/app_update_checker_io.dart';
import '../io/app_update_installer.dart';
import '../io/gptk_wine_installation.dart';
import '../io/linux_wine_installation.dart';
import '../io/macos_wine_installation.dart';
import '../io/program_discovery.dart';
import '../io/program_graphics_backend_hints_io.dart';
import '../io/program_io_services.dart';
import '../io/program_run_planner_io.dart';
import '../io/runtime_catalog_factories_io.dart';
import '../io/runtime_install_progress_io.dart';
import '../io/runtime_update_checker_io.dart';
import '../platform/macos/macos_runtime_validator.dart';
import '../platform/macos/macos_setup_checker.dart';
import '../repository/repository_interfaces.dart';
import 'cli_injected_runner.dart' as injected;
import 'cli_result_model.dart';

CliResult runCliWithDefaultIo(List<String> arguments) {
  final dependencies = defaultCliDependencies();
  return injected.runCli(
    arguments,
    bottleRepository: dependencies.bottleRepository,
    appSettingsRepository: dependencies.appSettingsRepository,
    runtimeCatalog: dependencies.runtimeCatalog,
    programRunPlanner: dependencies.programRunPlanner,
    programGraphicsBackendHintsInspector:
        const DartIoProgramGraphicsBackendHintsInspector(),
    programRunner: dependencies.programRunner,
    bottlePrefixInitializer: dependencies.bottlePrefixInitializer,
    pathOpener: const DartIoPathOpener(),
    macosWineInstaller: DartIoMacosWineInstaller.current(),
    linuxWineInstaller: DartIoLinuxWineInstaller.current(),
    gptkWineInstaller: DartIoGptkWineInstaller.current(),
    runtimeUpdateChecker: dependencies.runtimeUpdateChecker,
    appUpdateChecker: dependencies.appUpdateChecker,
    appUpdateInstaller: dependencies.appUpdateInstaller,
    runtimeValidator: dependencies.runtimeValidator,
    macosSetupChecker: dependencies.macosSetupChecker,
  );
}

Future<CliResult> runCliStreamingWithDefaultIo(
  List<String> arguments, {
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) async {
  final dependencies = defaultCliDependencies();
  return injected.runCliStreaming(
    arguments,
    bottleRepository: dependencies.bottleRepository,
    appSettingsRepository: dependencies.appSettingsRepository,
    runtimeCatalog: dependencies.runtimeCatalog,
    programRunPlanner: dependencies.programRunPlanner,
    programGraphicsBackendHintsInspector:
        const DartIoProgramGraphicsBackendHintsInspector(),
    programRunner: dependencies.programRunner,
    bottlePrefixInitializer: dependencies.bottlePrefixInitializer,
    pathOpener: const DartIoPathOpener(),
    macosWineInstaller: DartIoMacosWineInstaller.current(),
    linuxWineInstaller: DartIoLinuxWineInstaller.current(),
    gptkWineInstaller: DartIoGptkWineInstaller.current(),
    runtimeUpdateChecker: dependencies.runtimeUpdateChecker,
    appUpdateChecker: dependencies.appUpdateChecker,
    appUpdateInstaller: dependencies.appUpdateInstaller,
    runtimeValidator: dependencies.runtimeValidator,
    macosSetupChecker: dependencies.macosSetupChecker,
    runtimeInstallProgressSink: runtimeInstallProgressSink,
  );
}

DefaultCliDependencies defaultCliDependencies() {
  final environment = Platform.environment;
  final runtimeCatalog = currentKonyakRuntimeCatalog();
  final programRunPlanner = currentProgramRunPlanner();
  final appSettingsRepository = defaultAppSettingsRepositoryFromEnvironment(
    environment,
  );
  final bottleRepository = appSettingsRepository.read().match(
    (_) => defaultBottleRepositoryFromEnvironment(environment),
    (appSettings) => defaultBottleRepositoryFromEnvironment(
      environment,
      appSettings: appSettings,
    ),
  );
  const programRunner = DartIoProgramRunner();
  final hostEnvironment = HostEnvironment(environment);

  return DefaultCliDependencies(
    appSettingsRepository: appSettingsRepository,
    bottleRepository: bottleRepository,
    runtimeCatalog: runtimeCatalog,
    programRunPlanner: programRunPlanner,
    programRunner: programRunner,
    bottlePrefixInitializer: DartIoBottlePrefixInitializer(
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    ),
    runtimeUpdateChecker: DartIoRuntimeUpdateChecker(
      runtimeCatalog: runtimeCatalog,
    ),
    appUpdateChecker: DartIoAppUpdateChecker.fromEnvironment(hostEnvironment),
    appUpdateInstaller: DartIoAppUpdateInstaller.fromEnvironment(environment),
    runtimeValidator: DartIoMacosWineRuntimeValidator(
      runtimeCatalog: runtimeCatalog,
      environment: hostEnvironment,
    ),
    macosSetupChecker: DartIoMacosSetupChecker.current(runtimeCatalog),
  );
}

final class DefaultCliDependencies {
  const DefaultCliDependencies({
    required this.appSettingsRepository,
    required this.bottleRepository,
    required this.runtimeCatalog,
    required this.programRunPlanner,
    required this.programRunner,
    required this.bottlePrefixInitializer,
    required this.runtimeUpdateChecker,
    required this.appUpdateChecker,
    required this.appUpdateInstaller,
    required this.runtimeValidator,
    required this.macosSetupChecker,
  });

  final AppSettingsRepository appSettingsRepository;
  final BottleRepository bottleRepository;
  final KonyakRuntimeCatalog runtimeCatalog;
  final ProgramRunPlanner programRunPlanner;
  final DartIoProgramRunner programRunner;
  final DartIoBottlePrefixInitializer bottlePrefixInitializer;
  final DartIoRuntimeUpdateChecker runtimeUpdateChecker;
  final DartIoAppUpdateChecker appUpdateChecker;
  final AppUpdateInstaller appUpdateInstaller;
  final DartIoMacosWineRuntimeValidator runtimeValidator;
  final DartIoMacosSetupChecker macosSetupChecker;
}
