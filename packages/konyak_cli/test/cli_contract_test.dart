import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

part 'cli_contract_app_bottle.part.dart';
part 'cli_contract_pinned_program.part.dart';
part 'cli_contract_program_execution.part.dart';
part 'cli_contract_repository_runner.part.dart';
part 'cli_contract_runtime_process_update.part.dart';
part 'cli_contract_runtime_install.part.dart';
part 'cli_contract_executable.part.dart';

const _gptkD3DMetalWindowsFileNames = <String>[
  'atidxx64.dll',
  'd3d11.dll',
  'd3d12.dll',
  'dxgi.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

const _gptkD3DMetalUnixFileNames = <String>[
  'atidxx64.so',
  'd3d11.so',
  'd3d12.so',
  'dxgi.so',
  'nvapi64.so',
  'nvngx.so',
];

const _gptkD3DMetalOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d11.dll',
  'd3d12.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

final _gptkD3DMetalComponentArchivePaths = <List<String>>[
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
  for (final fileName in _gptkD3DMetalWindowsFileNames)
    <String>[
      'Components',
      'GPTK-D3DMetal',
      'lib',
      'wine',
      'x86_64-windows',
      fileName,
    ],
  for (final fileName in _gptkD3DMetalUnixFileNames)
    <String>[
      'Components',
      'GPTK-D3DMetal',
      'lib',
      'wine',
      'x86_64-unix',
      fileName,
    ],
];

void main() {
  test('macOS runtime release references match the repository SSOT', () {
    final referenceFile = _repoFile('runtime/macos-wine-release.json');
    final reference =
        jsonDecode(referenceFile.readAsStringSync()) as Map<String, Object?>;

    expect(reference['repository'], macosWineRuntimeRepository);
    expect(reference['defaultReleaseTag'], macosWineRuntimeDefaultReleaseTag);
    expect(
      reference['sourceManifestFileName'],
      macosWineRuntimeSourceManifestFileName,
    );
    expect(
      macosWineRuntimeSourceManifestUrl,
      'https://github.com/$macosWineRuntimeRepository/releases/download/'
      '$macosWineRuntimeDefaultReleaseTag/'
      '$macosWineRuntimeSourceManifestFileName',
    );
    expect(
      macosWineRuntimeReleaseUrl,
      'https://api.github.com/repos/$macosWineRuntimeRepository/releases/latest',
    );
  });

  defineAppAndBottleContractTests();
  definePinnedProgramContractTests();
  defineProgramExecutionContractTests();
  defineRepositoryAndRunnerContractTests();
  defineRuntimeProcessAndUpdateContractTests();
  defineRuntimeInstallContractTests();
  defineExecutableContractTests();
}

File _repoFile(String relativePath) {
  final direct = File(relativePath);
  if (direct.existsSync()) {
    return direct;
  }

  final fromPackage = File('../../$relativePath');
  if (fromPackage.existsSync()) {
    return fromPackage;
  }

  return direct;
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
    required String programPath,
  }) {
    return programPath == this.programPath
        ? Option.of(metadata)
        : const Option.none();
  }
}

final class ThrowingProgramMetadataExtractor
    implements ProgramMetadataExtractor {
  const ThrowingProgramMetadataExtractor(this.error);

  final StateError error;

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    throw error;
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

T _expectIo<T>(IoResult<T> result) {
  return result.fold((message) => throw TestFailure(message), (value) => value);
}

BottleRecord _expectFound(IoResult<Option<BottleRecord>> result) {
  return _expectIo(result).match(
    () => throw TestFailure('Expected bottle to exist.'),
    (bottle) => bottle,
  );
}

void _expectMissing(IoResult<Option<BottleRecord>> result) {
  _expectIo(result).match(
    () {},
    (bottle) =>
        throw TestFailure('Expected bottle to be missing: ${bottle.id}'),
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
    return ProgramSettingsReadFailed(message);
  }
}

final class RecordingPathOpener implements PathOpener {
  RecordingPathOpener({required this.result});

  final PathOpenResult result;
  String? lastPath;
  String? lastRevealedPath;

  @override
  PathOpenResult openPath(String path) {
    lastPath = path;

    return result;
  }

  @override
  PathOpenResult revealPath(String path) {
    lastRevealedPath = path;

    return result;
  }
}

final class RecordingWinetricksVerbLister implements WinetricksVerbLister {
  RecordingWinetricksVerbLister({required this.result});

  final WinetricksVerbListResult result;
  String? executable;

  @override
  WinetricksVerbListResult listVerbs({required String executable}) {
    this.executable = executable;

    return result;
  }
}

final class RecordingWinetricksScriptInstaller
    implements WinetricksScriptInstaller {
  RecordingWinetricksScriptInstaller({required this.result});

  final WinetricksScriptInstallResult result;
  String? executable;

  @override
  WinetricksScriptInstallResult installIfMissing({required String executable}) {
    this.executable = executable;

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
      const RuntimeInstallProgress(
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
      const RuntimeInstallProgress(
        stage: 'test',
        message: 'Installing test runtime...',
        fraction: 0.5,
      ),
    );

    return result;
  }
}

final class RecordingRuntimeUpdateChecker implements RuntimeUpdateChecker {
  RecordingRuntimeUpdateChecker({required this.result});

  final RuntimeUpdateCheckResult result;
  String? lastRuntimeId;

  @override
  RuntimeUpdateCheckResult check(String runtimeId) {
    lastRuntimeId = runtimeId;

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
  String? lastExecutable;
  List<String> lastArguments = const <String>[];

  @override
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  }) {
    lastExecutable = executable;
    lastArguments = List.unmodifiable(arguments);

    return result;
  }
}

final class RecordingRuntimeValidator implements RuntimeValidator {
  RecordingRuntimeValidator({required this.result});

  final RuntimeValidationResult result;
  String? lastRuntimeId;

  @override
  RuntimeValidationResult validate(String runtimeId) {
    lastRuntimeId = runtimeId;

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
  String? lastExecutable;
  List<String> lastArguments = const <String>[];
  Map<String, String> lastEnvironment = const <String, String>{};
  String? lastWorkingDirectory;

  @override
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required ProgramRunEnvironment environment,
    required String workingDirectory,
  }) {
    lastExecutable = executable;
    lastArguments = List.unmodifiable(arguments);
    lastEnvironment = Map.unmodifiable(environment.toMap());
    lastWorkingDirectory = workingDirectory;

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

const _macosDxvkComponentPaths = <List<String>>[
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

const _macosDxvkInstalledPaths = <List<String>>[
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

const _macosDxmtComponentPaths = <List<String>>[
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
    'x86_64-unix',
    'winemetal.so',
  ],
];

const _macosDxmtInstalledPaths = <List<String>>[
  <String>['lib', 'dxmt', 'x86_64-windows', 'd3d10core.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'd3d11.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'dxgi.dll'],
  <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.dll'],
];

const _macosFreetypeComponentPaths = <List<String>>[
  <String>['Components', 'FreeType', 'lib', 'libfreetype.6.dylib'],
  <String>['Components', 'FreeType', 'lib', 'libfreetype.dylib'],
];

const _macosGstreamerInstalledPaths = <List<String>>[
  <String>['lib', 'libgstreamer-1.0.0.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstcoreelements.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstplayback.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgsttypefindfunctions.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstisomp4.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstwavparse.dylib'],
  <String>['lib', 'gstreamer-1.0', 'libgstapplemedia.dylib'],
  <String>['libexec', 'gstreamer-1.0', 'gst-plugin-scanner'],
];

final _macosGstreamerComponentPaths = <List<String>>[
  for (final relativePath in _macosGstreamerInstalledPaths)
    <String>['Components', 'GStreamer', ...relativePath],
];

Set<String> _macosGstreamerExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in _macosGstreamerInstalledPaths)
      _joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> _macosGstreamerExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in _macosGstreamerInstalledPaths)
      _joinTestPath(runtimeRoot, relativePath),
  ];
}

const _macosWine32On64InstalledPaths = <List<String>>[
  <String>['bin', 'wine'],
  <String>['lib', 'wine', 'i386-windows', 'ntdll.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64cpu.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64win.dll'],
  <String>['lib', 'wine', 'x86_64-unix', 'ntdll.so'],
];

Set<String> _macosWine32On64ExistingPaths(String runtimeRoot) {
  return <String>{
    for (final relativePath in _macosWine32On64InstalledPaths)
      _joinTestPath(runtimeRoot, relativePath),
  };
}

List<String> _macosWine32On64ExpectedPaths(String runtimeRoot) {
  return <String>[
    for (final relativePath in _macosWine32On64InstalledPaths)
      _joinTestPath(runtimeRoot, relativePath),
  ];
}

String _macosManagedWineDllPath(String runtimeRoot) {
  return <String>[
    _joinTestPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    _joinTestPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
    _joinTestPath(runtimeRoot, const ['lib', 'wine']),
  ].join(':');
}

String _macosManagedWineDllPathWithOverrides(
  String runtimeRoot,
  List<List<String>> overridePaths,
) {
  return <String>[
    for (final relativePath in overridePaths)
      _joinTestPath(runtimeRoot, relativePath),
    _macosManagedWineDllPath(runtimeRoot),
  ].join(':');
}

String _createComponentRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['source']));
  final librariesRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Libraries']),
  );
  final wineRoot = Directory(_joinTestPath(librariesRoot.path, const ['Wine']));

  for (final relativePath in <List<String>>[
    <String>['Wine', 'bin', 'wine64'],
    <String>['Wine', 'bin', 'wineserver'],
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
    for (final relativePath in _macosGstreamerInstalledPaths)
      <String>['Wine', ...relativePath],
    <String>['Wine', 'lib', 'libfreetype.6.dylib'],
    <String>['Wine', 'lib', 'libfreetype.dylib'],
    <String>['Wine', 'share', 'wine', 'mono', 'wine-mono.marker'],
    <String>['Wine', 'lib', 'dxmt', 'x86_64-windows', 'd3d10core.dll'],
    <String>['Wine', 'lib', 'dxmt', 'x86_64-windows', 'd3d11.dll'],
    <String>['Wine', 'lib', 'dxmt', 'x86_64-windows', 'dxgi.dll'],
    <String>['Wine', 'lib', 'dxmt', 'x86_64-windows', 'winemetal.dll'],
    <String>['winetricks'],
  ]) {
    final file = File(_joinTestPath(librariesRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
  File(
    _joinTestPath(librariesRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'components': {
        'wine': 'wine-devel-11.9',
        'dxvk-macos': 'dxvk-macos-fixture',
        'dxmt': 'dxmt-fixture',
      },
    }),
  );

  expect(wineRoot.existsSync(), isTrue);

  final archivePath = _joinTestPath(tempPath, const ['runtime.tar.gz']);
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

String _createKonyakComponentRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(
    _joinTestPath(tempPath, const ['component-source']),
  );
  final runtimeRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in <List<String>>[
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
      'bin',
      'wineserver',
    ],
    <String>[
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
      'lib',
      'libwine.1.dylib',
    ],
    ..._macosDxvkComponentPaths,
    ..._macosDxmtComponentPaths,
    <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
    ..._macosGstreamerComponentPaths,
    ..._macosFreetypeComponentPaths,
    <String>['Components', 'wine-mono', 'share', 'wine', 'mono', 'marker'],
    <String>['Components', 'winetricks', 'winetricks'],
    ..._gptkD3DMetalComponentArchivePaths,
  ]) {
    final file = File(_joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    if (_isGptkD3DMetalUnixSymlinkPath(relativePath)) {
      Link(file.path).createSync('../../external/libd3dshared.dylib');
    } else if (_gptkD3DMetalWindowsFileNames.contains(relativePath.last)) {
      _createPEFile(file.path);
    } else if (relativePath.contains('GPTK-D3DMetal') ||
        _gptkD3DMetalUnixFileNames.contains(relativePath.last)) {
      _createMachOFile(file.path);
    } else {
      file.writeAsStringSync('fixture');
    }
  }
  File(
    _joinTestPath(runtimeRoot.path, const ['.konyak-runtime-stack.json']),
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
        'winetricks': 'winetricks-fixture',
        'gptk-d3dmetal': 'gptk-d3dmetal-fixture',
      },
    }),
  );

  final archivePath = _joinTestPath(tempPath, const [
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

String _createKonyakRuntimeComponentArchive(
  String tempPath, {
  required String archiveName,
  required List<List<String>> relativePaths,
  required Map<String, String> versions,
}) {
  final sourceRoot = Directory(
    _joinTestPath(tempPath, ['component-source-$archiveName']),
  );
  final runtimeRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in relativePaths) {
    final file = File(_joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    if (_isGptkD3DMetalUnixSymlinkPath(relativePath)) {
      Link(file.path).createSync('../../external/libd3dshared.dylib');
    } else if (_gptkD3DMetalWindowsFileNames.contains(relativePath.last)) {
      _createPEFile(file.path);
    } else if (relativePath.contains('D3DMetal.framework') ||
        relativePath.contains('libd3dshared.dylib') ||
        _gptkD3DMetalUnixFileNames.contains(relativePath.last)) {
      _createMachOFile(file.path);
    } else {
      file.writeAsStringSync('fixture');
    }
  }
  File(
    _joinTestPath(runtimeRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(jsonEncode({'schemaVersion': 1, 'components': versions}));

  final archivePath = _joinTestPath(tempPath, ['$archiveName.tar.xz']);
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

String _createRuntimeStackSourceManifest(
  String tempPath, {
  String fileName = 'runtime-stack-source.json',
  String runtimeId = 'konyak-macos-wine',
  String stackId = 'macos-konyak-runtime-stack',
  required List<Map<String, String>> components,
}) {
  final manifestPath = _joinTestPath(tempPath, [fileName]);
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

final class _RuntimeStackManifestSignature {
  const _RuntimeStackManifestSignature({
    required this.publicKeyPath,
    required this.signaturePath,
  });

  final String publicKeyPath;
  final String signaturePath;
}

_RuntimeStackManifestSignature _createRuntimeStackManifestSignature(
  String tempPath, {
  required String manifestPath,
}) {
  final privateKeyPath = _joinTestPath(tempPath, const [
    'runtime-stack-key.pem',
  ]);
  final publicKeyPath = _joinTestPath(tempPath, const [
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

  return _RuntimeStackManifestSignature(
    publicKeyPath: publicKeyPath,
    signaturePath: signaturePath,
  );
}

Map<String, String> _runtimeStackSourceComponent({
  required String id,
  required String version,
  required String archivePath,
}) {
  return <String, String>{
    'id': id,
    'version': version,
    'archiveUrl': archivePath,
    'sha256': _fileSha256(archivePath),
  };
}

String _fileSha256(String path) {
  return sha256.convert(File(path).readAsBytesSync()).toString();
}

String _createMacosAppBundleWineArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['source']));
  final wineRoot = Directory(
    _joinTestPath(sourceRoot.path, const [
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
    ]),
  );

  for (final relativePath in <List<String>>[
    <String>['bin', 'wineserver'],
    ..._macosWine32On64InstalledPaths,
    <String>['lib', 'libwine.1.dylib'],
    <String>['share', 'wine', 'mono', 'wine-mono.marker'],
  ]) {
    final file = File(_joinTestPath(wineRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }

  final archivePath = _joinTestPath(tempPath, const [
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

void _createInstalledMacosRuntime(String runtimeHome) {
  for (final relativePath in <List<String>>[
    <String>['bin', 'wine64'],
    <String>['bin', 'wineserver'],
    ..._macosWine32On64InstalledPaths,
    <String>['lib', 'libwine.1.dylib'],
    <String>['share', 'wine', 'mono', 'wine-mono.marker'],
  ]) {
    final file = File(_joinTestPath(runtimeHome, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
}

Directory _createGptkD3DMetalSource(
  String tempPath,
  List<String> externalRelativePath,
) {
  final sourceRoot = Directory(_joinTestPath(tempPath, externalRelativePath))
    ..createSync(recursive: true);
  _createMachOFile(
    _joinTestPath(sourceRoot.path, const [
      'D3DMetal.framework',
      'Versions',
      'A',
      'D3DMetal',
    ]),
  );
  _createMachOFile(
    _joinTestPath(sourceRoot.path, const ['libd3dshared.dylib']),
  );
  final dllRoot = _gptkFixtureDllRoot(sourceRoot);
  for (final fileName in _gptkD3DMetalWindowsFileNames) {
    _createPEFile(_joinTestPath(dllRoot.path, [fileName]));
  }
  final unixRoot = _gptkFixtureUnixRoot(sourceRoot);
  for (final fileName in _gptkD3DMetalUnixFileNames) {
    final path = _joinTestPath(unixRoot.path, [fileName]);
    File(path).parent.createSync(recursive: true);
    if (_isGptkD3DMetalUnixSymlinkPath(<String>[
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

Directory _createGptkWineRoot(
  String tempPath, {
  bool validBinaries = true,
  bool includeD3DMetal = false,
}) {
  final wineRoot = Directory(_joinTestPath(tempPath, const ['gptk-wine']));
  final wine64 = File(_joinTestPath(wineRoot.path, const ['bin', 'wine64']));
  final wineserver = File(
    _joinTestPath(wineRoot.path, const ['bin', 'wineserver']),
  );
  wine64.parent.createSync(recursive: true);
  if (validBinaries) {
    _createMachOFile(wine64.path);
    _createMachOFile(wineserver.path);
  } else {
    wine64.writeAsStringSync('fixture');
    wineserver.writeAsStringSync('fixture');
  }
  File(_joinTestPath(wineRoot.path, const ['lib', 'libwine.1.dylib']))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('fixture');
  if (includeD3DMetal) {
    _createGptkD3DMetalSource(wineRoot.path, const ['lib', 'external']);
  }
  return wineRoot;
}

Directory _createGptkWineAppBundle(
  String tempPath, {
  bool validBinaries = true,
  bool includeD3DMetal = false,
}) {
  final appBundle = Directory(
    _joinTestPath(tempPath, const ['Game Porting Toolkit.app']),
  );
  final wineRoot = _createGptkWineRoot(
    appBundle.path,
    validBinaries: validBinaries,
    includeD3DMetal: includeD3DMetal,
  );
  final targetWineRoot = Directory(
    _joinTestPath(appBundle.path, const ['Contents', 'Resources', 'wine']),
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
    _joinTestPath(libRoot.path, const ['wine', 'x86_64-windows']),
  );
}

Directory _gptkFixtureUnixRoot(Directory externalRoot) {
  final segments = externalRoot.path.split('/');
  final libRoot = segments.last == 'external'
      ? Directory(segments.take(segments.length - 1).join('/'))
      : externalRoot;
  return Directory(_joinTestPath(libRoot.path, const ['wine', 'x86_64-unix']));
}

bool _isGptkD3DMetalUnixSymlinkPath(List<String> relativePath) {
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

String _createBrokenRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['broken']));
  final file = File(_joinTestPath(sourceRoot.path, const ['README.txt']));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('not a runtime');

  final archivePath = _joinTestPath(tempPath, const ['broken-runtime.tar.gz']);
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

String _createInvalidRuntimeArchive(String tempPath) {
  final archivePath = _joinTestPath(tempPath, const ['invalid-runtime.tar.xz']);
  File(archivePath).writeAsStringSync('not a tar archive');

  return archivePath;
}

String _createLinuxWineRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['linux-source']));
  final runtimeRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Runtime']),
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
    final file = File(_joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }

  final archivePath = _joinTestPath(tempPath, const ['linux-runtime.tar.xz']);
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

Directory _createTestMacosAppBundle(String tempPath) {
  final appBundle = Directory(_joinTestPath(tempPath, const ['Konyak.app']));
  File(_joinTestPath(appBundle.path, const ['Contents', 'MacOS', 'Konyak']))
    ..createSync(recursive: true)
    ..writeAsStringSync('app executable');
  File(
      _joinTestPath(appBundle.path, const [
        'Contents',
        'Resources',
        'konyak-cli',
      ]),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('cli executable');

  return appBundle;
}

List<Directory> _generatedMacosLaunchers(String home) {
  final launcherDirectory = Directory(
    _joinTestPath(home, const ['Applications', 'Konyak']),
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

Directory _singleGeneratedMacosLauncher(String home) {
  final launchers = _generatedMacosLaunchers(home);
  expect(launchers, hasLength(1));

  return launchers.single;
}

String _joinTestPath(String root, List<String> segments) {
  return <String>[root, ...segments].join('/');
}

Uint8List _syntheticPortableExecutableBytes() {
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
  const iconDataOffset = 0x100;
  final groupDataOffset = iconDataOffset + iconImage.length;
  final versionDataOffset = groupDataOffset + groupIcon.length;
  final resourceSize = versionDataOffset + versionInfo.length;
  final bytes = Uint8List(resourceRawOffset + resourceSize + 0x100);

  bytes[0] = 0x4d;
  bytes[1] = 0x5a;
  _writeU32(bytes, 0x3c, peOffset);
  bytes[peOffset] = 0x50;
  bytes[peOffset + 1] = 0x45;
  _writeU16(bytes, peOffset + 4, 0x8664);
  _writeU16(bytes, peOffset + 6, 1);
  _writeU16(bytes, peOffset + 20, 0xf0);
  _writeU16(bytes, peOffset + 24, 0x020b);
  _writeU32(bytes, peOffset + 24 + 128, resourceRva);
  _writeU32(bytes, peOffset + 24 + 132, resourceSize);

  _writeAscii(bytes, sectionHeaderOffset, '.rsrc');
  _writeU32(bytes, sectionHeaderOffset + 8, resourceSize);
  _writeU32(bytes, sectionHeaderOffset + 12, resourceRva);
  _writeU32(bytes, sectionHeaderOffset + 16, resourceSize);
  _writeU32(bytes, sectionHeaderOffset + 20, resourceRawOffset);

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

Uint8List _syntheticShellLinkBytes({required String localBasePath}) {
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

void _writeTestBottleMetadata(BottleRecord bottle) {
  File(_joinTestPath(bottle.path, const ['metadata.json']))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottle': bottle.toJson(),
      }),
    );
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
