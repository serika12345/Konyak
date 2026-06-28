import 'dart:io';

import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_graphics_backend_hints.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/runtime_catalogs.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/update/update_records.dart';
import '../io/app_settings_repositories.dart';
import '../io/app_update_checker_io.dart';
import '../io/app_update_installer.dart';
import '../io/gptk_wine_installation.dart';
import '../io/linux_external_program_launchers.dart';
import '../io/linux_wine_installation.dart';
import '../io/macos_wine_installation.dart';
import '../io/program_discovery.dart';
import '../io/program_graphics_backend_hints_io.dart';
import '../io/program_io_services.dart';
import '../io/program_metadata_io.dart';
import '../io/program_run_planner_io.dart';
import '../io/runtime_catalog_factories_io.dart';
import '../io/runtime_install_progress_io.dart';
import '../io/runtime_update_checker_io.dart';
import '../io/winetricks_io.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../platform/macos/macos_runtime_validator.dart';
import '../platform/macos/macos_setup_checker.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../repository/repository_interfaces.dart';
import 'cli_commands.dart';
import 'cli_injected_runner.dart' as injected;
import 'cli_result_model.dart';

CliResult runCliWithDefaultIo(List<String> arguments) {
  final dependencies = defaultCliDependencies();
  return injected.runCli(
    arguments,
    context: defaultCliCommandContext(dependencies),
  );
}

Future<CliResult> runCliStreamingWithDefaultIo(
  List<String> arguments, {
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) async {
  final dependencies = defaultCliDependencies();
  return injected.runCliStreaming(
    arguments,
    context: defaultCliCommandContext(
      dependencies,
      runtimeInstallProgressSink: runtimeInstallProgressSink,
    ),
    asyncProgramRunner: dependencies.asyncProgramRunner,
    asyncProgramMetadataExtractor: dependencies.asyncProgramMetadataExtractor,
    hostProcessSnapshotReader: dependencies.hostProcessSnapshotReader,
    macosWineStreamingInstaller: dependencies.macosWineInstaller,
    linuxWineStreamingInstaller: dependencies.linuxWineInstaller,
  );
}

CliCommandContext defaultCliCommandContext(
  DefaultCliDependencies dependencies, {
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) {
  return CliCommandContext(
    bottleCatalog: dependencies.bottleRepository,
    bottleRepository: dependencies.bottleRepository,
    bottleProgramRepository: dependencies.bottleProgramRepository,
    programMetadataExtractor: dependencies.programMetadataExtractor,
    winetricksVerbRepository: dependencies.winetricksVerbRepository,
    runtimeCatalog: dependencies.runtimeCatalog,
    programRunPlanner: dependencies.programRunPlanner,
    programGraphicsBackendHintsInspector:
        dependencies.programGraphicsBackendHintsInspector,
    programRunner: dependencies.programRunner,
    bottlePrefixInitializer: dependencies.bottlePrefixInitializer,
    pathOpener: dependencies.pathOpener,
    macosWineInstaller: dependencies.macosWineInstaller,
    linuxWineInstaller: dependencies.linuxWineInstaller,
    gptkWineInstaller: dependencies.gptkWineInstaller,
    runtimeUpdateChecker: dependencies.runtimeUpdateChecker,
    appUpdateChecker: dependencies.appUpdateChecker,
    appUpdateInstaller: dependencies.appUpdateInstaller,
    runtimeValidator: dependencies.runtimeValidator,
    macosSetupChecker: dependencies.macosSetupChecker,
    appSettingsRepository: dependencies.appSettingsRepository,
    runtimeInstallProgressSink: runtimeInstallProgressSink,
    linuxExternalProgramLauncherDiagnosticSink:
        dependencies.linuxExternalProgramLauncherDiagnosticSink,
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
  const programMetadataExtractor = DartIoProgramMetadataExtractor();
  const programRunner = DartIoProgramRunner();
  final macosWineInstaller = DartIoMacosWineInstaller.current();
  final linuxWineInstaller = DartIoLinuxWineInstaller.current();
  final hostEnvironment = HostEnvironment(environment);

  return DefaultCliDependencies(
    appSettingsRepository: appSettingsRepository,
    bottleRepository: bottleRepository,
    bottleProgramRepository: const DartIoBottleProgramRepository(
      metadataExtractor: programMetadataExtractor,
    ),
    programMetadataExtractor: programMetadataExtractor,
    winetricksVerbRepository: DartIoWinetricksVerbRepository.current(),
    runtimeCatalog: runtimeCatalog,
    programRunPlanner: programRunPlanner,
    programGraphicsBackendHintsInspector:
        const DartIoProgramGraphicsBackendHintsInspector(),
    programRunner: programRunner,
    bottlePrefixInitializer: DartIoBottlePrefixInitializer(
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    ),
    pathOpener: const DartIoPathOpener(),
    macosWineInstaller: macosWineInstaller,
    linuxWineInstaller: linuxWineInstaller,
    gptkWineInstaller: DartIoGptkWineInstaller.current(),
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
    asyncProgramRunner: const DartIoAsyncProgramRunner(
      timeout: Duration(seconds: 4),
    ),
    asyncProgramMetadataExtractor: const DartIoAsyncProgramMetadataExtractor(),
    hostProcessSnapshotReader: const DartIoHostProcessSnapshotReader(),
  );
}

final class DefaultCliDependencies {
  const DefaultCliDependencies({
    required this.appSettingsRepository,
    required this.bottleRepository,
    required this.bottleProgramRepository,
    required this.programMetadataExtractor,
    required this.winetricksVerbRepository,
    required this.runtimeCatalog,
    required this.programRunPlanner,
    required this.programGraphicsBackendHintsInspector,
    required this.programRunner,
    required this.bottlePrefixInitializer,
    required this.pathOpener,
    required this.macosWineInstaller,
    required this.linuxWineInstaller,
    required this.gptkWineInstaller,
    required this.runtimeUpdateChecker,
    required this.appUpdateChecker,
    required this.appUpdateInstaller,
    required this.runtimeValidator,
    required this.macosSetupChecker,
    required this.asyncProgramRunner,
    required this.asyncProgramMetadataExtractor,
    required this.hostProcessSnapshotReader,
    this.linuxExternalProgramLauncherDiagnosticSink,
  });

  final AppSettingsRepository appSettingsRepository;
  final BottleRepository bottleRepository;
  final BottleProgramRepository bottleProgramRepository;
  final ProgramMetadataExtractor programMetadataExtractor;
  final WinetricksVerbRepository winetricksVerbRepository;
  final RuntimeCatalog runtimeCatalog;
  final ProgramRunPlanner programRunPlanner;
  final ProgramGraphicsBackendHintsInspector
  programGraphicsBackendHintsInspector;
  final ProgramRunner programRunner;
  final BottlePrefixInitializer bottlePrefixInitializer;
  final PathOpener pathOpener;
  final MacosWineStreamingInstaller macosWineInstaller;
  final LinuxWineStreamingInstaller linuxWineInstaller;
  final GptkWineInstaller gptkWineInstaller;
  final RuntimeUpdateChecker runtimeUpdateChecker;
  final AppUpdateChecker appUpdateChecker;
  final AppUpdateInstaller appUpdateInstaller;
  final RuntimeValidator runtimeValidator;
  final MacosSetupChecker macosSetupChecker;
  final AsyncProgramRunner asyncProgramRunner;
  final AsyncProgramMetadataExtractor asyncProgramMetadataExtractor;
  final HostProcessSnapshotReader hostProcessSnapshotReader;
  final LinuxExternalProgramLauncherDiagnosticSink?
  linuxExternalProgramLauncherDiagnosticSink;
}
