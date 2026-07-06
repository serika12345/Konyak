import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_graphics_backend_hints.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/runtime_catalogs.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/update/update_records.dart';
import '../io/gptk_wine_installation.dart';
import '../io/linux_external_program_launchers.dart';
import '../io/runtime_install_progress_io.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../platform/macos/macos_setup_checker.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../repository/repository_interfaces.dart';
import 'cli_app_handlers.dart';
import 'cli_app_runtime_handlers.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_read_handlers.dart';
import 'cli_host_integration_handlers.dart';
import 'cli_location_winetricks_handlers.dart';
import 'cli_pinned_program_handlers.dart';
import 'cli_program_run_handlers.dart';
import 'cli_result_model.dart';
import 'cli_wine_process_handlers.dart';

class CliCommandContext {
  const CliCommandContext({
    required this.bottleCatalog,
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
  final ProgramGraphicsBackendHintsInspector
  programGraphicsBackendHintsInspector;
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

sealed class CliCommandMatch {
  const CliCommandMatch();
}

final class CliCommandNotMatched extends CliCommandMatch {
  const CliCommandNotMatched();
}

final class CliCommandMatched extends CliCommandMatch {
  const CliCommandMatched(this.result);

  final CliResult result;
}

typedef CliCommandHandler = CliCommandMatch Function();

CliCommandMatch firstCliCommandMatch(Iterable<CliCommandHandler> handlers) {
  for (final handler in handlers) {
    final match = handler();
    switch (match) {
      case CliCommandMatched():
        return match;
      case CliCommandNotMatched():
    }
  }

  return const CliCommandNotMatched();
}

CliCommandMatch legacyCliCommandMatch(CliResult? result) {
  if (result == null) {
    return const CliCommandNotMatched();
  }

  return CliCommandMatched(result);
}

CliResult runCliWithContext(List<String> arguments, CliCommandContext context) {
  final bottleCatalog = context.bottleCatalog;
  final bottleRepository = context.bottleRepository;
  final activeBottleCatalog = bottleRepository ?? bottleCatalog;

  final commandMatch = firstCliCommandMatch(<CliCommandHandler>[
    () => legacyCliCommandMatch(handleAppCommand(arguments, context)),
    () =>
        legacyCliCommandMatch(handleHostIntegrationCommand(arguments, context)),
    () => legacyCliCommandMatch(
      handleWineProcessCommand(
        arguments,
        context: context,
        activeBottleCatalog: activeBottleCatalog,
      ),
    ),
    () => legacyCliCommandMatch(
      handleBottleReadCommand(
        arguments,
        context: context,
        activeBottleCatalog: activeBottleCatalog,
      ),
    ),
    () =>
        legacyCliCommandMatch(handleWinetricksVerbCommand(arguments, context)),
    () =>
        legacyCliCommandMatch(handleBottleMutationCommand(arguments, context)),
    () => legacyCliCommandMatch(
      handleBottleConfigurationCommand(arguments, context),
    ),
    () => legacyCliCommandMatch(handlePinnedProgramCommand(arguments, context)),
    () =>
        legacyCliCommandMatch(handleProgramSettingsCommand(arguments, context)),
    () => legacyCliCommandMatch(handleProgramRunCommand(arguments, context)),
    () => handleLocationCommand(arguments, context),
    () => handleRuntimeCommand(arguments, context),
  ]);
  switch (commandMatch) {
    case CliCommandMatched(:final result):
      return result;
    case CliCommandNotMatched():
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
  konyak suggest-graphics-backend --program <path> --json
  konyak launch-pinned-program --manifest <path> --json
  konyak run-program <id> --program <path> [--settings-json <json>] --json
  konyak run-winetricks <id> --verb <verb> --json
  konyak run-bottle-command <id> --command <winecfg|regedit|control|uninstaller|simulate-reboot|taskmgr|cmd|explorer|dxdiag|winver|terminal|winetricks> --json
  konyak open-bottle-location <id> --location <root|c-drive> --json
  konyak open-program-location <id> --program <path> --json
  konyak list-runtimes --json
  konyak check-macos-setup --json
  konyak install-gptk-wine --from <path> [--gptk-version <auto|3|4>] --json
  konyak open-url <https-url> --json
  konyak check-runtime-update <id> --json
  konyak install-runtime-update <id> --json
  konyak validate-runtime <id> --json
  konyak install-linux-wine [--reinstall] [--source-manifest <path-or-url>] --json
  konyak install-macos-wine [--reinstall] [--source-manifest <path-or-url>] --json
''',
  );
}
