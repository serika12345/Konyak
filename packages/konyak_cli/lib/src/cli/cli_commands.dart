part of '../../konyak_cli.dart';

class _CliCommandContext {
  const _CliCommandContext({
    required this.bottleCatalog,
    required this.bottleRepository,
    required this.bottleProgramRepository,
    required this.programMetadataExtractor,
    required this.winetricksVerbRepository,
    required this.runtimeCatalog,
    required this.programRunPlanner,
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
    required this.appSettingsRepository,
    required this.runtimeInstallProgressSink,
    required this.linuxExternalProgramLauncherDiagnosticSink,
  });

  final BottleCatalog bottleCatalog;
  final BottleRepository? bottleRepository;
  final BottleProgramRepository bottleProgramRepository;
  final ProgramMetadataExtractor programMetadataExtractor;
  final WinetricksVerbRepository winetricksVerbRepository;
  final RuntimeCatalog runtimeCatalog;
  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner? programRunner;
  final BottlePrefixInitializer? bottlePrefixInitializer;
  final PathOpener? pathOpener;
  final MacosWineInstaller? macosWineInstaller;
  final LinuxWineInstaller? linuxWineInstaller;
  final GptkWineInstaller? gptkWineInstaller;
  final RuntimeUpdateChecker? runtimeUpdateChecker;
  final AppUpdateChecker? appUpdateChecker;
  final AppUpdateInstaller? appUpdateInstaller;
  final RuntimeValidator? runtimeValidator;
  final MacosSetupChecker? macosSetupChecker;
  final AppSettingsRepository? appSettingsRepository;
  final RuntimeInstallProgressSink? runtimeInstallProgressSink;
  final LinuxExternalProgramLauncherDiagnosticSink?
  linuxExternalProgramLauncherDiagnosticSink;
}

CliResult runCli(
  List<String> arguments, {
  BottleCatalog? bottleCatalog,
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  RuntimeCatalog? runtimeCatalog,
  ProgramRunPlanner? programRunPlanner,
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
    return _runCli(
      arguments,
      _CliCommandContext(
        bottleCatalog: bottleCatalog ?? StaticBottleCatalog(const []),
        bottleRepository: bottleRepository,
        bottleProgramRepository: bottleProgramRepository,
        programMetadataExtractor: programMetadataExtractor,
        winetricksVerbRepository:
            winetricksVerbRepository ??
            DartIoWinetricksVerbRepository.current(),
        runtimeCatalog: runtimeCatalog ?? StaticRuntimeCatalog(const []),
        programRunPlanner: programRunPlanner ?? ProgramRunPlanner.current(),
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
    return _jsonError(
      exitCode: 74,
      code: 'bottleRepositoryError',
      message: error.message,
    );
  } on AppSettingsRepositoryException catch (error) {
    return _jsonError(
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
      const DartIoBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  RuntimeCatalog? runtimeCatalog,
  ProgramRunPlanner? programRunPlanner,
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
  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest?.emitProgress == true &&
      macosWineInstaller is DartIoMacosWineInstaller) {
    final installResult = await macosWineInstaller.installStreaming(
      macosWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return _macosWineInstallCliResult(installResult);
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest?.emitProgress == true &&
      linuxWineInstaller is DartIoLinuxWineInstaller) {
    final installResult = await linuxWineInstaller.installStreaming(
      linuxWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return _linuxWineInstallCliResult(installResult);
  }

  if (_isJsonWineProcessListCommand(arguments)) {
    try {
      final activeBottleCatalog =
          bottleRepository ?? bottleCatalog ?? StaticBottleCatalog(const []);
      return await _listWineProcessesJsonResultAsync(
        bottleCatalog: activeBottleCatalog,
        programRunPlanner: programRunPlanner ?? ProgramRunPlanner.current(),
        programRunner: asyncProgramRunner,
        programMetadataExtractor: asyncProgramMetadataExtractor,
        hostProcessSnapshotReader: hostProcessSnapshotReader,
      );
    } on BottleRepositoryException catch (error) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryError',
        message: error.message,
      );
    } on AppSettingsRepositoryException catch (error) {
      return _jsonError(
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

typedef _CliCommandHandler = CliResult? Function();

CliResult? _firstCliResult(Iterable<_CliCommandHandler> handlers) {
  for (final handler in handlers) {
    final result = handler();
    if (result != null) {
      return result;
    }
  }

  return null;
}

CliResult _runCli(List<String> arguments, _CliCommandContext context) {
  final bottleCatalog = context.bottleCatalog;
  final bottleRepository = context.bottleRepository;
  final activeBottleCatalog = bottleRepository ?? bottleCatalog;

  final commandResult = _firstCliResult(<_CliCommandHandler>[
    () => _handleAppCommand(arguments, context),
    () => _handleHostIntegrationCommand(arguments, context),
    () => _handleWineProcessCommand(
      arguments,
      context: context,
      activeBottleCatalog: activeBottleCatalog,
    ),
    () => _handleBottleReadCommand(
      arguments,
      context: context,
      activeBottleCatalog: activeBottleCatalog,
    ),
    () => _handleWinetricksVerbCommand(arguments, context),
    () => _handleBottleMutationCommand(arguments, context),
    () => _handleBottleConfigurationCommand(arguments, context),
    () => _handlePinnedProgramCommand(arguments, context),
    () => _handleProgramSettingsCommand(arguments, context),
    () => _handleProgramRunCommand(arguments, context),
    () => _handleLocationCommand(arguments, context),
    () => _handleRuntimeCommand(arguments, context),
  ]);
  if (commandResult != null) {
    return commandResult;
  }

  return const CliResult(
    exitCode: 64,
    stdout: '',
    stderr: '''
Usage:
  konyak check-app-update --json
  konyak install-app-update --json
  konyak get-app-settings --json
  konyak set-app-settings --settings-json <json> --json
  konyak install-linux-file-associations --json
  konyak list-wine-processes --json
  konyak terminate-wine-process --bottle <id> --process <pid> --json
  konyak terminate-wine-processes [--bottle <id>] --json
  konyak list-bottles --json
  konyak inspect-bottle <id> --json
  konyak list-bottle-programs <id> --json
  konyak list-winetricks-verbs --json
  konyak create-bottle --name <name> [--windows-version <version>] --json
  konyak export-bottle-archive <id> --archive <path> --json
  konyak import-bottle-archive --archive <path> --json
  konyak delete-bottle <id> --json
  konyak rename-bottle <id> --name <name> --json
  konyak move-bottle <id> --path <path> --json
  konyak set-windows-version <id> --windows-version <version> --json
  konyak set-runtime-settings <id> --settings-json <json> --json
  konyak pin-program <id> --name <name> --program <path> --json
  konyak unpin-program <id> --program <path> --json
  konyak rename-pinned-program <id> --program <path> --name <name> --json
  konyak get-program-settings <id> --program <path> --json
  konyak set-program-settings <id> --program <path> --settings-json <json> --json
  konyak launch-pinned-program --manifest <path> --json
  konyak run-program <id> --program <path> --json
  konyak run-winetricks <id> --verb <verb> --json
  konyak run-bottle-command <id> --command <winecfg|regedit|control|uninstaller|simulate-reboot|taskmgr|cmd|explorer|dxdiag|winver|terminal|winetricks> --json
  konyak open-bottle-location <id> --location <root|c-drive> --json
  konyak open-program-location <id> --program <path> --json
  konyak list-runtimes --json
  konyak check-macos-setup --json
  konyak install-gptk-wine --from <path> --json
  konyak open-url <https-url> --json
  konyak check-runtime-update <id> --json
  konyak install-runtime-update <id> --json
  konyak validate-runtime <id> --json
  konyak install-linux-wine [--reinstall] [--archive <path> | --archive-url <url>] [--archive-sha256 <sha256>] [--component-archive <path> ...] [--source-manifest <path-or-url>] --json
  konyak install-macos-wine [--reinstall] [--source-manifest <path-or-url> | --archive <path> [--archive-sha256 <sha256>] [--component-archive <path> ...] | --archive-url <url> [--component-archive <path> ...]] --json
''',
  );
}
