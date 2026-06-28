import 'dart:async';

import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_graphics_backend_hints.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/runtime_catalogs.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/update/update_records.dart';
import '../io/gptk_wine_installation.dart';
import '../io/linux_external_program_launchers.dart';
import '../io/linux_wine_installation.dart';
import '../io/macos_wine_installation.dart';
import '../io/program_discovery.dart';
import '../io/program_graphics_backend_hints_io.dart';
import '../io/program_io_services.dart';
import '../io/program_metadata_io.dart';
import '../io/program_run_planner_io.dart';
import '../io/runtime_install_progress_io.dart';
import '../io/winetricks_io.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../platform/macos/macos_setup_checker.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../repository/memory_bottle_repository.dart';
import '../repository/repository_exceptions.dart';
import '../repository/repository_interfaces.dart';
import 'cli_app_process_parsers.dart';
import 'cli_app_process_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';
import 'cli_runtime_parsers.dart';
import 'cli_update_runtime_results.dart';

CliResult runCli(
  List<String> arguments, {
  BottleCatalog? bottleCatalog,
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(
        metadataExtractor: DartIoProgramMetadataExtractor(),
      ),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  RuntimeCatalog? runtimeCatalog,
  ProgramRunPlanner? programRunPlanner,
  ProgramGraphicsBackendHintsInspector programGraphicsBackendHintsInspector =
      const DartIoProgramGraphicsBackendHintsInspector(),
  ProgramRunner? programRunner,
  BottlePrefixInitializer? bottlePrefixInitializer,
  PathOpener? pathOpener,
  MacosWineInstaller? macosWineInstaller,
  LinuxWineInstaller? linuxWineInstaller,
  GptkWineInstaller? gptkWineInstaller,
  RuntimeUpdateChecker? runtimeUpdateChecker,
  AppUpdateChecker? appUpdateChecker,
  AppUpdateInstaller? appUpdateInstaller,
  RuntimeValidator? runtimeValidator,
  MacosSetupChecker? macosSetupChecker,
  AppSettingsRepository? appSettingsRepository,
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
  LinuxExternalProgramLauncherDiagnosticSink?
  linuxExternalProgramLauncherDiagnosticSink,
}) {
  try {
    return runCliWithContext(
      arguments,
      CliCommandContext(
        bottleCatalog: bottleCatalog ?? StaticBottleCatalog(const []),
        bottleRepository: bottleRepository,
        bottleProgramRepository: bottleProgramRepository,
        programMetadataExtractor: programMetadataExtractor,
        winetricksVerbRepository:
            winetricksVerbRepository ??
            DartIoWinetricksVerbRepository.current(),
        runtimeCatalog: runtimeCatalog ?? StaticRuntimeCatalog(const []),
        programRunPlanner: programRunPlanner ?? currentProgramRunPlanner(),
        programGraphicsBackendHintsInspector:
            programGraphicsBackendHintsInspector,
        programRunner: programRunner,
        bottlePrefixInitializer: bottlePrefixInitializer,
        pathOpener: pathOpener,
        macosWineInstaller: macosWineInstaller,
        linuxWineInstaller: linuxWineInstaller,
        gptkWineInstaller: gptkWineInstaller,
        runtimeUpdateChecker: runtimeUpdateChecker,
        appUpdateChecker: appUpdateChecker,
        appUpdateInstaller: appUpdateInstaller,
        runtimeValidator: runtimeValidator,
        macosSetupChecker: macosSetupChecker,
        appSettingsRepository: appSettingsRepository,
        runtimeInstallProgressSink: runtimeInstallProgressSink,
        linuxExternalProgramLauncherDiagnosticSink:
            linuxExternalProgramLauncherDiagnosticSink,
      ),
    );
  } on BottleRepositoryException catch (error) {
    return jsonError(
      exitCode: 74,
      code: 'bottleRepositoryError',
      message: error.message,
    );
  } on AppSettingsRepositoryException catch (error) {
    return jsonError(
      exitCode: 74,
      code: 'appSettingsRepositoryError',
      message: error.message,
    );
  }
}

Future<CliResult> runCliStreaming(
  List<String> arguments, {
  BottleCatalog? bottleCatalog,
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(
        metadataExtractor: DartIoProgramMetadataExtractor(),
      ),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  RuntimeCatalog? runtimeCatalog,
  ProgramRunPlanner? programRunPlanner,
  ProgramGraphicsBackendHintsInspector programGraphicsBackendHintsInspector =
      const DartIoProgramGraphicsBackendHintsInspector(),
  ProgramRunner? programRunner,
  BottlePrefixInitializer? bottlePrefixInitializer,
  PathOpener? pathOpener,
  MacosWineInstaller? macosWineInstaller,
  LinuxWineInstaller? linuxWineInstaller,
  GptkWineInstaller? gptkWineInstaller,
  RuntimeUpdateChecker? runtimeUpdateChecker,
  AppUpdateChecker? appUpdateChecker,
  AppUpdateInstaller? appUpdateInstaller,
  RuntimeValidator? runtimeValidator,
  MacosSetupChecker? macosSetupChecker,
  AppSettingsRepository? appSettingsRepository,
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
  LinuxExternalProgramLauncherDiagnosticSink?
  linuxExternalProgramLauncherDiagnosticSink,
  AsyncProgramRunner asyncProgramRunner = const DartIoAsyncProgramRunner(
    timeout: Duration(seconds: 4),
  ),
  AsyncProgramMetadataExtractor asyncProgramMetadataExtractor =
      const DartIoAsyncProgramMetadataExtractor(),
  HostProcessSnapshotReader hostProcessSnapshotReader =
      const DartIoHostProcessSnapshotReader(),
}) async {
  final macosWineInstallRequest = parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest?.emitProgress == true &&
      macosWineInstaller is DartIoMacosWineInstaller) {
    final installResult = await macosWineInstaller.installStreaming(
      macosWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return macosWineInstallCliResult(installResult);
  }

  final linuxWineInstallRequest = parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest?.emitProgress == true &&
      linuxWineInstaller is DartIoLinuxWineInstaller) {
    final installResult = await linuxWineInstaller.installStreaming(
      linuxWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return linuxWineInstallCliResult(installResult);
  }

  if (isJsonWineProcessListCommand(arguments)) {
    try {
      final activeBottleCatalog =
          bottleRepository ?? bottleCatalog ?? StaticBottleCatalog(const []);
      return await listWineProcessesJsonResultAsync(
        bottleCatalog: activeBottleCatalog,
        programRunPlanner: programRunPlanner ?? currentProgramRunPlanner(),
        programRunner: asyncProgramRunner,
        programMetadataExtractor: asyncProgramMetadataExtractor,
        hostProcessSnapshotReader: hostProcessSnapshotReader,
      );
    } on BottleRepositoryException catch (error) {
      return jsonError(
        exitCode: 74,
        code: 'bottleRepositoryError',
        message: error.message,
      );
    } on AppSettingsRepositoryException catch (error) {
      return jsonError(
        exitCode: 74,
        code: 'appSettingsRepositoryError',
        message: error.message,
      );
    }
  }

  return runCli(
    arguments,
    bottleCatalog: bottleCatalog,
    bottleRepository: bottleRepository,
    bottleProgramRepository: bottleProgramRepository,
    programMetadataExtractor: programMetadataExtractor,
    winetricksVerbRepository: winetricksVerbRepository,
    runtimeCatalog: runtimeCatalog,
    programRunPlanner: programRunPlanner,
    programGraphicsBackendHintsInspector: programGraphicsBackendHintsInspector,
    programRunner: programRunner,
    bottlePrefixInitializer: bottlePrefixInitializer,
    pathOpener: pathOpener,
    macosWineInstaller: macosWineInstaller,
    linuxWineInstaller: linuxWineInstaller,
    gptkWineInstaller: gptkWineInstaller,
    runtimeUpdateChecker: runtimeUpdateChecker,
    appUpdateChecker: appUpdateChecker,
    appUpdateInstaller: appUpdateInstaller,
    runtimeValidator: runtimeValidator,
    macosSetupChecker: macosSetupChecker,
    appSettingsRepository: appSettingsRepository,
    runtimeInstallProgressSink: runtimeInstallProgressSink,
    linuxExternalProgramLauncherDiagnosticSink:
        linuxExternalProgramLauncherDiagnosticSink,
  );
}
