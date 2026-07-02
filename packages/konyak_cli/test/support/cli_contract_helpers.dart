import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart' hide runCli, runCliStreaming;
import 'package:konyak_cli/src/cli/cli_commands.dart';
import 'package:konyak_cli/src/cli/cli_injected_runner.dart' as injected;
import 'package:konyak_cli/src/io/io_result.dart';
import 'package:konyak_cli/src/repository/memory_bottle_repository.dart';
import 'package:konyak_cli/src/repository/repository_interfaces.dart';
import 'package:test/test.dart';

CliResult runTestCli(
  List<String> arguments, {
  ProgramRunPlanner? programRunPlanner,
}) {
  return injected.runCli(
    arguments,
    context: testCliCommandContext(programRunPlanner: programRunPlanner),
  );
}

CliCommandContext testCliCommandContext({
  ProgramRunPlanner? programRunPlanner,
}) {
  return CliCommandContext(
    bottleCatalog: StaticBottleCatalog(const []),
    bottleRepository: null,
    bottleProgramRepository: const EmptyBottleProgramRepository(),
    programMetadataExtractor: const NoopProgramMetadataExtractor(),
    winetricksVerbRepository: const UnavailableWinetricksVerbRepository(),
    runtimeCatalog: StaticRuntimeCatalog(const []),
    programRunPlanner:
        programRunPlanner ??
        ProgramRunPlanner(hostPlatform: KonyakHostPlatform.macos),
    programGraphicsBackendHintsInspector:
        const UnavailableProgramGraphicsBackendHintsInspector(),
    programRunner: null,
    bottlePrefixInitializer: null,
    pathOpener: null,
    macosWineInstaller: null,
    linuxWineInstaller: null,
    gptkWineInstaller: null,
    runtimeUpdateChecker: null,
    appUpdateChecker: null,
    appUpdateInstaller: null,
    runtimeValidator: null,
    macosSetupChecker: null,
    appSettingsRepository: null,
    runtimeInstallProgressSink: null,
    linuxExternalProgramLauncherDiagnosticSink: null,
  );
}

String joinTestPath(String root, List<String> segments) {
  return <String>[root, ...segments].join('/');
}

T expectIo<T>(IoResult<T> result) {
  return result.fold((message) => throw TestFailure(message), (value) => value);
}

BottleRecord expectFound(IoResult<Option<BottleRecord>> result) {
  return expectIo(result).match(
    () => throw TestFailure('Expected bottle to exist.'),
    (bottle) => bottle,
  );
}

final class EmptyBottleProgramRepository implements BottleProgramRepository {
  const EmptyBottleProgramRepository();

  @override
  List<BottleProgramRecord> listPrograms(BottleRecord bottle) {
    return const <BottleProgramRecord>[];
  }
}

final class NoopProgramMetadataExtractor implements ProgramMetadataExtractor {
  const NoopProgramMetadataExtractor();

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  }) {
    return const Option.none();
  }
}

final class UnavailableWinetricksVerbRepository
    implements WinetricksVerbRepository {
  const UnavailableWinetricksVerbRepository();

  @override
  WinetricksVerbListResult listVerbs() {
    return WinetricksVerbListResult.failed(
      'Winetricks verb repository was not injected.',
    );
  }
}

final class UnavailableProgramGraphicsBackendHintsInspector
    implements ProgramGraphicsBackendHintsInspector {
  const UnavailableProgramGraphicsBackendHintsInspector();

  @override
  ProgramGraphicsBackendHintsInspectionResult inspect({
    required ProgramPath programPath,
    required KonyakHostPlatform hostPlatform,
  }) {
    return ProgramGraphicsBackendHintsInspectionResult.failed(
      programPath: programPath,
      message: 'Program graphics backend hints inspector was not injected.',
    );
  }
}
