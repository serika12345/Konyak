import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart' hide runCli, runCliStreaming;
import 'package:konyak_cli/src/cli/cli_commands.dart';
import 'package:konyak_cli/src/cli/cli_injected_runner.dart' as injected;
import 'package:konyak_cli/src/io/bottle_metadata_json.dart';
import 'package:konyak_cli/src/io/gptk_wine_installation.dart';
import 'package:konyak_cli/src/io/io_result.dart';
import 'package:konyak_cli/src/io/linux_external_program_launchers.dart';
import 'package:konyak_cli/src/io/runtime_install_progress_io.dart';
import 'package:konyak_cli/src/platform/linux/linux_wine_install_requests.dart';
import 'package:konyak_cli/src/platform/linux/linux_wine_install_results.dart';
import 'package:konyak_cli/src/platform/macos/macos_setup_checker.dart';
import 'package:konyak_cli/src/platform/macos/macos_wine_install_requests.dart';
import 'package:konyak_cli/src/platform/macos/macos_wine_install_results.dart';
import 'package:konyak_cli/src/repository/memory_bottle_repository.dart';
import 'package:konyak_cli/src/repository/repository_interfaces.dart';
import 'package:konyak_cli/src/shared/model_constants.dart';
import 'package:test/test.dart';

export 'dart:async';
export 'dart:convert';
export 'dart:io';
export 'dart:math';
export 'dart:typed_data';

export 'package:crypto/crypto.dart';
export 'package:fpdart/fpdart.dart' hide Hash;
export 'package:konyak_cli/konyak_cli.dart' hide runCli, runCliStreaming;
export 'package:konyak_cli/src/cli/cli_commands.dart';
export 'package:konyak_cli/src/cli/cli_runtime_record_json.dart';
export 'package:konyak_cli/src/io/app_settings_repositories.dart';
export 'package:konyak_cli/src/io/app_update_checker_io.dart';
export 'package:konyak_cli/src/io/app_update_installer.dart';
export 'package:konyak_cli/src/io/bottle_metadata_json.dart';
export 'package:konyak_cli/src/io/gptk_wine_installation.dart';
export 'package:konyak_cli/src/io/io_result.dart';
export 'package:konyak_cli/src/io/linux_external_program_launchers.dart';
export 'package:konyak_cli/src/io/linux_wine_installation.dart';
export 'package:konyak_cli/src/io/macos_wine_installation.dart';
export 'package:konyak_cli/src/io/program_discovery.dart';
export 'package:konyak_cli/src/io/program_graphics_backend_hints_io.dart';
export 'package:konyak_cli/src/io/program_metadata_io.dart';
export 'package:konyak_cli/src/io/program_winetricks_support.dart';
export 'package:konyak_cli/src/io/release_metadata_fetcher.dart';
export 'package:konyak_cli/src/io/runtime_catalog_factories_io.dart';
export 'package:konyak_cli/src/io/runtime_install_progress_io.dart';
export 'package:konyak_cli/src/io/runtime_package_installer_io.dart';
export 'package:konyak_cli/src/io/runtime_probes.dart';
export 'package:konyak_cli/src/io/runtime_update_checker_io.dart';
export 'package:konyak_cli/src/io/winetricks_io.dart';
export 'package:konyak_cli/src/platform/linux/linux_wine_install_requests.dart';
export 'package:konyak_cli/src/platform/linux/linux_wine_install_results.dart';
export 'package:konyak_cli/src/platform/macos/macos_runtime_validator.dart';
export 'package:konyak_cli/src/platform/macos/macos_setup_checker.dart';
export 'package:konyak_cli/src/platform/macos/macos_wine_install_requests.dart';
export 'package:konyak_cli/src/platform/macos/macos_wine_install_results.dart';
export 'package:konyak_cli/src/repository/file_bottle_repository.dart';
export 'package:konyak_cli/src/repository/memory_bottle_repository.dart';
export 'package:konyak_cli/src/repository/repository_interfaces.dart';
export 'package:konyak_cli/src/shared/model_constants.dart';
export 'package:test/test.dart';

const gptkD3DMetalWindowsFileNames = <String>[
  'atidxx64.dll',
  'd3d11.dll',
  'd3d12.dll',
  'dxgi.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

const gptkD3DMetalUnixFileNames = <String>[
  'atidxx64.so',
  'd3d11.so',
  'd3d12.so',
  'dxgi.so',
  'nvapi64.so',
  'nvngx.so',
];

const gptkD3DMetalOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d11.dll',
  'd3d12.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

final gptkD3DMetalComponentArchivePaths = <List<String>>[
  <String>[
    'Components',
    'GPTK-D3DMetal',
    'lib',
    'external',
    'D3DMetal.framework',
    'D3DMetal',
  ],
  <String>[
    'Components',
    'GPTK-D3DMetal',
    'lib',
    'external',
    'libd3dshared.dylib',
  ],
  for (final fileName in gptkD3DMetalWindowsFileNames)
    <String>[
      'Components',
      'GPTK-D3DMetal',
      'lib',
      'wine',
      'x86_64-windows',
      fileName,
    ],
  for (final fileName in gptkD3DMetalUnixFileNames)
    <String>[
      'Components',
      'GPTK-D3DMetal',
      'lib',
      'wine',
      'x86_64-unix',
      fileName,
    ],
];

final gptkD3DMetalInstalledPaths = <List<String>>[
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'external',
    'D3DMetal.framework',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'external',
    'libd3dshared.dylib',
  ],
  for (final fileName in gptkD3DMetalWindowsFileNames)
    <String>[
      'components',
      'gptk-d3dmetal',
      'lib',
      'wine',
      'x86_64-windows',
      fileName,
    ],
  for (final fileName in gptkD3DMetalUnixFileNames)
    <String>[
      'components',
      'gptk-d3dmetal',
      'lib',
      'wine',
      'x86_64-unix',
      fileName,
    ],
];

CliResult runCli(
  List<String> arguments, {
  BottleCatalog? bottleCatalog,
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const EmptyBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const NoopProgramMetadataExtractor(),
  WinetricksVerbRepository winetricksVerbRepository =
      const UnavailableWinetricksVerbRepository(),
  RuntimeCatalog? runtimeCatalog,
  ProgramRunPlanner? programRunPlanner,
  ProgramGraphicsBackendHintsInspector programGraphicsBackendHintsInspector =
      const UnavailableProgramGraphicsBackendHintsInspector(),
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
  return injected.runCli(
    arguments,
    context: _testCliCommandContext(
      bottleCatalog: bottleCatalog,
      bottleRepository: bottleRepository,
      bottleProgramRepository: bottleProgramRepository,
      programMetadataExtractor: programMetadataExtractor,
      winetricksVerbRepository: winetricksVerbRepository,
      runtimeCatalog: runtimeCatalog,
      programRunPlanner: programRunPlanner,
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
}

Future<CliResult> runCliStreaming(
  List<String> arguments, {
  BottleCatalog? bottleCatalog,
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const EmptyBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const NoopProgramMetadataExtractor(),
  WinetricksVerbRepository winetricksVerbRepository =
      const UnavailableWinetricksVerbRepository(),
  RuntimeCatalog? runtimeCatalog,
  ProgramRunPlanner? programRunPlanner,
  ProgramGraphicsBackendHintsInspector programGraphicsBackendHintsInspector =
      const UnavailableProgramGraphicsBackendHintsInspector(),
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
  AsyncProgramRunner asyncProgramRunner = const UnavailableAsyncProgramRunner(),
  AsyncProgramMetadataExtractor asyncProgramMetadataExtractor =
      const NoopAsyncProgramMetadataExtractor(),
  HostProcessSnapshotReader hostProcessSnapshotReader =
      const EmptyHostProcessSnapshotReader(),
}) {
  return injected.runCliStreaming(
    arguments,
    context: _testCliCommandContext(
      bottleCatalog: bottleCatalog,
      bottleRepository: bottleRepository,
      bottleProgramRepository: bottleProgramRepository,
      programMetadataExtractor: programMetadataExtractor,
      winetricksVerbRepository: winetricksVerbRepository,
      runtimeCatalog: runtimeCatalog,
      programRunPlanner: programRunPlanner,
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
    asyncProgramRunner: asyncProgramRunner,
    asyncProgramMetadataExtractor: asyncProgramMetadataExtractor,
    hostProcessSnapshotReader: hostProcessSnapshotReader,
  );
}

CliCommandContext _testCliCommandContext({
  required BottleCatalog? bottleCatalog,
  required BottleRepository? bottleRepository,
  required BottleProgramRepository bottleProgramRepository,
  required ProgramMetadataExtractor programMetadataExtractor,
  required WinetricksVerbRepository winetricksVerbRepository,
  required RuntimeCatalog? runtimeCatalog,
  required ProgramRunPlanner? programRunPlanner,
  required ProgramGraphicsBackendHintsInspector
  programGraphicsBackendHintsInspector,
  required ProgramRunner? programRunner,
  required BottlePrefixInitializer? bottlePrefixInitializer,
  required PathOpener? pathOpener,
  required MacosWineInstaller? macosWineInstaller,
  required LinuxWineInstaller? linuxWineInstaller,
  required GptkWineInstaller? gptkWineInstaller,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
  required AppUpdateChecker? appUpdateChecker,
  required AppUpdateInstaller? appUpdateInstaller,
  required RuntimeValidator? runtimeValidator,
  required MacosSetupChecker? macosSetupChecker,
  required AppSettingsRepository? appSettingsRepository,
  required RuntimeInstallProgressSink? runtimeInstallProgressSink,
  required LinuxExternalProgramLauncherDiagnosticSink?
  linuxExternalProgramLauncherDiagnosticSink,
}) {
  return CliCommandContext(
    bottleCatalog:
        bottleCatalog ?? bottleRepository ?? StaticBottleCatalog(const []),
    bottleRepository: bottleRepository,
    bottleProgramRepository: bottleProgramRepository,
    programMetadataExtractor: programMetadataExtractor,
    winetricksVerbRepository: winetricksVerbRepository,
    runtimeCatalog: runtimeCatalog ?? StaticRuntimeCatalog(const []),
    programRunPlanner: programRunPlanner ?? _testProgramRunPlanner(),
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

ProgramRunPlanner _testProgramRunPlanner() {
  return ProgramRunPlanner(hostPlatform: KonyakHostPlatform.macos);
}

final class RecordingProgramRunner implements ProgramRunner {
  RecordingProgramRunner({
    ProgramRunResult? result,
    List<ProgramRunResult>? results,
  }) : results = _recordingProgramResults(result: result, results: results) {
    if (this.results.isEmpty) {
      throw ArgumentError('At least one program run result is required.');
    }
  }

  final List<ProgramRunResult> results;
  final List<ProgramRunRequest> requests = <ProgramRunRequest>[];
  ProgramRunRequest? lastRequest;
  var _nextResultIndex = 0;

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    requests.add(request);
    lastRequest = request;

    final resultIndex = min(_nextResultIndex, results.length - 1);
    _nextResultIndex += 1;

    return results[resultIndex];
  }
}

final class FixedProgramMetadataExtractor implements ProgramMetadataExtractor {
  const FixedProgramMetadataExtractor({
    required this.programPath,
    required this.metadata,
  });

  final String programPath;
  final ProgramMetadataRecord metadata;

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  }) {
    return programPath.value == this.programPath
        ? Option.of(metadata)
        : const Option.none();
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

final class NoopAsyncProgramMetadataExtractor
    implements AsyncProgramMetadataExtractor {
  const NoopAsyncProgramMetadataExtractor();

  @override
  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  }) async {
    return const Option.none();
  }
}

final class EmptyBottleProgramRepository implements BottleProgramRepository {
  const EmptyBottleProgramRepository();

  @override
  List<BottleProgramRecord> listPrograms(BottleRecord bottle) {
    return const <BottleProgramRecord>[];
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

final class RecordingProgramGraphicsBackendHintsInspector
    implements ProgramGraphicsBackendHintsInspector {
  RecordingProgramGraphicsBackendHintsInspector(this.result);

  final ProgramGraphicsBackendHintsInspectionResult result;
  final List<({ProgramPath programPath, KonyakHostPlatform hostPlatform})>
  requests = <({ProgramPath programPath, KonyakHostPlatform hostPlatform})>[];

  @override
  ProgramGraphicsBackendHintsInspectionResult inspect({
    required ProgramPath programPath,
    required KonyakHostPlatform hostPlatform,
  }) {
    requests.add((programPath: programPath, hostPlatform: hostPlatform));

    return result;
  }
}

final class ThrowingProgramMetadataExtractor
    implements ProgramMetadataExtractor {
  const ThrowingProgramMetadataExtractor(this.error);

  final StateError error;

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  }) {
    throw error;
  }
}

final class ControlledAsyncProgramRunner implements AsyncProgramRunner {
  final List<ProgramRunRequest> requests = <ProgramRunRequest>[];
  final Map<String, Completer<ProgramRunResult>> _pending =
      <String, Completer<ProgramRunResult>>{};

  @override
  Future<ProgramRunResult> run(ProgramRunRequest request) {
    requests.add(request);
    final completer = Completer<ProgramRunResult>();
    _pending[request.bottleId.value] = completer;
    return completer.future;
  }

  Future<void> waitForRequestCount(int count) async {
    while (requests.length < count) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void complete(String bottleId, ProgramRunResult result) {
    final completer = _pending[bottleId];
    if (completer == null) {
      throw StateError('No pending request for bottle `$bottleId`.');
    }
    completer.complete(result);
  }
}

final class UnavailableAsyncProgramRunner implements AsyncProgramRunner {
  const UnavailableAsyncProgramRunner();

  @override
  Future<ProgramRunResult> run(ProgramRunRequest request) async {
    return const ProgramRunFailed(
      message: 'Async program runner was not injected.',
    );
  }
}

final class FixedHostProcessSnapshotReader
    implements HostProcessSnapshotReader {
  const FixedHostProcessSnapshotReader(this.snapshot);

  final String snapshot;

  @override
  Future<String> read() async => snapshot;
}

final class EmptyHostProcessSnapshotReader
    implements HostProcessSnapshotReader {
  const EmptyHostProcessSnapshotReader();

  @override
  Future<String> read() async => '';
}

final class CountingAsyncProgramMetadataExtractor
    implements AsyncProgramMetadataExtractor {
  CountingAsyncProgramMetadataExtractor({
    required this.programPath,
    required this.metadata,
  });

  final String programPath;
  final ProgramMetadataRecord metadata;
  final List<String> requestedProgramPaths = <String>[];

  @override
  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  }) async {
    requestedProgramPaths.add(programPath.value);
    return programPath.value == this.programPath
        ? Option.of(metadata)
        : const Option.none();
  }
}

final class RecordingLinuxExternalProgramLauncherDiagnosticSink
    implements LinuxExternalProgramLauncherDiagnosticSink {
  final failures = <LinuxExternalProgramLauncherSyncFailure>[];

  @override
  void emit(LinuxExternalProgramLauncherSyncFailure failure) {
    failures.add(failure);
  }
}

List<ProgramRunResult> _recordingProgramResults({
  required ProgramRunResult? result,
  required List<ProgramRunResult>? results,
}) {
  final providedResults = results;
  if (providedResults != null) {
    return List.unmodifiable(providedResults);
  }

  final providedResult = result;
  if (providedResult != null) {
    return List.unmodifiable(<ProgramRunResult>[providedResult]);
  }

  return const <ProgramRunResult>[];
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

RuntimeDefinition runtimeDefinitionFixture({
  required String id,
  required String name,
  required String platform,
  required String architecture,
  required String runnerKind,
  required bool isBundled,
  required bool isUpdateable,
  Option<String> distributionKind = const Option.none(),
  Option<String> archiveUrl = const Option.none(),
  Option<String> versionUrl = const Option.none(),
}) {
  return RuntimeDefinition(
    id: RuntimeId(id),
    name: RuntimeName(name),
    platform: RuntimePlatformName(platform),
    architecture: RuntimeArchitecture(architecture),
    runnerKind: RunnerKind(runnerKind),
    isBundled: isBundled,
    isUpdateable: isUpdateable,
    distributionKind: distributionKind.map(RuntimeDistributionKind.new),
    archiveUrl: archiveUrl.map(RuntimeArchiveUrl.new),
    versionUrl: versionUrl.map(RuntimeVersionUrl.new),
  );
}

RuntimeRecord runtimeRecordFixture({
  required String id,
  required String name,
  required String platform,
  required String architecture,
  required String runnerKind,
  required bool isBundled,
  required bool isUpdateable,
  Option<String> distributionKind = const Option.none(),
  Option<bool> isInstalled = const Option.none(),
  Option<String> applicationSupportPath = const Option.none(),
  Option<String> libraryPath = const Option.none(),
  Option<String> executablePath = const Option.none(),
  Option<String> archiveUrl = const Option.none(),
  Option<String> versionUrl = const Option.none(),
  Option<RuntimeStack> stack = const Option.none(),
}) {
  return RuntimeRecord(
    id: RuntimeId(id),
    name: RuntimeName(name),
    platform: RuntimePlatformName(platform),
    architecture: RuntimeArchitecture(architecture),
    runnerKind: RunnerKind(runnerKind),
    isBundled: isBundled,
    isUpdateable: isUpdateable,
    distributionKind: distributionKind.map(RuntimeDistributionKind.new),
    isInstalled: isInstalled,
    applicationSupportPath: applicationSupportPath.map(
      RuntimeComponentPath.new,
    ),
    libraryPath: libraryPath.map(RuntimeComponentPath.new),
    executablePath: executablePath.map(RuntimeComponentPath.new),
    archiveUrl: archiveUrl.map(RuntimeArchiveUrl.new),
    versionUrl: versionUrl.map(RuntimeVersionUrl.new),
    stack: stack,
  );
}

RuntimeStack runtimeStackFixture({
  required String id,
  required String name,
  required String compatibilityTarget,
  required Iterable<RuntimeStackComponent> components,
  Iterable<RuntimeStackBackend> backends = const <RuntimeStackBackend>[],
}) {
  return RuntimeStack(
    id: RuntimeStackId(id),
    name: RuntimeStackName(name),
    compatibilityTarget: RuntimeCompatibilityTarget(compatibilityTarget),
    components: components,
    backends: backends,
  );
}

RuntimeStackBackend runtimeStackBackendFixture({
  required String id,
  required String name,
  required String role,
  required Iterable<String> componentIds,
  required Iterable<String> missingComponentIds,
  required Iterable<String> missingPaths,
}) {
  return RuntimeStackBackend(
    id: RuntimeBackendId(id),
    name: RuntimeName(name),
    role: RuntimeRole(role),
    componentIds: componentIds.map(RuntimeComponentId.new),
    missingComponentIds: missingComponentIds.map(RuntimeComponentId.new),
    missingPaths: missingPaths.map(RuntimeMissingPath.new),
  );
}

RuntimeStackComponent runtimeStackComponentFixture({
  required String id,
  required String name,
  required String role,
  required bool isRequired,
  required Iterable<String> paths,
  required Iterable<String> missingPaths,
  Option<String> version = const Option.none(),
}) {
  return RuntimeStackComponent(
    id: RuntimeComponentId(id),
    name: RuntimeName(name),
    role: RuntimeRole(role),
    isRequired: isRequired,
    paths: paths.map(RuntimeComponentPath.new),
    missingPaths: missingPaths.map(RuntimeMissingPath.new),
    version: version.map(RuntimeVersion.new),
  );
}

void expectMissing(IoResult<Option<BottleRecord>> result) {
  expectIo(result).match(
    () {},
    (bottle) =>
        throw TestFailure('Expected bottle to be missing: ${bottle.id.value}'),
  );
}

final class RecordingBottlePrefixInitializer
    implements BottlePrefixInitializer {
  RecordingBottlePrefixInitializer({required this.result});

  final BottlePrefixInitializationResult result;
  BottleRecord? lastBottle;

  @override
  BottlePrefixInitializationResult initialize(BottleRecord bottle) {
    lastBottle = bottle;

    return result;
  }
}

final class FailingBottleRepository extends MemoryBottleRepository {
  FailingBottleRepository({
    required super.dataHome,
    required this.message,
    super.bottles,
    super.programMetadataExtractor = const NoopProgramMetadataExtractor(),
  });

  final String message;

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return BottleCreateFailed(message);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return ProgramSettingsReadResult.failed(message);
  }
}

final class RecordingPathOpener implements PathOpener {
  RecordingPathOpener({required this.result});

  final PathOpenResult result;
  PathOpenTarget? lastOpenTarget;
  PathRevealTarget? lastRevealTarget;

  String? get lastPath => lastOpenTarget?.value;

  String? get lastRevealedPath => lastRevealTarget?.value;

  @override
  PathOpenResult openPath(PathOpenTarget target) {
    lastOpenTarget = target;

    return result;
  }

  @override
  PathOpenResult revealPath(PathRevealTarget target) {
    lastRevealTarget = target;

    return result;
  }
}

final class RecordingWinetricksVerbLister implements WinetricksVerbLister {
  RecordingWinetricksVerbLister({required this.result});

  final WinetricksVerbListResult result;
  ProgramExecutable? programExecutable;

  String? get executable => programExecutable?.value;

  @override
  WinetricksVerbListResult listVerbs({required ProgramExecutable executable}) {
    programExecutable = executable;

    return result;
  }
}

final class RecordingMacosWineInstaller implements MacosWineInstaller {
  RecordingMacosWineInstaller({required this.result});

  final MacosWineInstallResult result;
  MacosWineInstallRequest? lastRequest;

  @override
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    lastRequest = request;
    progressSink?.emit(
      RuntimeInstallProgress(
        stage: 'test',
        message: 'Installing test runtime...',
        fraction: 0.5,
      ),
    );

    return result;
  }
}

final class RecordingLinuxWineInstaller implements LinuxWineInstaller {
  RecordingLinuxWineInstaller({required this.result});

  final LinuxWineInstallResult result;
  LinuxWineInstallRequest? lastRequest;

  @override
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    lastRequest = request;
    progressSink?.emit(
      RuntimeInstallProgress(
        stage: 'test',
        message: 'Installing test runtime...',
        fraction: 0.5,
      ),
    );

    return result;
  }
}

final class RecordingRuntimeInstallProgressSink
    implements RuntimeInstallProgressSink {
  final List<RuntimeInstallProgress> events = <RuntimeInstallProgress>[];

  @override
  void emit(RuntimeInstallProgress progress) {
    events.add(progress);
  }
}

final class RecordingRuntimeUpdateChecker implements RuntimeUpdateChecker {
  RecordingRuntimeUpdateChecker({required this.result});

  final RuntimeUpdateCheckResult result;
  RuntimeId? lastRuntimeIdValue;

  String? get lastRuntimeId => lastRuntimeIdValue?.value;

  @override
  RuntimeUpdateCheckResult check(RuntimeId runtimeId) {
    lastRuntimeIdValue = runtimeId;

    return result;
  }
}

final class RecordingAppUpdateChecker implements AppUpdateChecker {
  RecordingAppUpdateChecker({required this.result});

  final AppUpdateCheckResult result;
  var checkCount = 0;

  @override
  AppUpdateCheckResult check() {
    checkCount += 1;

    return result;
  }
}

final class RecordingAppUpdateInstaller implements AppUpdateInstaller {
  RecordingAppUpdateInstaller({required this.result});

  final AppUpdateInstallResult result;
  AppUpdateRecord? lastUpdate;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    lastUpdate = update;

    return result;
  }
}

final class RecordingDetachedProcessStarter implements DetachedProcessStarter {
  RecordingDetachedProcessStarter({required this.result});

  final DetachedProcessStartResult result;
  ProgramExecutable? lastExecutable;
  ProgramRunArguments lastArguments = ProgramRunArguments(const <String>[]);

  @override
  DetachedProcessStartResult start({
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
  }) {
    lastExecutable = executable;
    lastArguments = arguments;

    return result;
  }
}

final class RecordingRuntimeValidator implements RuntimeValidator {
  RecordingRuntimeValidator({required this.result});

  final RuntimeValidationResult result;
  RuntimeId? lastRuntimeIdValue;

  String? get lastRuntimeId => lastRuntimeIdValue?.value;

  @override
  RuntimeValidationResult validate(RuntimeId runtimeId) {
    lastRuntimeIdValue = runtimeId;

    return result;
  }
}

final class RecordingMacosSetupChecker implements MacosSetupChecker {
  RecordingMacosSetupChecker({required this.result});

  final MacosSetupCheckResult result;

  @override
  MacosSetupCheckResult check() {
    return result;
  }
}

final class RecordingRuntimeExecutableProbe implements RuntimeExecutableProbe {
  RecordingRuntimeExecutableProbe({required this.result});

  final RuntimeExecutableProbeResult result;
  ProgramExecutable? lastProgramExecutable;
  ProgramRunArguments lastProgramRunArguments = ProgramRunArguments(
    const <String>[],
  );
  Map<String, String> lastEnvironment = const <String, String>{};
  ProgramWorkingDirectoryPath? lastProgramWorkingDirectory;

  String? get lastExecutable => lastProgramExecutable?.value;

  List<String> get lastArguments => lastProgramRunArguments.value;

  String? get lastWorkingDirectory => lastProgramWorkingDirectory?.value;

  @override
  RuntimeExecutableProbeResult run({
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
    required ProgramRunEnvironment environment,
    required ProgramWorkingDirectoryPath workingDirectory,
  }) {
    lastProgramExecutable = executable;
    lastProgramRunArguments = arguments;
    lastEnvironment = Map.unmodifiable(environment.toMap());
    lastProgramWorkingDirectory = workingDirectory;

    return result;
  }
}

final class StaticFileStatusProbe implements FileStatusProbe {
  const StaticFileStatusProbe(this._existingPaths);

  final Set<String> _existingPaths;

  @override
  bool exists(String path) {
    return _existingPaths.contains(path);
  }
}

final class EmptyRuntimeStackVersionProbe implements RuntimeStackVersionProbe {
  const EmptyRuntimeStackVersionProbe();

  @override
  Option<RuntimeVersion> versionFor({
    required RuntimeRootPath runtimeRoot,
    required RuntimeComponentId componentId,
  }) {
    return const Option.none();
  }
}

const macosDxvkComponentPaths = <List<String>>[
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'dxgi.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'd3d9.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'd3d10.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'd3d10_1.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'd3d10core.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'd3d11.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'dxgi.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'd3d9.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'd3d10.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'd3d10_1.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'd3d10core.dll'],
  <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'd3d11.dll'],
];

const macosDxvkInstalledPaths = <List<String>>[
  <String>['DXVK', 'x64', 'dxgi.dll'],
  <String>['DXVK', 'x64', 'd3d9.dll'],
  <String>['DXVK', 'x64', 'd3d10.dll'],
  <String>['DXVK', 'x64', 'd3d10_1.dll'],
  <String>['DXVK', 'x64', 'd3d10core.dll'],
  <String>['DXVK', 'x64', 'd3d11.dll'],
  <String>['DXVK', 'x32', 'dxgi.dll'],
  <String>['DXVK', 'x32', 'd3d9.dll'],
  <String>['DXVK', 'x32', 'd3d10.dll'],
  <String>['DXVK', 'x32', 'd3d10_1.dll'],
  <String>['DXVK', 'x32', 'd3d10core.dll'],
  <String>['DXVK', 'x32', 'd3d11.dll'],
];

Set<String> macosDxvkExistingPaths(String runtimeRoot) {
  final architectureFolders = <String, String>{
    'x64': 'x86_64-windows',
    'x32': 'i386-windows',
  };
  return <String>{
    for (final relativePath in macosDxvkInstalledPaths)
      joinTestPath(runtimeRoot, <String>[
        'lib',
        'dxvk',
        architectureFolders[relativePath[1]]!,
        relativePath.last,
      ]),
  };
}

const macosDxmtComponentPaths = <List<String>>[
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'd3d10core.dll',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'd3d11.dll',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'dxgi.dll',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'winemetal.dll',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'winemetal.so',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'nvapi64.dll',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-windows',
    'nvngx.dll',
  ],
  <String>[
    'Components',
    'DXMT',
    'components',
    'dxmt',
    'x86_64-unix',
    'winemetal.so',
  ],
];

const macosDxmtInstalledPaths = <List<String>>[
  <String>['lib', 'dxmt', 'x86_64-windows', 'd3d10core.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'd3d11.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'dxgi.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.so'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'nvapi64.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'nvngx.dll'],
  <String>['lib', 'dxmt', 'x86_64-unix', 'winemetal.so'],
];

const macosFreetypeComponentPaths = <List<String>>[
  <String>['Components', 'FreeType', 'lib', 'libfreetype.6.dylib'],
  <String>['Components', 'FreeType', 'lib', 'libfreetype.dylib'],
];

const macosGstreamerInstalledPaths = <List<String>>[
  <String>['lib', 'libgstreamer-1.0.0.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstcoreelements.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstplayback.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgsttypefindfunctions.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstisomp4.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstwavparse.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstapplemedia.dylib'],
  <String>['libexec', 'gstreamer-1.0', 'gst-plugin-scanner'],
];

final macosGstreamerComponentPaths = <List<String>>[
  for (final relativePath in macosGstreamerInstalledPaths)
    <String>['Components', 'GStreamer', ...relativePath],
];

const macosWineMonoInstalledPaths = <List<String>>[
  <String>['share', 'wine', 'mono', 'wine-mono-10.4.1-x86.msi'],
];

final macosWineMonoComponentPaths = <List<String>>[
  for (final relativePath in macosWineMonoInstalledPaths)
    <String>['Components', 'wine-mono', ...relativePath],
];

const macosWineGeckoInstalledPaths = <List<String>>[
  <String>['share', 'wine', 'gecko', 'wine-gecko-2.47.4-x86.msi'],
  <String>['share', 'wine', 'gecko', 'wine-gecko-2.47.4-x86_64.msi'],
];

final macosWineGeckoComponentPaths = <List<String>>[
  for (final relativePath in macosWineGeckoInstalledPaths)
    <String>['Components', 'wine-gecko', ...relativePath],
];

const macosWinetricksInstalledPaths = <List<String>>[
  <String>['winetricks'],
  <String>['verbs.txt'],
];

final macosWinetricksComponentPaths = <List<String>>[
  for (final relativePath in macosWinetricksInstalledPaths)
    <String>['Components', 'winetricks', ...relativePath],
];

Set<String> macosGstreamerExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in macosGstreamerInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosGstreamerExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in macosGstreamerInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

Set<String> macosWineMonoExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in macosWineMonoInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosWineMonoExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in macosWineMonoInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

Set<String> macosWineGeckoExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in macosWineGeckoInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosWineGeckoExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in macosWineGeckoInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

Set<String> macosWinetricksExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in macosWinetricksInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosWinetricksExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in macosWinetricksInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

const _macosWine32On64InstalledPaths = <List<String>>[
  <String>['lib', 'wine', 'i386-windows', 'ntdll.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64cpu.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64win.dll'],
  <String>['lib', 'wine', 'x86_64-unix', 'ntdll.so'],
];

const _macosWineEntryPointInstalledPaths = <List<String>>[
  <String>['bin', 'wine'],
  <String>['bin', 'wineloader'],
  <String>['bin', 'wineserver'],
  <String>['Konyak Wine Hosted Application', 'wine'],
  <String>['Konyak Wine Hosted Application', 'wineloader'],
  <String>['Konyak Wine Hosted Application', 'wineserver'],
  <String>['lib', 'wine', 'x86_64-unix', 'wine'],
];

Set<String> macosWineEntryPointExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in _macosWineEntryPointInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosWineEntryPointExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in _macosWineEntryPointInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

const macosVkd3dInstalledPaths = <List<String>>[
  <String>['lib', 'wine', 'x86_64-windows', 'libvkd3d-1.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'libvkd3d-shader-1.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'libvkd3d-utils-1.dll'],
  <String>['lib', 'wine', 'i386-windows', 'libvkd3d-1.dll'],
  <String>['lib', 'wine', 'i386-windows', 'libvkd3d-shader-1.dll'],
  <String>['lib', 'wine', 'i386-windows', 'libvkd3d-utils-1.dll'],
];

final macosVkd3dComponentPaths = <List<String>>[
  for (final relativePath in macosVkd3dInstalledPaths)
    <String>['Components', 'vkd3d', ...relativePath],
];

Set<String> macosVkd3dExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in macosVkd3dInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosVkd3dExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in macosVkd3dInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

Set<String> macosWine32On64ExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in _macosWine32On64InstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> macosWine32On64ExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in _macosWine32On64InstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

String macosManagedWineDllPath(String runtimeRoot) {
  return <String>[
    joinTestPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    joinTestPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
    joinTestPath(runtimeRoot, const ['lib', 'wine']),
  ].join(':');
}

List<String> gptkD3DMetalExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in gptkD3DMetalInstalledPaths)
      joinTestPath(runtimeRoot, relativePath),
  ];
}

String macosManagedWineDllPathWithOverrides(
  String runtimeRoot,
  List<List<String>> overridePaths,
) {
  return <String>[
    for (final relativePath in overridePaths)
      joinTestPath(runtimeRoot, relativePath),
    macosManagedWineDllPath(runtimeRoot),
  ].join(':');
}

String macosManagedWinePath(String runtimeRoot) {
  final unixPaths = <String>[
    joinTestPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    joinTestPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
  ];
  return unixPaths.map(_macosWineWindowsPath).join(';');
}

String macosManagedWinePathWithOverrides(
  String runtimeRoot,
  List<List<String>> overridePaths,
) {
  final unixPaths = <String>[
    for (final overridePath in overridePaths)
      joinTestPath(runtimeRoot, overridePath),
    joinTestPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    joinTestPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
  ];
  return unixPaths.map(_macosWineWindowsPath).join(';');
}

String _macosWineWindowsPath(String unixPath) {
  final windowsPath = unixPath.replaceAll('/', '\\');
  if (unixPath.startsWith('/')) {
    return 'Z:$windowsPath';
  }
  return windowsPath;
}

String createComponentRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(joinTestPath(tempPath, const ['source']));
  final librariesRoot = Directory(
    joinTestPath(sourceRoot.path, const ['Libraries']),
  );
  final wineRoot = Directory(joinTestPath(librariesRoot.path, const ['Wine']));

  for (final relativePath in <List<String>>[
    for (final relativePath in _macosWineEntryPointInstalledPaths)
      <String>['Wine', ...relativePath],
    for (final relativePath in _macosWine32On64InstalledPaths)
      <String>['Wine', ...relativePath],
    <String>['Wine', 'lib', 'dxvk', 'x86_64-windows', 'dxgi.dll'],
    <String>['Wine', 'lib', 'dxvk', 'x86_64-windows', 'd3d9.dll'],
    <String>['Wine', 'lib', 'dxvk', 'x86_64-windows', 'd3d10.dll'],
    <String>['Wine', 'lib', 'dxvk', 'x86_64-windows', 'd3d10_1.dll'],
    <String>['Wine', 'lib', 'dxvk', 'x86_64-windows', 'd3d10core.dll'],
    <String>['Wine', 'lib', 'dxvk', 'x86_64-windows', 'd3d11.dll'],
    <String>['Wine', 'lib', 'dxvk', 'i386-windows', 'dxgi.dll'],
    <String>['Wine', 'lib', 'dxvk', 'i386-windows', 'd3d9.dll'],
    <String>['Wine', 'lib', 'dxvk', 'i386-windows', 'd3d10.dll'],
    <String>['Wine', 'lib', 'dxvk', 'i386-windows', 'd3d10_1.dll'],
    <String>['Wine', 'lib', 'dxvk', 'i386-windows', 'd3d10core.dll'],
    <String>['Wine', 'lib', 'dxvk', 'i386-windows', 'd3d11.dll'],
    <String>['Wine', 'lib', 'libMoltenVK.dylib'],
    for (final relativePath in macosGstreamerInstalledPaths)
      <String>['Wine', ...relativePath],
    <String>['Wine', 'lib', 'libfreetype.6.dylib'],
    <String>['Wine', 'lib', 'libfreetype.dylib'],
    for (final relativePath in macosWineMonoInstalledPaths)
      <String>['Wine', ...relativePath],
    for (final relativePath in macosWineGeckoInstalledPaths)
      <String>['Wine', ...relativePath],
    for (final relativePath in macosDxmtInstalledPaths)
      <String>['Wine', ...relativePath],
    for (final relativePath in macosVkd3dInstalledPaths)
      <String>['Wine', ...relativePath],
    for (final relativePath in macosWinetricksInstalledPaths)
      <String>[...relativePath],
  ]) {
    final file = File(joinTestPath(librariesRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
  File(
    joinTestPath(librariesRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'components': {
        'wine': 'wine-devel-11.9',
        'dxvk-macos': 'dxvk-macos-fixture',
        'dxmt': 'dxmt-fixture',
        'vkd3d': 'vkd3d-fixture',
      },
    }),
  );

  expect(wineRoot.existsSync(), isTrue);

  final archivePath = joinTestPath(tempPath, const ['runtime.tar.gz']);
  final result = Process.runSync('tar', [
    '-czf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Libraries',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String createKonyakComponentRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(
    joinTestPath(tempPath, const ['component-source']),
  );
  final runtimeRoot = Directory(
    joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in <List<String>>[
    for (final relativePath in _macosWineEntryPointInstalledPaths)
      <String>[
        'Wine Devel.app',
        'Contents',
        'Resources',
        'wine',
        ...relativePath,
      ],
    for (final relativePath in _macosWine32On64InstalledPaths)
      <String>[
        'Wine Devel.app',
        'Contents',
        'Resources',
        'wine',
        ...relativePath,
      ],
    <String>[
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
      'lib',
      'libwine.1.dylib',
    ],
    ...macosDxvkComponentPaths,
    ...macosDxmtComponentPaths,
    <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
    ...macosGstreamerComponentPaths,
    ...macosFreetypeComponentPaths,
    ...macosWineMonoComponentPaths,
    ...macosWineGeckoComponentPaths,
    ...macosWinetricksComponentPaths,
    ...macosVkd3dComponentPaths,
  ]) {
    final file = File(joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
  File(
    joinTestPath(runtimeRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'components': {
        'wine': 'wine-devel-11.9',
        'dxvk-macos': 'dxvk-macos-fixture',
        'dxmt': 'dxmt-fixture',
        'moltenvk': 'moltenvk-fixture',
        'gstreamer': 'gstreamer-fixture',
        'freetype': 'freetype-fixture',
        'wine-mono': 'wine-mono-fixture',
        'wine-gecko': 'wine-gecko-fixture',
        'winetricks': 'winetricks-fixture',
        'vkd3d': 'vkd3d-fixture',
      },
    }),
  );

  final archivePath = joinTestPath(tempPath, const [
    'component-runtime.tar.xz',
  ]);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Runtime',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String createKonyakRuntimeComponentArchive(
  String tempPath, {
  required String archiveName,
  required List<List<String>> relativePaths,
  required Map<String, String> versions,
}) {
  final sourceRoot = Directory(
    joinTestPath(tempPath, ['component-source-$archiveName']),
  );
  final runtimeRoot = Directory(
    joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in relativePaths) {
    final file = File(joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    if (isGptkD3DMetalUnixSymlinkPath(relativePath)) {
      Link(file.path).createSync('../../external/libd3dshared.dylib');
    } else if (gptkD3DMetalWindowsFileNames.contains(relativePath.last)) {
      _createPEFile(file.path);
    } else if (relativePath.contains('D3DMetal.framework') ||
        relativePath.contains('libd3dshared.dylib') ||
        gptkD3DMetalUnixFileNames.contains(relativePath.last)) {
      _createMachOFile(file.path);
    } else {
      file.writeAsStringSync('fixture');
    }
  }
  File(
    joinTestPath(runtimeRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(jsonEncode({'schemaVersion': 1, 'components': versions}));

  final archivePath = joinTestPath(tempPath, ['$archiveName.tar.xz']);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Runtime',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String createRuntimeStackSourceManifest(
  String tempPath, {
  String fileName = 'runtime-stack-source.json',
  String runtimeId = 'konyak-macos-wine',
  String stackId = 'macos-konyak-runtime-stack',
  required List<Map<String, String>> components,
}) {
  final manifestPath = joinTestPath(tempPath, [fileName]);
  File(manifestPath).writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'runtimeId': runtimeId,
      'stackId': stackId,
      'components': components,
    }),
  );

  return manifestPath;
}

final class RuntimeStackManifestSignature {
  const RuntimeStackManifestSignature({
    required this.publicKeyPath,
    required this.signaturePath,
  });

  final String publicKeyPath;
  final String signaturePath;
}

RuntimeStackManifestSignature createRuntimeStackManifestSignature(
  String tempPath, {
  required String manifestPath,
}) {
  final privateKeyPath = joinTestPath(tempPath, const [
    'runtime-stack-key.pem',
  ]);
  final publicKeyPath = joinTestPath(tempPath, const [
    'runtime-stack-key.pub.pem',
  ]);
  final signaturePath = '$manifestPath.sig';

  final privateKeyResult = Process.runSync('openssl', [
    'genpkey',
    '-algorithm',
    'RSA',
    '-pkeyopt',
    'rsa_keygen_bits:2048',
    '-out',
    privateKeyPath,
  ]);
  expect(
    privateKeyResult.exitCode,
    0,
    reason: privateKeyResult.stderr.toString(),
  );

  final publicKeyResult = Process.runSync('openssl', [
    'pkey',
    '-in',
    privateKeyPath,
    '-pubout',
    '-out',
    publicKeyPath,
  ]);
  expect(
    publicKeyResult.exitCode,
    0,
    reason: publicKeyResult.stderr.toString(),
  );

  final signatureResult = Process.runSync('openssl', [
    'dgst',
    '-sha256',
    '-sign',
    privateKeyPath,
    '-out',
    signaturePath,
    manifestPath,
  ]);
  expect(
    signatureResult.exitCode,
    0,
    reason: signatureResult.stderr.toString(),
  );

  return RuntimeStackManifestSignature(
    publicKeyPath: publicKeyPath,
    signaturePath: signaturePath,
  );
}

Map<String, String> runtimeStackSourceComponent({
  required String id,
  required String version,
  required String archivePath,
}) {
  return <String, String>{
    'id': id,
    'version': version,
    'archiveUrl': archivePath,
    'sha256': fileSha256(archivePath),
  };
}

String fileSha256(String path) {
  return sha256.convert(File(path).readAsBytesSync()).toString();
}

String createMacosAppBundleWineArchive(String tempPath) {
  final sourceRoot = Directory(joinTestPath(tempPath, const ['source']));
  final wineRoot = Directory(
    joinTestPath(sourceRoot.path, const [
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
    ]),
  );

  for (final relativePath in <List<String>>[
    ..._macosWineEntryPointInstalledPaths,
    ..._macosWine32On64InstalledPaths,
    <String>['lib', 'libwine.1.dylib'],
    ...macosWineMonoInstalledPaths,
    ...macosWineGeckoInstalledPaths,
    ...macosWinetricksInstalledPaths,
  ]) {
    final file = File(joinTestPath(wineRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }

  final archivePath = joinTestPath(tempPath, const [
    'app-bundle-runtime.tar.xz',
  ]);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Wine Devel.app',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

void createInstalledMacosRuntime(String runtimeHome) {
  for (final relativePath in <List<String>>[
    ..._macosWineEntryPointInstalledPaths,
    ..._macosWine32On64InstalledPaths,
    <String>['lib', 'libwine.1.dylib'],
    ...macosWineMonoInstalledPaths,
    ...macosWineGeckoInstalledPaths,
  ]) {
    final file = File(joinTestPath(runtimeHome, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
}

void createCompleteMacosRuntime(String runtimeHome) {
  createInstalledMacosRuntime(runtimeHome);
  for (final path in <String>{
    ...macosDxvkExistingPaths(runtimeHome),
    joinTestPath(runtimeHome, const ['lib', 'libMoltenVK.dylib']),
    ...macosGstreamerExistingPaths(runtimeHome),
    joinTestPath(runtimeHome, const ['lib', 'libfreetype.6.dylib']),
    joinTestPath(runtimeHome, const ['lib', 'libfreetype.dylib']),
    ...macosWinetricksExistingPaths(runtimeHome),
    ...macosVkd3dExistingPaths(runtimeHome),
    for (final relativePath in macosDxmtInstalledPaths)
      joinTestPath(runtimeHome, relativePath),
  }) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
}

Directory createGptkD3DMetalSource(
  String tempPath,
  List<String> externalRelativePath,
) {
  final sourceRoot = Directory(joinTestPath(tempPath, externalRelativePath))
    ..createSync(recursive: true);
  _createMachOFile(
    joinTestPath(sourceRoot.path, const [
      'D3DMetal.framework',
      'Versions',
      'A',
      'D3DMetal',
    ]),
  );
  _createMachOFile(joinTestPath(sourceRoot.path, const ['libd3dshared.dylib']));
  final dllRoot = _gptkFixtureDllRoot(sourceRoot);
  for (final fileName in gptkD3DMetalWindowsFileNames) {
    _createPEFile(joinTestPath(dllRoot.path, [fileName]));
  }
  final unixRoot = _gptkFixtureUnixRoot(sourceRoot);
  for (final fileName in gptkD3DMetalUnixFileNames) {
    final path = joinTestPath(unixRoot.path, [fileName]);
    File(path).parent.createSync(recursive: true);
    if (isGptkD3DMetalUnixSymlinkPath(<String>[
      'lib',
      'wine',
      'x86_64-unix',
      fileName,
    ])) {
      Link(path).createSync('../../external/libd3dshared.dylib');
    } else {
      _createMachOFile(path);
    }
  }
  return sourceRoot;
}

Directory createGptkWineRoot(
  String tempPath, {
  bool validBinaries = true,
  bool includeD3DMetal = false,
}) {
  final wineRoot = Directory(joinTestPath(tempPath, const ['gptk-wine']));
  final wineloader = File(
    joinTestPath(wineRoot.path, const ['bin', 'wineloader']),
  );
  final wineserver = File(
    joinTestPath(wineRoot.path, const ['bin', 'wineserver']),
  );
  wineloader.parent.createSync(recursive: true);
  if (validBinaries) {
    _createMachOFile(wineloader.path);
    _createMachOFile(wineserver.path);
  } else {
    wineloader.writeAsStringSync('fixture');
    wineserver.writeAsStringSync('fixture');
  }
  File(joinTestPath(wineRoot.path, const ['lib', 'libwine.1.dylib']))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('fixture');
  if (includeD3DMetal) {
    createGptkD3DMetalSource(wineRoot.path, const ['lib', 'external']);
  }
  return wineRoot;
}

Directory createGptkWineAppBundle(
  String tempPath, {
  bool validBinaries = true,
  bool includeD3DMetal = false,
}) {
  final appBundle = Directory(
    joinTestPath(tempPath, const ['Game Porting Toolkit.app']),
  );
  final wineRoot = createGptkWineRoot(
    appBundle.path,
    validBinaries: validBinaries,
    includeD3DMetal: includeD3DMetal,
  );
  final targetWineRoot = Directory(
    joinTestPath(appBundle.path, const ['Contents', 'Resources', 'wine']),
  );
  targetWineRoot.parent.createSync(recursive: true);
  wineRoot.renameSync(targetWineRoot.path);
  return appBundle;
}

Directory _gptkFixtureDllRoot(Directory externalRoot) {
  final segments = externalRoot.path.split('/');
  final libRoot = segments.last == 'external'
      ? Directory(segments.take(segments.length - 1).join('/'))
      : externalRoot;
  return Directory(
    joinTestPath(libRoot.path, const ['wine', 'x86_64-windows']),
  );
}

Directory _gptkFixtureUnixRoot(Directory externalRoot) {
  final segments = externalRoot.path.split('/');
  final libRoot = segments.last == 'external'
      ? Directory(segments.take(segments.length - 1).join('/'))
      : externalRoot;
  return Directory(joinTestPath(libRoot.path, const ['wine', 'x86_64-unix']));
}

bool isGptkD3DMetalUnixSymlinkPath(List<String> relativePath) {
  return relativePath.contains('x86_64-unix') &&
      const <String>[
        'atidxx64.so',
        'd3d11.so',
        'd3d12.so',
        'dxgi.so',
        'nvapi64.so',
        'nvngx.so',
      ].contains(relativePath.last);
}

void _createMachOFile(String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(<int>[
    0xcf,
    0xfa,
    0xed,
    0xfe,
    ...List<int>.filled(64, 0),
  ]);
}

void _createPEFile(String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(<int>[0x4d, 0x5a, ...List<int>.filled(64, 0)]);
}

String createBrokenRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(joinTestPath(tempPath, const ['broken']));
  final file = File(joinTestPath(sourceRoot.path, const ['README.txt']));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('not a runtime');

  final archivePath = joinTestPath(tempPath, const ['broken-runtime.tar.gz']);
  final result = Process.runSync('tar', [
    '-czf',
    archivePath,
    '-C',
    sourceRoot.path,
    'README.txt',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String createInvalidRuntimeArchive(String tempPath) {
  final archivePath = joinTestPath(tempPath, const ['invalid-runtime.tar.xz']);
  File(archivePath).writeAsStringSync('not a tar archive');

  return archivePath;
}

String createLinuxWineRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(joinTestPath(tempPath, const ['linux-source']));
  final runtimeRoot = Directory(
    joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in const <List<String>>[
    <String>['bin', 'wine'],
    <String>['bin', 'wineboot'],
    <String>['bin', 'winedbg'],
    <String>['bin', 'wineserver'],
    <String>['winetricks'],
    <String>['share', 'wine', 'mono', 'wine-mono-11.1.0-x86.msi'],
    <String>['dxvk', 'x64', 'dxgi.dll'],
    <String>['dxvk', 'x64', 'd3d9.dll'],
    <String>['dxvk', 'x64', 'd3d10core.dll'],
    <String>['dxvk', 'x64', 'd3d11.dll'],
    <String>['dxvk', 'x86', 'dxgi.dll'],
    <String>['dxvk', 'x86', 'd3d9.dll'],
    <String>['dxvk', 'x86', 'd3d10core.dll'],
    <String>['dxvk', 'x86', 'd3d11.dll'],
  ]) {
    final file = File(joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }

  final archivePath = joinTestPath(tempPath, const ['linux-runtime.tar.xz']);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Runtime',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

Directory createTestMacosAppBundle(String tempPath) {
  final appBundle = Directory(joinTestPath(tempPath, const ['Konyak.app']));
  File(joinTestPath(appBundle.path, const ['Contents', 'MacOS', 'Konyak']))
    ..createSync(recursive: true)
    ..writeAsStringSync('app executable');
  File(
      joinTestPath(appBundle.path, const [
        'Contents',
        'Resources',
        'konyak-cli',
      ]),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('cli executable');

  return appBundle;
}

List<Directory> generatedMacosLaunchers(String home) {
  final launcherDirectory = Directory(
    joinTestPath(home, const ['Applications', 'Konyak']),
  );
  if (!launcherDirectory.existsSync()) {
    return const <Directory>[];
  }

  final launchers = launcherDirectory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((directory) => directory.path.endsWith('.app'))
      .toList(growable: false);
  launchers.sort((left, right) => left.path.compareTo(right.path));

  return launchers;
}

Directory singleGeneratedMacosLauncher(String home) {
  final launchers = generatedMacosLaunchers(home);
  expect(launchers, hasLength(1));

  return launchers.single;
}

List<File> generatedLinuxPinnedLaunchers(String xdgDataHome) {
  final applicationsDirectory = Directory(
    joinTestPath(xdgDataHome, const ['applications']),
  );
  if (!applicationsDirectory.existsSync()) {
    return const <File>[];
  }

  final launchers = applicationsDirectory
      .listSync(followLinks: false)
      .whereType<File>()
      .where(
        (file) =>
            file.path.split('/').last.startsWith('app.konyak.Konyak.pinned.') &&
            file.path.endsWith('.desktop'),
      )
      .toList(growable: false);
  launchers.sort((left, right) => left.path.compareTo(right.path));

  return launchers;
}

File singleGeneratedLinuxPinnedLauncher(String xdgDataHome) {
  final launchers = generatedLinuxPinnedLaunchers(xdgDataHome);
  expect(launchers, hasLength(1));

  return launchers.single;
}

List<File> generatedLinuxPinnedManifests(String xdgDataHome) {
  final launcherDirectory = Directory(
    joinTestPath(xdgDataHome, const ['konyak', 'launchers', 'linux-pinned']),
  );
  if (!launcherDirectory.existsSync()) {
    return const <File>[];
  }

  final manifests = launcherDirectory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .map(
        (directory) =>
            File(joinTestPath(directory.path, const ['konyak-launcher.json'])),
      )
      .where((file) => file.existsSync())
      .toList(growable: false);
  manifests.sort((left, right) => left.path.compareTo(right.path));

  return manifests;
}

File singleGeneratedLinuxPinnedManifest(String xdgDataHome) {
  final manifests = generatedLinuxPinnedManifests(xdgDataHome);
  expect(manifests, hasLength(1));

  return manifests.single;
}

File singleGeneratedLinuxPinnedScript(String xdgDataHome) {
  final manifest = singleGeneratedLinuxPinnedManifest(xdgDataHome);
  return File(joinTestPath(manifest.parent.path, const ['launch']));
}

String joinTestPath(String root, List<String> segments) {
  return <String>[root, ...segments].join('/');
}

Uint8List syntheticPortableExecutableBytes({
  List<String> importDllNames = const <String>[],
}) {
  final iconImage = Uint8List.fromList(const <int>[1, 2, 3, 4]);
  final groupIcon = _syntheticGroupIconBytes(
    iconId: 1,
    iconByteLength: iconImage.length,
  );
  final versionInfo = _utf16LeBytes(
    [
      'VS_VERSION_INFO',
      'StringFileInfo',
      'FileDescription',
      'Fixture App',
      'ProductName',
      'Fixture Suite',
      'CompanyName',
      'Example Co',
      'FileVersion',
      '1.2.3',
      'ProductVersion',
      '4.5.6',
    ].join('\u0000'),
  );

  const peOffset = 0x80;
  const sectionHeaderOffset = peOffset + 4 + 20 + 0xf0;
  const resourceRva = 0x1000;
  const resourceRawOffset = 0x200;
  const importRva = 0x3000;
  const importRawOffset = 0x1000;
  const iconDataOffset = 0x100;
  final groupDataOffset = iconDataOffset + iconImage.length;
  final versionDataOffset = groupDataOffset + groupIcon.length;
  final resourceSize = versionDataOffset + versionInfo.length;
  final importDirectory = _syntheticImportDirectoryBytes(
    dllNames: importDllNames,
    sectionRva: importRva,
  );
  final bytes = Uint8List(
    max(
      resourceRawOffset + resourceSize + 0x100,
      importRawOffset + importDirectory.length + 0x100,
    ),
  );

  bytes[0] = 0x4d;
  bytes[1] = 0x5a;
  _writeU32(bytes, 0x3c, peOffset);
  bytes[peOffset] = 0x50;
  bytes[peOffset + 1] = 0x45;
  _writeU16(bytes, peOffset + 4, 0x8664);
  _writeU16(bytes, peOffset + 6, importDllNames.isEmpty ? 1 : 2);
  _writeU16(bytes, peOffset + 20, 0xf0);
  _writeU16(bytes, peOffset + 24, 0x020b);
  if (importDllNames.isNotEmpty) {
    _writeU32(bytes, peOffset + 24 + 120, importRva);
    _writeU32(bytes, peOffset + 24 + 124, importDirectory.length);
  }
  _writeU32(bytes, peOffset + 24 + 128, resourceRva);
  _writeU32(bytes, peOffset + 24 + 132, resourceSize);

  _writeAscii(bytes, sectionHeaderOffset, '.rsrc');
  _writeU32(bytes, sectionHeaderOffset + 8, resourceSize);
  _writeU32(bytes, sectionHeaderOffset + 12, resourceRva);
  _writeU32(bytes, sectionHeaderOffset + 16, resourceSize);
  _writeU32(bytes, sectionHeaderOffset + 20, resourceRawOffset);
  if (importDllNames.isNotEmpty) {
    final importSectionHeaderOffset = sectionHeaderOffset + 40;
    _writeAscii(bytes, importSectionHeaderOffset, '.idata');
    _writeU32(bytes, importSectionHeaderOffset + 8, importDirectory.length);
    _writeU32(bytes, importSectionHeaderOffset + 12, importRva);
    _writeU32(bytes, importSectionHeaderOffset + 16, importDirectory.length);
    _writeU32(bytes, importSectionHeaderOffset + 20, importRawOffset);
    bytes.setRange(
      importRawOffset,
      importRawOffset + importDirectory.length,
      importDirectory,
    );
  }

  _writeResourceDirectory(bytes, resourceRawOffset, [
    _ResourceDirectoryEntry(id: 3, directoryOffset: 0x028),
    _ResourceDirectoryEntry(id: 14, directoryOffset: 0x040),
    _ResourceDirectoryEntry(id: 16, directoryOffset: 0x058),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x028, [
    _ResourceDirectoryEntry(id: 1, directoryOffset: 0x070),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x040, [
    _ResourceDirectoryEntry(id: 1, directoryOffset: 0x088),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x058, [
    _ResourceDirectoryEntry(id: 1, directoryOffset: 0x0a0),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x070, [
    _ResourceDirectoryEntry(id: 1033, dataEntryOffset: 0x0b8),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x088, [
    _ResourceDirectoryEntry(id: 1033, dataEntryOffset: 0x0c8),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x0a0, [
    _ResourceDirectoryEntry(id: 1033, dataEntryOffset: 0x0d8),
  ]);

  _writeResourceDataEntry(
    bytes,
    resourceRawOffset + 0x0b8,
    resourceRva + iconDataOffset,
    iconImage.length,
  );
  _writeResourceDataEntry(
    bytes,
    resourceRawOffset + 0x0c8,
    resourceRva + groupDataOffset,
    groupIcon.length,
  );
  _writeResourceDataEntry(
    bytes,
    resourceRawOffset + 0x0d8,
    resourceRva + versionDataOffset,
    versionInfo.length,
  );

  bytes.setRange(
    resourceRawOffset + iconDataOffset,
    resourceRawOffset + iconDataOffset + iconImage.length,
    iconImage,
  );
  bytes.setRange(
    resourceRawOffset + groupDataOffset,
    resourceRawOffset + groupDataOffset + groupIcon.length,
    groupIcon,
  );
  bytes.setRange(
    resourceRawOffset + versionDataOffset,
    resourceRawOffset + versionDataOffset + versionInfo.length,
    versionInfo,
  );

  return bytes;
}

Uint8List _syntheticImportDirectoryBytes({
  required List<String> dllNames,
  required int sectionRva,
}) {
  final descriptorBytes = (dllNames.length + 1) * 20;
  final nameBytes = <List<int>>[
    for (final dllName in dllNames) [...ascii.encode(dllName), 0],
  ];
  final size =
      descriptorBytes +
      nameBytes.fold<int>(0, (sum, bytes) => sum + bytes.length);
  final bytes = Uint8List(size);
  var nameOffset = descriptorBytes;

  for (var index = 0; index < dllNames.length; index += 1) {
    _writeU32(bytes, index * 20 + 12, sectionRva + nameOffset);
    final name = nameBytes[index];
    bytes.setRange(nameOffset, nameOffset + name.length, name);
    nameOffset += name.length;
  }

  return bytes;
}

Uint8List syntheticShellLinkBytes({required String localBasePath}) {
  final localBasePathBytes = ascii.encode(localBasePath);
  const shellLinkHeaderSize = 0x4c;
  const linkInfoOffset = shellLinkHeaderSize;
  const linkInfoHeaderSize = 0x24;
  final linkInfoSize = linkInfoHeaderSize + localBasePathBytes.length + 1;
  final bytes = Uint8List(shellLinkHeaderSize + linkInfoSize);

  _writeU32(bytes, 0, shellLinkHeaderSize);
  _writeU32(bytes, 0x14, 0x00000002);
  _writeU32(bytes, linkInfoOffset, linkInfoSize);
  _writeU32(bytes, linkInfoOffset + 4, linkInfoHeaderSize);
  _writeU32(bytes, linkInfoOffset + 8, 0x00000001);
  _writeU32(bytes, linkInfoOffset + 16, linkInfoHeaderSize);
  bytes.setRange(
    linkInfoOffset + linkInfoHeaderSize,
    linkInfoOffset + linkInfoHeaderSize + localBasePathBytes.length,
    localBasePathBytes,
  );

  return bytes;
}

Uint8List _syntheticGroupIconBytes({
  required int iconId,
  required int iconByteLength,
}) {
  final bytes = Uint8List(20);
  _writeU16(bytes, 2, 1);
  _writeU16(bytes, 4, 1);
  bytes[6] = 1;
  bytes[7] = 1;
  _writeU16(bytes, 10, 1);
  _writeU16(bytes, 12, 32);
  _writeU32(bytes, 14, iconByteLength);
  _writeU16(bytes, 18, iconId);

  return bytes;
}

Uint8List _utf16LeBytes(String value) {
  final bytes = Uint8List((value.length + 1) * 2);
  for (var index = 0; index < value.length; index += 1) {
    _writeU16(bytes, index * 2, value.codeUnitAt(index));
  }

  return bytes;
}

void _writeResourceDirectory(
  Uint8List bytes,
  int offset,
  List<_ResourceDirectoryEntry> entries,
) {
  _writeU16(bytes, offset + 14, entries.length);
  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    final entryOffset = offset + 16 + index * 8;
    _writeU32(bytes, entryOffset, entry.id);
    final directoryOffset = entry.directoryOffset;
    if (directoryOffset != null) {
      _writeU32(bytes, entryOffset + 4, 0x80000000 | directoryOffset);
    } else {
      _writeU32(bytes, entryOffset + 4, entry.dataEntryOffset!);
    }
  }
}

void _writeResourceDataEntry(
  Uint8List bytes,
  int offset,
  int dataRva,
  int size,
) {
  _writeU32(bytes, offset, dataRva);
  _writeU32(bytes, offset + 4, size);
}

void _writeAscii(Uint8List bytes, int offset, String value) {
  final codes = ascii.encode(value);
  bytes.setRange(offset, offset + codes.length, codes);
}

void writeTestBottleMetadata(BottleRecord bottle) {
  File(joinTestPath(bottle.path.value, const ['metadata.json']))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottle': bottleRecordJson(bottle),
      }),
    );
}

void chmodPath(String path, String mode) {
  if (Platform.isWindows || !Directory(path).existsSync()) {
    return;
  }
  Process.runSync('chmod', [mode, path]);
}

void _writeU16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
}

void _writeU32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
  bytes[offset + 2] = value >> 16 & 0xff;
  bytes[offset + 3] = value >> 24 & 0xff;
}

final class _ResourceDirectoryEntry {
  const _ResourceDirectoryEntry({
    required this.id,
    this.directoryOffset,
    this.dataEntryOffset,
  }) : assert(
         (directoryOffset == null) != (dataEntryOffset == null),
         'Exactly one resource target must be provided.',
       );

  final int id;
  final int? directoryOffset;
  final int? dataEntryOffset;
}
