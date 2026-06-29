import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/domain/program/program_run_command_support.dart';
import 'package:konyak_cli/src/io/io_result.dart';
import 'package:konyak_cli/src/io/runtime_catalog_factories_io.dart';
import 'package:konyak_cli/src/repository/memory_bottle_repository.dart';
import 'package:test/test.dart';

T _expectIo<T>(IoResult<T> result) {
  return result.fold((message) => throw TestFailure(message), (value) => value);
}

BottleRecord _expectFound(IoResult<Option<BottleRecord>> result) {
  return _expectIo(result).match(
    () => throw TestFailure('Expected bottle to exist.'),
    (bottle) => bottle,
  );
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
  Option<String> versionFor({
    required String runtimeRoot,
    required String componentId,
  }) {
    return const Option.none();
  }
}

void main() {
  test('bottle records expose immutable pinned program snapshots', () {
    final pinnedPrograms = <PinnedProgramRecord>[
      PinnedProgramRecord(name: 'Steam', path: '/steam.exe'),
    ];
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
      pinnedPrograms: pinnedPrograms,
    );
    pinnedPrograms.clear();

    expect(bottle.pinnedPrograms, hasLength(1));
    expect(bottle.id, BottleId('steam'));
    expect(bottle.name, BottleName('Steam'));
    expect(bottle.path, BottlePath('/bottles/steam'));
    expect(bottle.windowsVersion, WindowsVersion('win10'));
    expect(
      bottle.pinnedPrograms.add(
        PinnedProgramRecord(name: 'Other', path: '/other.exe'),
      ),
      hasLength(2),
    );
    expect(bottle.pinnedPrograms, hasLength(1));
  });

  test('bottle records reject blank required fields', () {
    BottleRecord validBottle() {
      return BottleRecord(
        id: 'steam',
        name: 'Steam',
        path: '/bottles/steam',
        windowsVersion: 'win10',
      );
    }

    expect(
      () => validBottle().withIdentity(
        id: BottleId(' '),
        name: BottleName('Steam'),
        path: BottlePath('/bottles/steam'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().withIdentity(
        id: BottleId('steam'),
        name: BottleName(' '),
        path: BottlePath('/bottles/steam'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().withPath(BottlePath(' ')),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().withWindowsVersion(WindowsVersion(' ')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('pinned program records reject blank required fields', () {
    expect(
      () => PinnedProgramRecord(name: ' ', path: '/steam.exe'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => PinnedProgramRecord(name: 'Steam', path: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => PinnedProgramRecord(
        name: 'Steam',
        path: '/steam.exe',
        iconPath: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('pinned program records model absent icons with Option', () {
    final withoutIcon = PinnedProgramRecord(name: 'Steam', path: '/steam.exe');
    final withIcon = withoutIcon.withIconPath(
      Option.of(ProgramIconPath('/steam.icns')),
    );
    final clearedIcon = withIcon.withIconPath(const Option.none());

    expect(withoutIcon.name, ProgramName('Steam'));
    expect(withoutIcon.path, ProgramPath('/steam.exe'));
    expect(withoutIcon.iconPath.isNone(), isTrue);
    expect(withIcon.iconPath.toNullable(), ProgramIconPath('/steam.icns'));
    expect(clearedIcon.iconPath.isNone(), isTrue);
  });

  test('runtime settings expose semantic value object fields', () {
    final settings = BottleRuntimeSettings(
      enhancedSync: 'msync',
      dxvkHud: 'off',
      buildVersion: 22631,
      dpiScaling: 144,
    );

    expect(settings.enhancedSync, EnhancedSyncMode('msync'));
    expect(settings.dxvkHud, DxvkHudMode('off'));
    expect(settings.buildVersion, WindowsBuildVersion(22631));
    expect(settings.dpiScaling, WindowsDpiScaling(144));
  });

  test('app settings expose default bottle path as a value object', () {
    final settings = AppSettingsRecord(defaultBottlePath: '/bottles');

    expect(settings.defaultBottlePath, DefaultBottlePath('/bottles'));
  });

  test('program metadata records model absent fields with Option', () {
    final emptyMetadata = ProgramMetadataRecord();
    final metadata = ProgramMetadataRecord(
      architecture: Option.of('x86_64'),
      fileDescription: Option.of('Steam'),
      iconPath: Option.of('/steam.icns'),
    );

    expect(emptyMetadata.isEmpty, isTrue);
    expect(emptyMetadata.iconPath.isNone(), isTrue);
    expect(metadata.isEmpty, isFalse);
    expect(metadata.architecture.toNullable(), ProgramArchitecture('x86_64'));
    expect(
      metadata.fileDescription.toNullable(),
      ProgramFileDescription('Steam'),
    );
    expect(metadata.iconPath.toNullable(), ProgramIconPath('/steam.icns'));
  });

  test('program metadata records reject blank present fields', () {
    expect(
      () => ProgramMetadataRecord(architecture: Option.of(' ')),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ProgramMetadataRecord(iconPath: Option.of(' ')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('program and process records model absent metadata with Option', () {
    final program = BottleProgramRecord(
      id: 'steam',
      name: 'Steam',
      path: '/steam.exe',
      source: 'pinned',
    );
    final process = WineProcessRecord(
      bottleId: 'steam',
      processId: '42',
      executable: 'steam.exe',
    );

    expect(program.metadata.isNone(), isTrue);
    expect(program.id, ProgramId('steam'));
    expect(program.name, ProgramName('Steam'));
    expect(program.path, ProgramPath('/steam.exe'));
    expect(program.source, ProgramSource('pinned'));
    expect(process.metadata.isNone(), isTrue);
    expect(process.bottleId, BottleId('steam'));
    expect(process.processId, WineProcessId('42'));
    expect(process.executable, ProgramExecutable('steam.exe'));
    expect(process.hostPath.isNone(), isTrue);
  });

  test('graphics backend hints expose immutable value records', () {
    final signals = <ProgramGraphicsBackendSignal>[
      ProgramGraphicsBackendSignal(kind: 'peImport', value: 'd3d11.dll'),
    ];
    final suggestions = <ProgramGraphicsBackendSuggestion>[
      ProgramGraphicsBackendSuggestion(
        backend: 'dxvk',
        confidence: 'high',
        reason: 'D3D11 API usage was detected.',
      ),
    ];
    final hints = ProgramGraphicsBackendHints(
      programPath: '/games/steam.exe',
      hostPlatform: KonyakHostPlatform.linux,
      signals: signals,
      suggestions: suggestions,
    );
    signals.add(ProgramGraphicsBackendSignal(kind: 'string', value: 'd3d12'));
    suggestions.clear();

    expect(hints.programPath, ProgramPath('/games/steam.exe'));
    expect(hints.hostPlatform, KonyakHostPlatform.linux);
    expect(hints.signals, [
      ProgramGraphicsBackendSignal(kind: 'peImport', value: 'd3d11.dll'),
    ]);
    expect(hints.suggestions, [
      ProgramGraphicsBackendSuggestion(
        backend: 'dxvk',
        confidence: 'high',
        reason: 'D3D11 API usage was detected.',
      ),
    ]);
  });

  test('runtime release metadata models absent fields with Option', () {
    final metadata = RuntimeReleaseMetadata(version: '1.0.0');

    expect(metadata.version, ReleaseVersion('1.0.0'));
    expect(metadata.archiveUrl.isNone(), isTrue);
    expect(metadata.archiveSha256.isNone(), isTrue);
    expect(metadata.sourceManifestUrl.isNone(), isTrue);
    expect(metadata.sourceManifestSignatureUrl.isNone(), isTrue);
  });

  test('runtime release metadata rejects blank present fields', () {
    expect(
      () => RuntimeReleaseMetadata(version: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () =>
          RuntimeReleaseMetadata(version: '1.0.0', archiveUrl: Option.of(' ')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime update records model absent fields with Option', () {
    final update = RuntimeUpdateRecord(runtimeId: 'wine', status: 'unknown');
    final available = RuntimeUpdateRecord(
      runtimeId: 'wine',
      status: 'available',
      currentVersion: Option.of('1.0.0'),
      latestVersion: Option.of('1.1.0'),
      archiveUrl: Option.of('https://example.invalid/wine.tar.xz'),
    );

    expect(update.currentVersion.isNone(), isTrue);
    expect(update.runtimeId, RuntimeId('wine'));
    expect(update.status, UpdateCheckStatus('unknown'));
    expect(update.archiveUrl.isNone(), isTrue);
    expect(available.currentVersion.toNullable(), RuntimeVersion('1.0.0'));
    expect(available.latestVersion.toNullable(), RuntimeVersion('1.1.0'));
    expect(
      available.archiveUrl.toNullable(),
      RuntimeArchiveUrl('https://example.invalid/wine.tar.xz'),
    );
  });

  test('runtime update records reject blank present fields', () {
    expect(
      () => RuntimeUpdateRecord(runtimeId: ' ', status: 'unknown'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeUpdateRecord(runtimeId: 'wine', status: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeUpdateRecord(
        runtimeId: 'wine',
        status: 'unknown',
        archiveUrl: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('app update records model absent fields with Option', () {
    final update = AppUpdateRecord(appId: 'konyak', status: 'unknown');

    expect(update.appId, AppId('konyak'));
    expect(update.status, UpdateCheckStatus('unknown'));
    expect(update.currentVersion.isNone(), isTrue);
    expect(update.latestVersion.isNone(), isTrue);
    expect(update.archiveUrl.isNone(), isTrue);
    expect(update.archiveSha256.isNone(), isTrue);
  });

  test('app update records reject blank present fields', () {
    expect(
      () => AppUpdateRecord(appId: ' ', status: 'unknown'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateRecord(appId: 'konyak', status: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateRecord(
        appId: 'konyak',
        status: 'unknown',
        archiveSha256: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('app update install records model absent fields with Option', () {
    final install = AppUpdateInstallRecord(appId: 'konyak', status: 'skipped');

    expect(install.appId, AppId('konyak'));
    expect(install.status, UpdateInstallStatus('skipped'));
    expect(install.currentVersion.isNone(), isTrue);
    expect(install.installedVersion.isNone(), isTrue);
    expect(install.archiveUrl.isNone(), isTrue);
    expect(install.archiveSha256.isNone(), isTrue);
    expect(install.installPath.isNone(), isTrue);
  });

  test('app update install records reject blank present fields', () {
    expect(
      () => AppUpdateInstallRecord(appId: ' ', status: 'skipped'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateInstallRecord(appId: 'konyak', status: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateInstallRecord(
        appId: 'konyak',
        status: 'installed',
        installPath: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('update records compare by semantic values', () {
    expect(
      RuntimeUpdateRecord(
        runtimeId: 'wine',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        sourceManifestUrl: Option.of('https://example.invalid/source.json'),
      ),
      RuntimeUpdateRecord(
        runtimeId: 'wine',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        sourceManifestUrl: Option.of('https://example.invalid/source.json'),
      ),
    );
    expect(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        archiveSha256: Option.of('abc123'),
      ),
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        archiveSha256: Option.of('abc123'),
      ),
    );
    expect(
      AppUpdateInstallRecord(
        appId: 'konyak',
        status: 'installed',
        installPath: Option.of('/Applications/Konyak.app'),
      ),
      AppUpdateInstallRecord(
        appId: 'konyak',
        status: 'installed',
        installPath: Option.of('/Applications/Konyak.app'),
      ),
    );
    expect(
      RuntimeReleaseMetadata(
        version: '1.0.0',
        sourceManifestSignatureUrl: Option.of(
          'https://example.invalid/source.json.sig',
        ),
      ),
      RuntimeReleaseMetadata(
        version: '1.0.0',
        sourceManifestSignatureUrl: Option.of(
          'https://example.invalid/source.json.sig',
        ),
      ),
    );
  });

  test('runtime release metadata fetch results compare by value', () {
    expect(
      RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: '1.0.0',
          sourceManifestUrl: Option.of('https://example.invalid/source.json'),
        ),
      ),
      RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: '1.0.0',
          sourceManifestUrl: Option.of('https://example.invalid/source.json'),
        ),
      ),
    );
    expect(
      const RuntimeReleaseMetadataFetchFailed('metadata unavailable'),
      const RuntimeReleaseMetadataFetchFailed('metadata unavailable'),
    );
  });

  test('app update results compare by value', () {
    expect(
      AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          latestVersion: Option.of('1.1.0'),
        ),
      ),
      AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          latestVersion: Option.of('1.1.0'),
        ),
      ),
    );
    expect(
      const AppUpdateCheckFailed('update metadata unavailable'),
      const AppUpdateCheckFailed('update metadata unavailable'),
    );
    expect(
      AppUpdateInstallCompleted(
        AppUpdateInstallRecord(appId: 'konyak', status: 'installed'),
      ),
      AppUpdateInstallCompleted(
        AppUpdateInstallRecord(appId: 'konyak', status: 'installed'),
      ),
    );
    expect(
      const AppUpdateInstallFailed('installer unavailable'),
      const AppUpdateInstallFailed('installer unavailable'),
    );
  });

  test('runtime update check results compare by value', () {
    expect(
      RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'wine',
          status: 'available',
          latestVersion: Option.of('1.1.0'),
        ),
      ),
      RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'wine',
          status: 'available',
          latestVersion: Option.of('1.1.0'),
        ),
      ),
    );
    expect(
      const RuntimeUpdateCheckFailed('runtime metadata unavailable'),
      const RuntimeUpdateCheckFailed('runtime metadata unavailable'),
    );
    expect(
      RuntimeUpdateCheckResult.runtimeNotFound('wine'),
      RuntimeUpdateCheckResult.runtimeNotFound('wine'),
    );
  });

  test('runtime install operations group install source as a domain value', () {
    final operation = RuntimeInstallRequestOperation.fullInstall();

    final source = operation.installSource;

    expect(source, isA<RuntimeConfiguredArchiveSource>());
    expect(source.hasExplicitInstallSource, isFalse);
  });

  test('runtime install operations model source manifest explicitly', () {
    final operation = RuntimeInstallRequestOperation.repair(
      sourceManifest: Option.of('https://example.invalid/source.json'),
      sourceManifestSignature: Option.of(
        'https://example.invalid/source.json.sig',
      ),
    );

    final source = operation.installSource;

    expect(source, isA<RuntimeSourceManifestInstallSource>());
    final manifestSource = source as RuntimeSourceManifestInstallSource;
    expect(
      manifestSource.sourceManifest,
      RuntimeSourceManifestUrl('https://example.invalid/source.json'),
    );
    expect(manifestSource.signature, isA<RuntimeSourceManifestSigned>());
  });

  test('runtime install operations expose immutable source snapshots', () {
    final componentArchivePaths = <String>['/dxvk.tar.gz'];
    final operation = RuntimeInstallRequestOperation.componentInstall(
      componentArchivePaths: componentArchivePaths,
    );
    componentArchivePaths.add('/vkd3d.tar.gz');

    expect(operation, isA<RuntimeComponentInstallOperation>());
    expect(operation.operation, RuntimeInstallOperation.componentInstall);
    expect(operation.force, isFalse);
    expect(operation.componentArchivePaths, [
      RuntimeArchivePath('/dxvk.tar.gz'),
    ]);
  });

  test('runtime install sources expose immutable archive path snapshots', () {
    final componentArchivePaths = <String>['/dxvk.tar.gz'];
    final configuredSource = RuntimeInstallSource.configuredArchive(
      componentArchivePaths: componentArchivePaths,
    );
    final localSource = RuntimeInstallSource.localArchive(
      archivePath: '/wine.tar.gz',
      componentArchivePaths: componentArchivePaths,
    );
    final remoteSource = RuntimeInstallSource.remoteArchive(
      archiveUrl: 'https://example.invalid/wine.tar.gz',
      componentArchivePaths: componentArchivePaths,
    );
    componentArchivePaths.add('/vkd3d.tar.gz');

    expect(
      switch (configuredSource) {
        RuntimeConfiguredArchiveSource(:final componentArchivePaths) =>
          componentArchivePaths,
        _ => throw TestFailure('Expected configured archive source.'),
      },
      [RuntimeArchivePath('/dxvk.tar.gz')],
    );
    expect(
      switch (localSource) {
        RuntimeLocalArchiveSource(:final componentArchivePaths) =>
          componentArchivePaths,
        _ => throw TestFailure('Expected local archive source.'),
      },
      [RuntimeArchivePath('/dxvk.tar.gz')],
    );
    expect(
      switch (remoteSource) {
        RuntimeRemoteArchiveSource(:final componentArchivePaths) =>
          componentArchivePaths,
        _ => throw TestFailure('Expected remote archive source.'),
      },
      [RuntimeArchivePath('/dxvk.tar.gz')],
    );
  });

  test('runtime install plans expose immutable archive path snapshots', () {
    final componentArchivePaths = <RuntimeArchivePath>[
      RuntimeArchivePath('/dxvk.tar.gz'),
    ];
    final localPlan = RuntimeWineInstallPlan.fromArchive(
      archivePath: RuntimeArchivePath('/wine.tar.gz'),
      archiveSha256: const RuntimeArchiveChecksum.absent(),
      componentArchivePaths: componentArchivePaths,
      preserveExistingRuntimeFiles: false,
    );
    final remotePlan = RuntimeWineInstallPlan.downloadArchive(
      archiveUrl: RuntimeArchiveUrl('https://example.invalid/wine.tar.gz'),
      archiveFileName: 'wine.tar.gz',
      archiveSha256: const RuntimeArchiveChecksum.absent(),
      componentArchivePaths: componentArchivePaths,
      preserveExistingRuntimeFiles: false,
    );
    componentArchivePaths.add(RuntimeArchivePath('/vkd3d.tar.gz'));

    expect(
      switch (localPlan) {
        RuntimeWineInstallFromArchive(:final componentArchivePaths) =>
          componentArchivePaths,
        _ => throw TestFailure('Expected local archive plan.'),
      },
      [RuntimeArchivePath('/dxvk.tar.gz')],
    );
    expect(
      switch (remotePlan) {
        RuntimeWineInstallDownloadArchive(:final componentArchivePaths) =>
          componentArchivePaths,
        _ => throw TestFailure('Expected remote archive plan.'),
      },
      [RuntimeArchivePath('/dxvk.tar.gz')],
    );
  });

  test('program path Wine arguments model unsupported paths with Option', () {
    expect(
      wineArgumentsForProgramPath(ProgramPath('/Games/setup.exe')).toNullable(),
      ProgramRunArguments(const <String>['/Games/setup.exe']),
    );
    expect(
      wineArgumentsForProgramPath(ProgramPath('/Games/readme.txt')).isNone(),
      isTrue,
    );
  });

  test('bottle commands model supported commands with BottleCommand', () {
    expect(
      supportedBottleCommand(BottleCommand(' WineCfg ')).toNullable(),
      BottleCommand('winecfg'),
    );
    expect(supportedBottleCommand(BottleCommand('notepad')).isNone(), isTrue);
    expect(wineArgumentsForBottleCommand(BottleCommand('dxdiag')), const <
      String
    >[
      'cmd',
      '/c',
      'dxdiag /t C:\\konyak-dxdiag.txt && start "" notepad C:\\konyak-dxdiag.txt',
    ]);
  });

  test('winetricks verbs model supported verbs with WinetricksVerbId', () {
    expect(isSupportedWinetricksVerb(WinetricksVerbId('corefonts')), isTrue);
    expect(
      isSupportedWinetricksVerb(WinetricksVerbId('corefonts;rm')),
      isFalse,
    );

    final request =
        ProgramRunPlanner(
              hostPlatform: KonyakHostPlatform.macos,
              environment: HostEnvironment({'HOME': '/Users/user'}),
            )
            .planWinetricksVerb(
              bottle: BottleRecord(
                id: 'steam',
                name: 'Steam',
                path:
                    '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
                windowsVersion: 'win10',
              ),
              verb: WinetricksVerbId('corefonts'),
            )
            .toNullable();

    expect(request?.programPath, ProgramPath('corefonts'));
    expect(
      request?.arguments,
      ProgramRunArguments(const <String>['corefonts']),
    );
  });

  test('Wine process kill plans model process ids with WineProcessId', () {
    expect(winedbgAttachProcessId(WineProcessId('000000d8')), '0x000000d8');
    expect(winedbgAttachProcessId(WineProcessId('0x000000d8')), '0x000000d8');

    final request =
        ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: const HostEnvironment.empty(),
        ).planWineProcessKill(
          bottle: BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: '/home/user/.local/share/konyak/Bottles/Steam',
            windowsVersion: 'win10',
          ),
          processId: WineProcessId('000000d8'),
        );

    expect(
      request.arguments,
      ProgramRunArguments(const <String>['--command', 'kill', '0x000000d8']),
    );
  });

  test('runtime install operations reject blank present sources', () {
    expect(
      () => RuntimeInstallRequestOperation.fullInstall(
        archivePath: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () =>
          RuntimeInstallRequestOperation.repair(sourceManifest: Option.of(' ')),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeInstallRequestOperation.updateInstall(
        archiveSha256: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('program settings expose immutable environment snapshots', () {
    final environment = <String, String>{'LANG': 'ja_JP.UTF-8'};
    final settings = ProgramSettingsRecord(
      environment: ProgramEnvironmentOverrides(environment),
      logging: Option.of(
        ProgramLoggingSettingsRecord(
          additionalWineLoggingChannels: ' +seh ',
          logFilePath: ' /tmp/steam.log ',
        ),
      ),
    );
    environment['LANG'] = 'en_US.UTF-8';

    expect(settings.locale, ProgramLocale(''));
    expect(settings.arguments, ProgramArguments(''));
    final logging = settings.logging.toNullable();
    expect(logging?.additionalWineLoggingChannels, WineDebugChannels('+seh'));
    expect(logging?.logFilePath, ProgramLogPath('/tmp/steam.log'));
    expect(settings.environment.toMap(), {'LANG': 'ja_JP.UTF-8'});
    expect(settings.environment.add('WINEDEBUG', '-all').toMap(), {
      'LANG': 'ja_JP.UTF-8',
      'WINEDEBUG': '-all',
    });
    expect(settings.environment.toMap(), {'LANG': 'ja_JP.UTF-8'});
  });

  test('program run environments expose immutable snapshots', () {
    final variables = <String, String>{'WINEPREFIX': '/bottles/steam'};
    final environment = ProgramRunEnvironment(variables);
    variables['WINEPREFIX'] = '/changed';

    expect(environment['WINEPREFIX'], Option.of('/bottles/steam'));
    expect(environment.toMap(), {'WINEPREFIX': '/bottles/steam'});
    expect(
      () => ProgramRunEnvironment(const <String, String>{' ': 'value'}),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ProgramRunEnvironment(const <String, String>{'A=B': 'value'}),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('program run requests expose semantic value object fields', () {
    final request = ProgramRunRequest(
      bottleId: BottleId('steam'),
      programPath: ProgramPath('/steam.exe'),
      runnerKind: RunnerKind('wine'),
      executable: ProgramExecutable('wine'),
      arguments: ProgramRunArguments(const <String>['/steam.exe']),
      environment: const ProgramRunEnvironment.empty(),
      logPath: ProgramLogPath('/bottles/steam/logs/latest.log'),
      workingDirectory: Option.of(ProgramWorkingDirectoryPath('/downloads')),
    );

    expect(request.bottleId, BottleId('steam'));
    expect(request.programPath, ProgramPath('/steam.exe'));
    expect(request.runnerKind, RunnerKind('wine'));
    expect(request.executable, ProgramExecutable('wine'));
    expect(request.logPath, ProgramLogPath('/bottles/steam/logs/latest.log'));
    expect(
      request.workingDirectory.toNullable(),
      ProgramWorkingDirectoryPath('/downloads'),
    );
    expect(request.argv, ['wine', '/steam.exe']);
  });

  test('host environments expose immutable snapshots', () {
    final variables = <String, String>{'HOME': '/Users/user'};
    final environment = HostEnvironment(variables);
    variables['HOME'] = '/changed';

    expect(environment['HOME'], Option.of('/Users/user'));
    expect(environment.nonEmptyValue('HOME'), Option.of('/Users/user'));
    expect(environment.toMap(), {'HOME': '/Users/user'});
    expect(
      HostEnvironment(const <String, String>{
        'EMPTY': ' ',
      }).nonEmptyValue('EMPTY'),
      const Option<String>.none(),
    );
    expect(
      () => HostEnvironment(const <String, String>{' ': 'value'}),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => HostEnvironment(const <String, String>{'A=B': 'value'}),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime catalogs expose immutable host environment snapshots', () {
    final variables = <String, String>{
      'KONYAK_RUNTIME_PROFILE': 'development',
      'XDG_DATA_HOME': '/home/user/.local/share',
    };
    final catalog = KonyakRuntimeCatalog(
      hostPlatform: KonyakHostPlatform.linux,
      environment: HostEnvironment(variables),
      fileStatusProbe: const StaticFileStatusProbe({
        '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
      }),
      runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
    );
    variables['KONYAK_RUNTIME_PROFILE'] = 'managed';

    final runtime = catalog.listRuntimes().single;

    expect(
      runtime.distributionKind.toNullable(),
      RuntimeDistributionKind('development'),
    );
  });

  test('process termination records expose immutable argv snapshots', () {
    final argv = <String>['wine', '/steam.exe'];
    final record = WineProcessTerminationRecord(
      bottleId: 'steam',
      status: 'terminated',
      runnerKind: 'wine',
      executable: 'wine',
      argv: argv,
    );
    argv.add('--changed');

    expect(record.bottleId, BottleId('steam'));
    expect(record.status, WineProcessStatus('terminated'));
    expect(record.runnerKind, RunnerKind('wine'));
    expect(record.executable, ProgramExecutable('wine'));
    expect(record.argv, ['wine', '/steam.exe']);
    expect(() => record.argv.add('--other'), throwsUnsupportedError);
  });

  test(
    'runtime package install requests expose immutable collection snapshots',
    () {
      final componentArchivePaths = <String>['/dxvk.tar.gz'];
      final componentVersions = <String, String>{'dxvk': '2.7'};
      final requiredExecutableRelativePath = <String>['bin', 'wine'];
      final request = RuntimePackageInstallRequest(
        runtimeLabel: 'Konyak Wine',
        archivePath: '/wine.tar.gz',
        archiveSha256: const Option.none(),
        componentArchivePaths: componentArchivePaths,
        componentVersions: RuntimeComponentVersions(componentVersions),
        runtimeRoot: '/tmp/konyak-runtime',
        requiredExecutableRelativePath: requiredExecutableRelativePath,
        expectedExecutablePath: '/tmp/konyak-runtime/bin/wine',
      );
      componentArchivePaths.clear();
      componentVersions['dxvk'] = 'changed';
      requiredExecutableRelativePath.add('changed');

      expect(request.archivePath, RuntimeArchivePath('/wine.tar.gz'));
      expect(request.componentArchivePaths, [
        RuntimeArchivePath('/dxvk.tar.gz'),
      ]);
      expect(request.componentVersions.toMap(), {'dxvk': '2.7'});
      expect(request.runtimeRoot, RuntimeRootPath('/tmp/konyak-runtime'));
      expect(
        request.requiredExecutableRelativePath,
        RuntimeRelativePath(['bin', 'wine']),
      );
      expect(
        request.expectedExecutablePath,
        RuntimeComponentPath('/tmp/konyak-runtime/bin/wine'),
      );
      expect(
        request.componentArchivePaths.add(RuntimeArchivePath('/vkd3d.tar.gz')),
        [
          RuntimeArchivePath('/dxvk.tar.gz'),
          RuntimeArchivePath('/vkd3d.tar.gz'),
        ],
      );
      expect(request.componentArchivePaths, [
        RuntimeArchivePath('/dxvk.tar.gz'),
      ]);
      expect(request.componentVersions.add('vkd3d', '2.14').toMap(), {
        'dxvk': '2.7',
        'vkd3d': '2.14',
      });
      expect(request.componentVersions.toMap(), {'dxvk': '2.7'});
      expect(
        request.requiredExecutableRelativePath.components.clear,
        throwsUnsupportedError,
      );
    },
  );

  test(
    'runtime package install requests model absent checksums with Option',
    () {
      final request = RuntimePackageInstallRequest(
        runtimeLabel: 'Konyak Wine',
        archivePath: '/wine.tar.gz',
        archiveSha256: const Option.none(),
        componentArchivePaths: const <String>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: '/tmp/konyak-runtime',
        requiredExecutableRelativePath: const <String>['bin', 'wine'],
        expectedExecutablePath: '/tmp/konyak-runtime/bin/wine',
      );

      expect(request.archiveSha256.isNone(), isTrue);
    },
  );

  test('runtime package install requests reject blank required values', () {
    expect(
      () => RuntimePackageInstallRequest(
        runtimeLabel: ' ',
        archivePath: '/wine.tar.gz',
        archiveSha256: const Option.none(),
        componentArchivePaths: const <String>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: '/tmp/konyak-runtime',
        requiredExecutableRelativePath: const <String>['bin', 'wine'],
        expectedExecutablePath: '/tmp/konyak-runtime/bin/wine',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimePackageInstallRequest(
        runtimeLabel: 'Konyak Wine',
        archivePath: '/wine.tar.gz',
        archiveSha256: Option.of(' '),
        componentArchivePaths: const <String>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: '/tmp/konyak-runtime',
        requiredExecutableRelativePath: const <String>['bin', 'wine'],
        expectedExecutablePath: '/tmp/konyak-runtime/bin/wine',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime stack components model absent versions with Option', () {
    final component = RuntimeStackComponent(
      id: 'wine',
      name: 'Wine',
      role: 'runner',
      isRequired: true,
      paths: const <String>['/runtime/bin/wine'],
      missingPaths: const <String>[],
    );

    expect(component.id, RuntimeComponentId('wine'));
    expect(component.name, RuntimeName('Wine'));
    expect(component.role, RuntimeRole('runner'));
    expect(component.paths, [RuntimeComponentPath('/runtime/bin/wine')]);
    expect(component.version.isNone(), isTrue);
    expect(component.isInstalled, isTrue);
  });

  test('runtime stack components reject blank present versions', () {
    expect(
      () => RuntimeStackComponent(
        id: 'wine',
        name: 'Wine',
        role: 'runner',
        isRequired: true,
        paths: const <String>['/runtime/bin/wine'],
        missingPaths: const <String>[],
        version: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime source manifests model missing components with Option', () {
    final manifest = RuntimeSourceManifest(
      runtimeId: 'wine',
      stackId: 'konyak',
      components: <RuntimeSourceComponent>[
        RuntimeSourceComponent(
          id: 'wine',
          version: '1.0.0',
          archiveUrl: 'https://example.invalid/wine.tar.xz',
          sha256: 'digest',
        ),
      ],
    );

    expect(manifest.runtimeId, RuntimeId('wine'));
    expect(manifest.stackId, RuntimeStackId('konyak'));
    expect(
      manifest.componentById('wine').toNullable()?.id,
      RuntimeSourceComponentId('wine'),
    );
    expect(manifest.componentById('dxvk').isNone(), isTrue);
  });

  test('runtime source archive plans report missing source components', () {
    final wineComponent = RuntimeSourceComponent(
      id: 'wine',
      version: '1.0.0',
      archiveUrl: 'https://example.invalid/wine.tar.xz',
      sha256: 'wine-digest',
    );
    final dxvkComponent = RuntimeSourceComponent(
      id: 'dxvk',
      version: '2.0.0',
      archiveUrl: 'https://example.invalid/dxvk.tar.xz',
      sha256: 'dxvk-digest',
    );
    final plan = RuntimeStackSourceArchivePlan(
      wineComponent: wineComponent,
      sourceComponents: <RuntimeSourceComponent>[wineComponent],
      components: <RuntimeStackSourceArchiveComponentPlan>[
        RuntimeStackSourceArchiveComponentPlan(
          component: dxvkComponent,
          archivePath: '/tmp/dxvk.tar.xz',
          startFraction: 0.05,
          endFraction: 0.6,
        ),
      ],
    );

    final bundleResult = plan.toBundle();

    expect(bundleResult, isA<RuntimeStackSourceArchiveBundleFailed>());
    expect(
      (bundleResult as RuntimeStackSourceArchiveBundleFailed).message,
      contains('wine'),
    );
  });

  test('runtime definitions model absent source URLs with Option', () {
    final definition = RuntimeDefinition(
      id: 'konyak-linux-wine',
      name: 'Konyak Linux Wine',
      platform: 'linux',
      architecture: 'x86_64',
      runnerKind: 'wine',
      isBundled: false,
      isUpdateable: true,
    );

    expect(definition.id, RuntimeId('konyak-linux-wine'));
    expect(definition.name, RuntimeName('Konyak Linux Wine'));
    expect(definition.platform, RuntimePlatformName('linux'));
    expect(definition.architecture, RuntimeArchitecture('x86_64'));
    expect(definition.runnerKind, RunnerKind('wine'));
    expect(definition.distributionKind.isNone(), isTrue);
    expect(definition.archiveUrl.isNone(), isTrue);
    expect(definition.versionUrl.isNone(), isTrue);
  });

  test('runtime definitions reject blank present source URLs', () {
    expect(
      () => RuntimeDefinition(
        id: 'konyak-linux-wine',
        name: 'Konyak Linux Wine',
        platform: 'linux',
        architecture: 'x86_64',
        runnerKind: 'wine',
        isBundled: false,
        isUpdateable: true,
        archiveUrl: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('installed runtime states model absent layout paths with Option', () {
    final state = InstalledRuntimeState(isInstalled: Option.of(false));
    const unknown = InstalledRuntimeState.unknown();

    expect(state.isInstalled.toNullable(), isFalse);
    expect(state.applicationSupportPath.isNone(), isTrue);
    expect(state.libraryPath.isNone(), isTrue);
    expect(state.executablePath.isNone(), isTrue);
    expect(unknown.isInstalled.isNone(), isTrue);
  });

  test('installed runtime states reject blank present layout paths', () {
    expect(
      () => InstalledRuntimeState(
        isInstalled: Option.of(true),
        executablePath: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime records model absent state with Option', () {
    final runtime = RuntimeRecord(
      id: 'wine',
      name: 'Wine',
      platform: 'linux',
      architecture: 'x86_64',
      runnerKind: 'wine',
      isBundled: false,
      isUpdateable: true,
    );

    expect(runtime.id, RuntimeId('wine'));
    expect(runtime.name, RuntimeName('Wine'));
    expect(runtime.platform, RuntimePlatformName('linux'));
    expect(runtime.architecture, RuntimeArchitecture('x86_64'));
    expect(runtime.runnerKind, RunnerKind('wine'));
    expect(runtime.distributionKind.isNone(), isTrue);
    expect(runtime.isInstalled.isNone(), isTrue);
    expect(runtime.libraryPath.isNone(), isTrue);
    expect(runtime.executablePath.isNone(), isTrue);
    expect(runtime.archiveUrl.isNone(), isTrue);
    expect(runtime.versionUrl.isNone(), isTrue);
    expect(runtime.stack.isNone(), isTrue);
  });

  test('runtime records reject blank present state fields', () {
    expect(
      () => RuntimeRecord(
        id: 'wine',
        name: 'Wine',
        platform: 'linux',
        architecture: 'x86_64',
        runnerKind: 'wine',
        isBundled: false,
        isUpdateable: true,
        executablePath: Option.of(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('static catalogs expose immutable snapshots', () {
    final bottles = <BottleRecord>[
      BottleRecord(
        id: 'steam',
        name: 'Steam',
        path: '/bottles/steam',
        windowsVersion: 'win10',
      ),
    ];
    final bottleCatalog = StaticBottleCatalog(bottles);
    bottles.clear();

    expect(_expectIo(bottleCatalog.listBottles()), hasLength(1));
    expect(_expectFound(bottleCatalog.findBottle('steam')), isNotNull);
    expect(
      _expectIo(bottleCatalog.listBottles()).clear,
      throwsUnsupportedError,
    );

    final runtimes = <RuntimeRecord>[
      RuntimeRecord(
        id: 'wine',
        name: 'Wine',
        platform: 'linux',
        architecture: 'x86_64',
        runnerKind: 'wine',
        isBundled: false,
        isUpdateable: true,
      ),
    ];
    final runtimeCatalog = StaticRuntimeCatalog(runtimes);
    runtimes.clear();

    expect(runtimeCatalog.listRuntimes(), hasLength(1));
    expect(runtimeCatalog.listRuntimes().clear, throwsUnsupportedError);
  });
}
