import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/domain/program/program_run_command_support.dart';
import 'package:konyak_cli/src/domain/program/program_run_terminal_requests.dart';
import 'package:konyak_cli/src/io/io_result.dart';
import 'package:konyak_cli/src/io/runtime_catalog_factories_io.dart';
import 'package:konyak_cli/src/platform/platform_location_paths.dart';
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
  Option<RuntimeVersion> versionFor({
    required RuntimeRootPath runtimeRoot,
    required RuntimeComponentId componentId,
  }) {
    return const Option.none();
  }
}

final class RecordingDomainDetachedProcessStarter
    implements DetachedProcessStarter {
  ProgramExecutable? executable;
  ProgramRunArguments? arguments;

  @override
  DetachedProcessStartResult start({
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
  }) {
    this.executable = executable;
    this.arguments = arguments;

    return const DetachedProcessStartCompleted();
  }
}

final class RecordingDomainPathOpener implements PathOpener {
  PathOpenTarget? openedTarget;
  PathRevealTarget? revealedTarget;

  @override
  PathOpenResult openPath(PathOpenTarget target) {
    openedTarget = target;

    return const PathOpenCompleted();
  }

  @override
  PathOpenResult revealPath(PathRevealTarget target) {
    revealedTarget = target;

    return const PathOpenCompleted();
  }
}

final class RecordingDomainRuntimeExecutableProbe
    implements RuntimeExecutableProbe {
  ProgramExecutable? executable;
  ProgramRunArguments? arguments;
  ProgramRunEnvironment? environment;
  ProgramWorkingDirectoryPath? workingDirectory;

  @override
  RuntimeExecutableProbeResult run({
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
    required ProgramRunEnvironment environment,
    required ProgramWorkingDirectoryPath workingDirectory,
  }) {
    this.executable = executable;
    this.arguments = arguments;
    this.environment = environment;
    this.workingDirectory = workingDirectory;

    return const RuntimeExecutableProbeResult(
      exitCode: 0,
      stdout: 'wine-11.9',
      stderr: '',
    );
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
      () => validBottle().copyWith(
        id: BottleId(' '),
        name: BottleName('Steam'),
        path: BottlePath('/bottles/steam'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().copyWith(
        id: BottleId('steam'),
        name: BottleName(' '),
        path: BottlePath('/bottles/steam'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().copyWith(path: BottlePath(' ')),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().copyWith(windowsVersion: WindowsVersion(' ')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('bottle records copyWith preserves semantic value object fields', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
    );
    final updated = bottle.copyWith(
      id: BottleId('steam-new'),
      name: BottleName('Steam New'),
      path: BottlePath('/bottles/steam-new'),
      windowsVersion: WindowsVersion('win11'),
      runtimeSettings: BottleRuntimeSettings(dxvk: true),
      pinnedPrograms: [
        PinnedProgramRecord(name: 'Steam', path: '/steam.exe'),
      ].toIList(),
    );

    expect(
      updated,
      BottleRecord(
        id: 'steam-new',
        name: 'Steam New',
        path: '/bottles/steam-new',
        windowsVersion: 'win11',
        runtimeSettings: Option.of(BottleRuntimeSettings(dxvk: true)),
        pinnedPrograms: [
          PinnedProgramRecord(name: 'Steam', path: '/steam.exe'),
        ],
      ),
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
    final withIcon = withoutIcon.copyWith(
      iconPath: Option.of(ProgramIconPath('/steam.icns')),
    );
    final clearedIcon = withIcon.copyWith(iconPath: const Option.none());

    expect(withoutIcon.name, ProgramName('Steam'));
    expect(withoutIcon.path, ProgramPath('/steam.exe'));
    expect(withoutIcon.iconPath.isNone(), isTrue);
    expect(withIcon.iconPath.toNullable(), ProgramIconPath('/steam.icns'));
    expect(clearedIcon.iconPath.isNone(), isTrue);
  });

  test('pinned program records copyWith preserves semantic fields', () {
    final program = PinnedProgramRecord(name: 'Steam', path: '/steam.exe');
    final updated = program.copyWith(
      name: ProgramName('Steam New'),
      path: ProgramPath('/steam-new.exe'),
      removable: true,
      iconPath: Option.of(ProgramIconPath('/steam.icns')),
    );

    expect(
      updated,
      PinnedProgramRecord(
        name: 'Steam New',
        path: '/steam-new.exe',
        removable: true,
        iconPath: Option.of('/steam.icns'),
      ),
    );
  });

  test('pinned program lookups use semantic program paths', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
      pinnedPrograms: [
        PinnedProgramRecord(name: 'Steam', path: '/games/steam.exe'),
      ],
    );

    expect(hasPinnedProgram(bottle, ProgramPath('/games/steam.exe')), isTrue);
    expect(hasPinnedProgram(bottle, ProgramPath('/games/other.exe')), isFalse);
  });

  test('registry update plans use semantic Windows versions', () {
    final updates = windowsVersionRegistryUpdates(WindowsVersion('win10'));

    expect(updates, hasLength(1));
    expect(updates.single.data, ProgramRegistryValueData('win10'));
  });

  test('bottle mutation request records compare by semantic values', () {
    expect(
      BottleCreateRequest(
        name: BottleName('Steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
      BottleCreateRequest(
        name: BottleName('Steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );
    expect(
      BottleArchiveExportRequest(
        bottleId: BottleId('steam'),
        archivePath: BottleArchivePath('/archives/steam.tar'),
      ),
      BottleArchiveExportRequest(
        bottleId: BottleId('steam'),
        archivePath: BottleArchivePath('/archives/steam.tar'),
      ),
    );
    expect(
      BottleArchiveImportRequest(
        archivePath: BottleArchivePath('/archives/steam.tar'),
      ),
      BottleArchiveImportRequest(
        archivePath: BottleArchivePath('/archives/steam.tar'),
      ),
    );
    expect(
      BottleArchiveRecord(
        bottleId: BottleId('steam'),
        archivePath: BottleArchivePath('/archives/steam.tar'),
      ),
      BottleArchiveRecord(
        bottleId: BottleId('steam'),
        archivePath: BottleArchivePath('/archives/steam.tar'),
      ),
    );
    expect(
      BottleRenameRequest(
        bottleId: BottleId('steam'),
        name: BottleName('Steam'),
      ),
      BottleRenameRequest(
        bottleId: BottleId('steam'),
        name: BottleName('Steam'),
      ),
    );
    expect(
      BottleMoveRequest(
        bottleId: BottleId('steam'),
        path: BottlePath('/bottles/steam'),
      ),
      BottleMoveRequest(
        bottleId: BottleId('steam'),
        path: BottlePath('/bottles/steam'),
      ),
    );
    expect(
      WindowsVersionUpdateRequest(
        bottleId: BottleId('steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
      WindowsVersionUpdateRequest(
        bottleId: BottleId('steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );
    expect(
      RuntimeSettingsUpdateRequest(
        bottleId: BottleId('steam'),
        runtimeSettings: BottleRuntimeSettings(dxvk: true),
      ),
      RuntimeSettingsUpdateRequest(
        bottleId: BottleId('steam'),
        runtimeSettings: BottleRuntimeSettings(dxvk: true),
      ),
    );
  });

  test('bottle mutation result records compare by semantic values', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
    );
    final archive = BottleArchiveRecord(
      bottleId: BottleId('steam'),
      archivePath: BottleArchivePath('/archives/steam.tar'),
    );

    expect(BottleCreated(bottle), BottleCreated(bottle));
    expect(
      BottleCreateConflict(BottleId('steam')),
      BottleCreateConflict(BottleId('steam')),
    );
    expect(BottleCreateFailed('failed'), BottleCreateFailed('failed'));
    expect(BottleArchiveExported(archive), BottleArchiveExported(archive));
    expect(
      BottleArchiveExportMissing(BottleId('steam')),
      BottleArchiveExportMissing(BottleId('steam')),
    );
    expect(
      BottleArchiveExportFailed('failed'),
      BottleArchiveExportFailed('failed'),
    );
    expect(BottleArchiveImported(bottle), BottleArchiveImported(bottle));
    expect(
      BottleArchiveImportConflict(BottleId('steam')),
      BottleArchiveImportConflict(BottleId('steam')),
    );
    expect(
      BottleArchiveImportFailed('failed'),
      BottleArchiveImportFailed('failed'),
    );
    expect(BottleDeleted(bottle), BottleDeleted(bottle));
    expect(
      BottleDeleteMissing(BottleId('steam')),
      BottleDeleteMissing(BottleId('steam')),
    );
    expect(BottleDeleteFailed('failed'), BottleDeleteFailed('failed'));
    expect(BottleRenamed(bottle), BottleRenamed(bottle));
    expect(
      BottleRenameMissing(BottleId('steam')),
      BottleRenameMissing(BottleId('steam')),
    );
    expect(
      BottleRenameConflict(BottleId('steam')),
      BottleRenameConflict(BottleId('steam')),
    );
    expect(BottleRenameFailed('failed'), BottleRenameFailed('failed'));
    expect(BottleMoved(bottle), BottleMoved(bottle));
    expect(
      BottleMoveMissing(BottleId('steam')),
      BottleMoveMissing(BottleId('steam')),
    );
    expect(
      BottleMoveConflict(BottlePath('/bottles/steam')),
      BottleMoveConflict(BottlePath('/bottles/steam')),
    );
    expect(BottleMoveFailed('failed'), BottleMoveFailed('failed'));
    expect(BottleUpdated(bottle), BottleUpdated(bottle));
    expect(
      BottleUpdateMissing(BottleId('steam')),
      BottleUpdateMissing(BottleId('steam')),
    );
    expect(BottleUpdateFailed('failed'), BottleUpdateFailed('failed'));
  });

  test('runtime settings expose semantic value object fields', () {
    final settings = BottleRuntimeSettings(
      enhancedSync: EnhancedSyncMode('msync'),
      dxvkHud: DxvkHudMode('off'),
      buildVersion: WindowsBuildVersion(22631),
      dpiScaling: WindowsDpiScaling(144),
    );

    expect(settings.enhancedSync, EnhancedSyncMode('msync'));
    expect(settings.dxvkHud, DxvkHudMode('off'));
    expect(settings.buildVersion, WindowsBuildVersion(22631));
    expect(settings.dpiScaling, WindowsDpiScaling(144));
  });

  test('runtime settings copyWith preserves semantic value object fields', () {
    final settings = BottleRuntimeSettings(dxrEnabled: true, dxmt: true);
    final updated = settings.copyWith(
      enhancedSync: EnhancedSyncMode('none'),
      dxvkHud: DxvkHudMode('fps'),
      buildVersion: WindowsBuildVersion(22631),
      dpiScaling: WindowsDpiScaling(144),
    );
    final esync = settings.withEnhancedSync(EnhancedSyncMode('esync'));
    final hud = settings.withDxvkHud(DxvkHudMode('partial'));
    final dxvk = settings.withDxvk(true);

    expect(
      updated,
      BottleRuntimeSettings(
        enhancedSync: EnhancedSyncMode('none'),
        dxrEnabled: true,
        dxmt: true,
        dxvkHud: DxvkHudMode('fps'),
        buildVersion: WindowsBuildVersion(22631),
        dpiScaling: WindowsDpiScaling(144),
      ),
    );
    expect(esync.enhancedSync, EnhancedSyncMode('esync'));
    expect(hud.dxvkHud, DxvkHudMode('partial'));
    expect(dxvk.dxvk, isTrue);
    expect(dxvk.dxmt, isFalse);
    expect(dxvk.dxrEnabled, isFalse);
  });

  test('bottle location paths use semantic value objects', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
    );

    expect(
      bottleLocationPath(bottle: bottle, location: BottleLocation('c-drive')),
      Option.of('/bottles/steam/drive_c'),
    );
    expect(
      bottleLocationPath(bottle: bottle, location: BottleLocation('logs')),
      const Option<String>.none(),
    );
  });

  test('program location paths use semantic value objects', () {
    expect(
      programLocationPath(ProgramPath('/games/Steam/steam.exe')),
      '/games/Steam',
    );
    expect(programLocationPath(ProgramPath('steam.exe')), 'steam.exe');
  });

  test('app settings expose default bottle path as a value object', () {
    final settings = AppSettingsRecord(
      defaultBottlePath: DefaultBottlePath('/bottles'),
    );

    expect(settings.defaultBottlePath, DefaultBottlePath('/bottles'));
  });

  test('app settings copyWith preserves semantic value object fields', () {
    final settings = AppSettingsRecord(
      defaultBottlePath: DefaultBottlePath('/bottles'),
    );
    final updated = settings.copyWith(
      terminateWineProcessesOnClose: true,
      defaultBottlePath: DefaultBottlePath('/library'),
      appearanceMode: AppAppearanceMode.system,
      languageMode: AppLanguageMode.japanese,
      automaticallyCheckForKonyakUpdates: true,
      automaticallyCheckForWineUpdates: false,
      automaticallyPinNewInstalledPrograms: false,
    );

    expect(settings.defaultBottlePath, DefaultBottlePath('/bottles'));
    expect(
      updated,
      AppSettingsRecord(
        terminateWineProcessesOnClose: true,
        defaultBottlePath: DefaultBottlePath('/library'),
        appearanceMode: AppAppearanceMode.system,
        languageMode: AppLanguageMode.japanese,
        automaticallyCheckForKonyakUpdates: true,
        automaticallyCheckForWineUpdates: false,
        automaticallyPinNewInstalledPrograms: false,
      ),
    );
  });

  test('program metadata records model absent fields with Option', () {
    final emptyMetadata = ProgramMetadataRecord();
    final metadata = ProgramMetadataRecord(
      architecture: Option.of(ProgramArchitecture('x86_64')),
      fileDescription: Option.of(ProgramFileDescription('Steam')),
      iconPath: Option.of(ProgramIconPath('/steam.icns')),
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
      () => ProgramMetadataRecord(
        architecture: Option.of(ProgramArchitecture(' ')),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ProgramMetadataRecord(iconPath: Option.of(ProgramIconPath(' '))),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('program and process records model absent metadata with Option', () {
    final program = BottleProgramRecord(
      id: ProgramId('steam'),
      name: ProgramName('Steam'),
      path: ProgramPath('/steam.exe'),
      source: ProgramSource('pinned'),
    );
    final process = WineProcessRecord(
      bottleId: BottleId('steam'),
      processId: WineProcessId('42'),
      executable: ProgramExecutable('steam.exe'),
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

  test('program catalog records compare by semantic values', () {
    expect(
      ProgramMetadataRecord(
        architecture: Option.of(ProgramArchitecture('x86_64')),
        fileDescription: Option.of(ProgramFileDescription('Steam')),
        iconPath: Option.of(ProgramIconPath('/steam.icns')),
      ),
      ProgramMetadataRecord(
        architecture: Option.of(ProgramArchitecture('x86_64')),
        fileDescription: Option.of(ProgramFileDescription('Steam')),
        iconPath: Option.of(ProgramIconPath('/steam.icns')),
      ),
    );
    expect(
      BottleProgramRecord(
        id: ProgramId('steam'),
        name: ProgramName('Steam'),
        path: ProgramPath('/steam.exe'),
        source: ProgramSource('pinned'),
        metadata: Option.of(
          ProgramMetadataRecord(iconPath: Option.of(ProgramIconPath('/i'))),
        ),
      ),
      BottleProgramRecord(
        id: ProgramId('steam'),
        name: ProgramName('Steam'),
        path: ProgramPath('/steam.exe'),
        source: ProgramSource('pinned'),
        metadata: Option.of(
          ProgramMetadataRecord(iconPath: Option.of(ProgramIconPath('/i'))),
        ),
      ),
    );
    expect(
      WineProcessRecord(
        bottleId: BottleId('steam'),
        processId: WineProcessId('42'),
        executable: ProgramExecutable('steam.exe'),
        hostPath: Option.of(ProgramPath('/steam.exe')),
      ),
      WineProcessRecord(
        bottleId: BottleId('steam'),
        processId: WineProcessId('42'),
        executable: ProgramExecutable('steam.exe'),
        hostPath: Option.of(ProgramPath('/steam.exe')),
      ),
    );
  });

  test('registry value records compare by semantic values', () {
    expect(
      RegistryValueUpdate(
        key: ProgramRegistryKey(r'HKCU\Software\Wine'),
        name: ProgramRegistryValueName('Version'),
        type: ProgramRegistryValueType('REG_SZ'),
        data: ProgramRegistryValueData('win10'),
      ),
      RegistryValueUpdate(
        key: ProgramRegistryKey(r'HKCU\Software\Wine'),
        name: ProgramRegistryValueName('Version'),
        type: ProgramRegistryValueType('REG_SZ'),
        data: ProgramRegistryValueData('win10'),
      ),
    );
    expect(
      RegistryValueQuery(
        key: ProgramRegistryKey(r'HKCU\Software\Wine'),
        name: ProgramRegistryValueName('Version'),
      ),
      RegistryValueQuery(
        key: ProgramRegistryKey(r'HKCU\Software\Wine'),
        name: ProgramRegistryValueName('Version'),
      ),
    );
  });

  test('winetricks catalog records expose immutable value snapshots', () {
    final verbs = <WinetricksVerbRecord>[
      WinetricksVerbRecord(
        id: WinetricksVerbId('corefonts'),
        name: WinetricksVerbName('corefonts'),
        description: WinetricksVerbDescription('install core fonts'),
      ),
    ];
    final category = WinetricksCategoryRecord(
      id: WinetricksCategoryId('fonts'),
      name: WinetricksCategoryName('Fonts'),
      verbs: verbs,
    );
    verbs.clear();

    expect(category.id, WinetricksCategoryId('fonts'));
    expect(category.verbs, hasLength(1));
    expect(category.verbs.single.id, WinetricksVerbId('corefonts'));
    expect(
      () => category.verbs.add(
        WinetricksVerbRecord(
          id: WinetricksVerbId('allfonts'),
          name: WinetricksVerbName('allfonts'),
          description: WinetricksVerbDescription('install all fonts'),
        ),
      ),
      throwsUnsupportedError,
    );
    expect(
      WinetricksVerbRecord(
        id: WinetricksVerbId('corefonts'),
        name: WinetricksVerbName('corefonts'),
        description: WinetricksVerbDescription('install core fonts'),
      ),
      WinetricksVerbRecord(
        id: WinetricksVerbId('corefonts'),
        name: WinetricksVerbName('corefonts'),
        description: WinetricksVerbDescription('install core fonts'),
      ),
    );
    expect(
      category,
      WinetricksCategoryRecord(
        id: WinetricksCategoryId('fonts'),
        name: WinetricksCategoryName('Fonts'),
        verbs: <WinetricksVerbRecord>[
          WinetricksVerbRecord(
            id: WinetricksVerbId('corefonts'),
            name: WinetricksVerbName('corefonts'),
            description: WinetricksVerbDescription('install core fonts'),
          ),
        ],
      ),
    );
  });

  test('winetricks verb list results compare by value', () {
    WinetricksCategoryRecord fontsCategory() {
      return WinetricksCategoryRecord(
        id: WinetricksCategoryId('fonts'),
        name: WinetricksCategoryName('Fonts'),
        verbs: <WinetricksVerbRecord>[
          WinetricksVerbRecord(
            id: WinetricksVerbId('corefonts'),
            name: WinetricksVerbName('corefonts'),
            description: WinetricksVerbDescription('install core fonts'),
          ),
        ],
      );
    }

    final categories = <WinetricksCategoryRecord>[fontsCategory()];
    final result = WinetricksVerbListResult.completed(categories: categories);
    categories.clear();
    final resultCategories = switch (result) {
      WinetricksVerbListCompleted(:final categories) => categories,
      WinetricksVerbListFailed() => fail('Expected completed result.'),
    };

    expect(resultCategories, hasLength(1));
    expect(
      result,
      WinetricksVerbListResult.completed(
        categories: <WinetricksCategoryRecord>[fontsCategory()],
      ),
    );
    expect(
      WinetricksVerbListResult.failed('missing winetricks'),
      WinetricksVerbListResult.failed('missing winetricks'),
    );
  });

  test('graphics backend hints expose immutable value records', () {
    final signals = <ProgramGraphicsBackendSignal>[
      ProgramGraphicsBackendSignal(
        kind: GraphicsBackendSignalKind('peImport'),
        value: GraphicsBackendSignalValue('d3d11.dll'),
      ),
    ];
    final suggestions = <ProgramGraphicsBackendSuggestion>[
      ProgramGraphicsBackendSuggestion(
        backend: GraphicsBackendKind('dxvk'),
        confidence: GraphicsBackendConfidence('high'),
        reason: 'D3D11 API usage was detected.',
      ),
    ];
    final hints = ProgramGraphicsBackendHints(
      programPath: ProgramPath('/games/steam.exe'),
      hostPlatform: KonyakHostPlatform.linux,
      signals: signals,
      suggestions: suggestions,
    );
    signals.add(
      ProgramGraphicsBackendSignal(
        kind: GraphicsBackendSignalKind('string'),
        value: GraphicsBackendSignalValue('d3d12'),
      ),
    );
    suggestions.clear();

    expect(hints.programPath, ProgramPath('/games/steam.exe'));
    expect(hints.hostPlatform, KonyakHostPlatform.linux);
    expect(hints.signals, [
      ProgramGraphicsBackendSignal(
        kind: GraphicsBackendSignalKind('peImport'),
        value: GraphicsBackendSignalValue('d3d11.dll'),
      ),
    ]);
    expect(hints.suggestions, [
      ProgramGraphicsBackendSuggestion(
        backend: GraphicsBackendKind('dxvk'),
        confidence: GraphicsBackendConfidence('high'),
        reason: 'D3D11 API usage was detected.',
      ),
    ]);
  });

  test('graphics backend hint decisions use semantic program paths', () {
    final hints = programGraphicsBackendHintsFromSignals(
      programPath: ProgramPath('/games/steam.exe'),
      hostPlatform: KonyakHostPlatform.linux,
      signals: [
        ProgramGraphicsBackendSignal(
          kind: GraphicsBackendSignalKind('peImport'),
          value: GraphicsBackendSignalValue('d3d12.dll'),
        ),
      ],
    );
    final missing = ProgramGraphicsBackendHintsInspectionResult.missingProgram(
      ProgramPath('/games/missing.exe'),
    );
    final failed = ProgramGraphicsBackendHintsInspectionResult.failed(
      programPath: ProgramPath('/games/broken.exe'),
      message: 'unreadable',
    );

    expect(hints.programPath, ProgramPath('/games/steam.exe'));
    expect(
      missing,
      isA<ProgramGraphicsBackendHintsMissingProgram>().having(
        (result) => result.programPath,
        'programPath',
        ProgramPath('/games/missing.exe'),
      ),
    );
    expect(
      failed,
      isA<ProgramGraphicsBackendHintsInspectionFailed>().having(
        (result) => result.programPath,
        'programPath',
        ProgramPath('/games/broken.exe'),
      ),
    );
  });

  test('runtime release metadata models absent fields with Option', () {
    final metadata = RuntimeReleaseMetadata(version: ReleaseVersion('1.0.0'));

    expect(metadata.version, ReleaseVersion('1.0.0'));
    expect(metadata.archiveUrl.isNone(), isTrue);
    expect(metadata.archiveSha256.isNone(), isTrue);
    expect(metadata.sourceManifestUrl.isNone(), isTrue);
    expect(metadata.sourceManifestSignatureUrl.isNone(), isTrue);
  });

  test('runtime release metadata rejects blank present fields', () {
    expect(
      () => RuntimeReleaseMetadata(version: ReleaseVersion(' ')),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeReleaseMetadata(
        version: ReleaseVersion('1.0.0'),
        archiveUrl: Option.of(RuntimeArchiveUrl(' ')),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime update records model absent fields with Option', () {
    final update = RuntimeUpdateRecord(
      runtimeId: RuntimeId('wine'),
      status: UpdateCheckStatus('unknown'),
    );
    final available = RuntimeUpdateRecord(
      runtimeId: RuntimeId('wine'),
      status: UpdateCheckStatus('available'),
      currentVersion: Option.of(RuntimeVersion('1.0.0')),
      latestVersion: Option.of(RuntimeVersion('1.1.0')),
      archiveUrl: Option.of(
        RuntimeArchiveUrl('https://example.invalid/wine.tar.xz'),
      ),
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
      () => RuntimeUpdateRecord(
        runtimeId: RuntimeId(' '),
        status: UpdateCheckStatus('unknown'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeUpdateRecord(
        runtimeId: RuntimeId('wine'),
        status: UpdateCheckStatus(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeUpdateRecord(
        runtimeId: RuntimeId('wine'),
        status: UpdateCheckStatus('unknown'),
        archiveUrl: Option.of(RuntimeArchiveUrl(' ')),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime update helpers use semantic version and runtime ids', () {
    final runtime = RuntimeRecord(
      id: 'konyak-macos-wine',
      name: 'Konyak macOS Wine',
      platform: 'macos',
      architecture: 'arm64',
      runnerKind: 'wine',
      isBundled: false,
      isUpdateable: true,
    );

    expect(
      runtimeById([runtime], RuntimeId('konyak-macos-wine')).toNullable(),
      runtime,
    );
    expect(
      updateStatus(
        currentVersion: Option.of(RuntimeVersion('wine-devel-9.0')),
        latestVersion: ReleaseVersion('v9.0'),
      ),
      UpdateCheckStatus('current'),
    );
    expect(
      updateStatus(
        currentVersion: Option.of(AppVersion('1.0.0')),
        latestVersion: ReleaseVersion('1.1.0'),
      ),
      UpdateCheckStatus('available'),
    );
  });

  test('app update records model absent fields with Option', () {
    final update = AppUpdateRecord(
      appId: AppId('konyak'),
      status: UpdateCheckStatus('unknown'),
    );

    expect(update.appId, AppId('konyak'));
    expect(update.status, UpdateCheckStatus('unknown'));
    expect(update.currentVersion.isNone(), isTrue);
    expect(update.latestVersion.isNone(), isTrue);
    expect(update.archiveUrl.isNone(), isTrue);
    expect(update.archiveSha256.isNone(), isTrue);
  });

  test('app update records reject blank present fields', () {
    expect(
      () => AppUpdateRecord(
        appId: AppId(' '),
        status: UpdateCheckStatus('unknown'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateRecord(
        appId: AppId('konyak'),
        status: UpdateCheckStatus(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateRecord(
        appId: AppId('konyak'),
        status: UpdateCheckStatus('unknown'),
        archiveSha256: Option.of(AppArchiveSha256(' ')),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('app update install records model absent fields with Option', () {
    final install = AppUpdateInstallRecord(
      appId: AppId('konyak'),
      status: UpdateInstallStatus('skipped'),
    );

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
      () => AppUpdateInstallRecord(
        appId: AppId(' '),
        status: UpdateInstallStatus('skipped'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateInstallRecord(
        appId: AppId('konyak'),
        status: UpdateInstallStatus(' '),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => AppUpdateInstallRecord(
        appId: AppId('konyak'),
        status: UpdateInstallStatus('installed'),
        installPath: Option.of(AppInstallPath(' ')),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('update records compare by semantic values', () {
    expect(
      RuntimeUpdateRecord(
        runtimeId: RuntimeId('wine'),
        status: UpdateCheckStatus('available'),
        currentVersion: Option.of(RuntimeVersion('1.0.0')),
        latestVersion: Option.of(RuntimeVersion('1.1.0')),
        sourceManifestUrl: Option.of(
          RuntimeSourceManifestUrl('https://example.invalid/source.json'),
        ),
      ),
      RuntimeUpdateRecord(
        runtimeId: RuntimeId('wine'),
        status: UpdateCheckStatus('available'),
        currentVersion: Option.of(RuntimeVersion('1.0.0')),
        latestVersion: Option.of(RuntimeVersion('1.1.0')),
        sourceManifestUrl: Option.of(
          RuntimeSourceManifestUrl('https://example.invalid/source.json'),
        ),
      ),
    );
    expect(
      AppUpdateRecord(
        appId: AppId('konyak'),
        status: UpdateCheckStatus('available'),
        archiveSha256: Option.of(AppArchiveSha256('abc123')),
      ),
      AppUpdateRecord(
        appId: AppId('konyak'),
        status: UpdateCheckStatus('available'),
        archiveSha256: Option.of(AppArchiveSha256('abc123')),
      ),
    );
    expect(
      AppUpdateInstallRecord(
        appId: AppId('konyak'),
        status: UpdateInstallStatus('installed'),
        installPath: Option.of(AppInstallPath('/Applications/Konyak.app')),
      ),
      AppUpdateInstallRecord(
        appId: AppId('konyak'),
        status: UpdateInstallStatus('installed'),
        installPath: Option.of(AppInstallPath('/Applications/Konyak.app')),
      ),
    );
    expect(
      RuntimeReleaseMetadata(
        version: ReleaseVersion('1.0.0'),
        sourceManifestSignatureUrl: Option.of(
          RuntimeSourceManifestSignatureUrl(
            'https://example.invalid/source.json.sig',
          ),
        ),
      ),
      RuntimeReleaseMetadata(
        version: ReleaseVersion('1.0.0'),
        sourceManifestSignatureUrl: Option.of(
          RuntimeSourceManifestSignatureUrl(
            'https://example.invalid/source.json.sig',
          ),
        ),
      ),
    );
  });

  test('runtime release metadata fetch results compare by value', () {
    expect(
      RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: ReleaseVersion('1.0.0'),
          sourceManifestUrl: Option.of(
            RuntimeSourceManifestUrl('https://example.invalid/source.json'),
          ),
        ),
      ),
      RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: ReleaseVersion('1.0.0'),
          sourceManifestUrl: Option.of(
            RuntimeSourceManifestUrl('https://example.invalid/source.json'),
          ),
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
          appId: AppId('konyak'),
          status: UpdateCheckStatus('available'),
          latestVersion: Option.of(ReleaseVersion('1.1.0')),
        ),
      ),
      AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: AppId('konyak'),
          status: UpdateCheckStatus('available'),
          latestVersion: Option.of(ReleaseVersion('1.1.0')),
        ),
      ),
    );
    expect(
      const AppUpdateCheckFailed('update metadata unavailable'),
      const AppUpdateCheckFailed('update metadata unavailable'),
    );
    expect(
      AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: AppId('konyak'),
          status: UpdateInstallStatus('installed'),
        ),
      ),
      AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: AppId('konyak'),
          status: UpdateInstallStatus('installed'),
        ),
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
          runtimeId: RuntimeId('wine'),
          status: UpdateCheckStatus('available'),
          latestVersion: Option.of(RuntimeVersion('1.1.0')),
        ),
      ),
      RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: RuntimeId('wine'),
          status: UpdateCheckStatus('available'),
          latestVersion: Option.of(RuntimeVersion('1.1.0')),
        ),
      ),
    );
    expect(
      const RuntimeUpdateCheckFailed('runtime metadata unavailable'),
      const RuntimeUpdateCheckFailed('runtime metadata unavailable'),
    );
    expect(
      RuntimeUpdateCheckResult.runtimeNotFound(RuntimeId('wine')),
      RuntimeUpdateCheckResult.runtimeNotFound(RuntimeId('wine')),
    );
  });

  test('runtime install operations group install source as a domain value', () {
    final operation = RuntimeInstallRequestOperation.fullInstall();

    final source = operation.installSource;

    expect(source, isA<RuntimeConfiguredArchiveSource>());
    expect(source.hasExplicitInstallSource, isFalse);
  });

  test('runtime install request operations accept typed source inputs', () {
    final archiveOperation = RuntimeInstallRequestOperation.fullInstall(
      archivePath: Option.of(RuntimeArchivePath('/wine.tar.gz')),
      archiveSha256: Option.of(RuntimeArchiveChecksumValue('abc123')),
      force: true,
    );

    expect(archiveOperation, isA<RuntimeFullInstallOperation>());
    expect(archiveOperation.force, isTrue);
    expect(
      archiveOperation.archivePath.toNullable(),
      RuntimeArchivePath('/wine.tar.gz'),
    );
    expect(
      archiveOperation.archiveSha256.toNullable(),
      RuntimeArchiveChecksumValue('abc123'),
    );

    final manifestOperation = RuntimeInstallRequestOperation.repair(
      sourceManifest: Option.of(
        RuntimeSourceManifestUrl('https://example.invalid/source.json'),
      ),
      sourceManifestSignature: Option.of(
        RuntimeSourceManifestSignatureUrl(
          'https://example.invalid/source.json.sig',
        ),
      ),
    );

    expect(
      manifestOperation.sourceManifest.toNullable(),
      RuntimeSourceManifestUrl('https://example.invalid/source.json'),
    );
    expect(
      manifestOperation.sourceManifestSignature.toNullable(),
      RuntimeSourceManifestSignatureUrl(
        'https://example.invalid/source.json.sig',
      ),
    );
  });

  test('runtime install operations model source manifest explicitly', () {
    final operation = RuntimeInstallRequestOperation.repair(
      sourceManifest: Option.of(
        RuntimeSourceManifestUrl('https://example.invalid/source.json'),
      ),
      sourceManifestSignature: Option.of(
        RuntimeSourceManifestSignatureUrl(
          'https://example.invalid/source.json.sig',
        ),
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

    final typedSource = RuntimeInstallSource.sourceManifest(
      sourceManifest: RuntimeSourceManifestUrl(
        'https://example.invalid/typed-source.json',
      ),
      signature: runtimeSourceManifestSignature(
        Option.of(
          RuntimeSourceManifestSignatureUrl(
            'https://example.invalid/typed-source.json.sig',
          ),
        ),
      ),
    );
    expect(typedSource, isA<RuntimeSourceManifestInstallSource>());

    final configuredManifest = runtimeSourceManifestForPlatform(
      platformSpec: macosKonyakRuntimePlatformSpec,
      environment: HostEnvironment({
        'KONYAK_RUNTIME_PROFILE': 'development',
        macosKonyakRuntimePlatformSpec.developmentSourceManifestEnvironmentKey:
            'https://example.invalid/dev-source.json',
      }),
    );
    expect(
      configuredManifest.toNullable(),
      RuntimeSourceManifestUrl('https://example.invalid/dev-source.json'),
    );
  });

  test('runtime install operations expose immutable source snapshots', () {
    final componentArchivePaths = <RuntimeArchivePath>[
      RuntimeArchivePath('/dxvk.tar.gz'),
    ];
    final operation = RuntimeInstallRequestOperation.componentInstall(
      componentArchivePaths: componentArchivePaths,
    );
    componentArchivePaths.add(RuntimeArchivePath('/vkd3d.tar.gz'));

    expect(operation, isA<RuntimeComponentInstallOperation>());
    expect(operation.operation, RuntimeInstallOperation.componentInstall);
    expect(operation.force, isFalse);
    expect(operation.componentArchivePaths, [
      RuntimeArchivePath('/dxvk.tar.gz'),
    ]);
  });

  test('runtime install sources expose immutable archive path snapshots', () {
    final componentArchivePaths = <RuntimeArchivePath>[
      RuntimeArchivePath('/dxvk.tar.gz'),
    ];
    final configuredSource = RuntimeInstallSource.configuredArchive(
      componentArchivePaths: componentArchivePaths,
    );
    final localSource = RuntimeInstallSource.localArchive(
      archivePath: RuntimeArchivePath('/wine.tar.gz'),
      componentArchivePaths: componentArchivePaths,
    );
    final remoteSource = RuntimeInstallSource.remoteArchive(
      archiveUrl: RuntimeArchiveUrl('https://example.invalid/wine.tar.gz'),
      componentArchivePaths: componentArchivePaths,
    );
    componentArchivePaths.add(RuntimeArchivePath('/vkd3d.tar.gz'));

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

  test('bottle commands model selected command plan kinds', () {
    final supportedWinecfg = supportedBottleCommand(
      BottleCommand(' WineCfg '),
    ).toNullable();
    expect(supportedWinecfg?.command, BottleCommand('winecfg'));
    expect(supportedWinecfg?.planKind, BottleCommandPlanKind.wineCommand);
    expect(
      supportedBottleCommand(BottleCommand('terminal')).toNullable()?.planKind,
      BottleCommandPlanKind.terminal,
    );
    expect(
      supportedBottleCommand(BottleCommand('cmd')).toNullable()?.planKind,
      BottleCommandPlanKind.terminalWithInitialCommand,
    );
    expect(
      supportedBottleCommand(
        BottleCommand('simulate-reboot'),
      ).toNullable()?.planKind,
      BottleCommandPlanKind.prefixRestart,
    );
    expect(
      supportedBottleCommand(
        BottleCommand('winetricks'),
      ).toNullable()?.planKind,
      BottleCommandPlanKind.winetricks,
    );
    expect(supportedBottleCommand(BottleCommand('notepad')).isNone(), isTrue);
    expect(wineArgumentsForBottleCommand(BottleCommand('dxdiag')).value, const [
      'cmd',
      '/c',
      'dxdiag /t C:\\konyak-dxdiag.txt && start "" notepad C:\\konyak-dxdiag.txt',
    ]);

    final request = linuxTerminalCommandRequest(
      bottle: BottleRecord(
        id: 'steam',
        name: 'Steam',
        path: '/home/user/.local/share/konyak/Bottles/Steam',
        windowsVersion: 'win10',
      ),
      environment: const HostEnvironment.empty(),
      initialWineCommand: Option.of(BottleCommand('cmd')),
    );

    expect(request.programPath, ProgramPath('cmd'));
    expect(request.arguments.value.last, contains("'cmd'"));
  });

  test('program settings helpers return typed run arguments and log paths', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
    );
    final settings = ProgramSettingsRecord(
      arguments: ProgramArguments('-windowed -novid'),
      logging: Option.of(
        ProgramLoggingSettingsRecord(
          logFilePath: ProgramLogPath('/tmp/run.log'),
        ),
      ),
    );

    expect(
      programSettingsArguments(settings),
      ProgramRunArguments(const <String>['-windowed', '-novid']),
    );
    expect(
      programSettingsLogPath(bottle: bottle, settings: settings),
      ProgramLogPath('/tmp/run.log'),
    );
    expect(
      programSettingsLogPath(bottle: bottle, settings: ProgramSettingsRecord()),
      ProgramLogPath('/bottles/steam/logs/latest.log'),
    );
  });

  test('registry planning policy controls macOS-only registry values', () {
    final macosUpdates = runtimeSettingsRegistryUpdates(
      currentRuntimeSettings: BottleRuntimeSettings(),
      runtimeSettings: BottleRuntimeSettings(
        retinaMode: true,
        dpiScaling: WindowsDpiScaling(192),
      ),
      policy: RegistryPlanningPolicy.macosWine,
    );
    final linuxUpdates = runtimeSettingsRegistryUpdates(
      currentRuntimeSettings: BottleRuntimeSettings(),
      runtimeSettings: BottleRuntimeSettings(
        retinaMode: true,
        dpiScaling: WindowsDpiScaling(192),
      ),
      policy: RegistryPlanningPolicy.linuxWine,
    );

    expect(
      macosUpdates.map((update) => update.key),
      contains(ProgramRegistryKey(r'HKCU\Software\Wine\Mac Driver')),
    );
    expect(
      linuxUpdates.map((update) => update.key),
      isNot(contains(ProgramRegistryKey(r'HKCU\Software\Wine\Mac Driver'))),
    );
    expect(
      bottleSettingsRegistryQueries(
        policy: RegistryPlanningPolicy.macosWine,
      ).map((query) => query.key),
      contains(ProgramRegistryKey(r'HKCU\Software\Wine\Mac Driver')),
    );
    expect(
      bottleSettingsRegistryQueries(
        policy: RegistryPlanningPolicy.linuxWine,
      ).map((query) => query.key),
      isNot(contains(ProgramRegistryKey(r'HKCU\Software\Wine\Mac Driver'))),
    );
  });

  test('registry argument helpers return typed run arguments', () {
    expect(
      registryUpdateArguments(
        RegistryValueUpdate(
          key: ProgramRegistryKey(r'HKCU\Software\Wine'),
          name: ProgramRegistryValueName('Version'),
          type: ProgramRegistryValueType('REG_SZ'),
          data: ProgramRegistryValueData('win10'),
        ),
      ),
      ProgramRunArguments(const <String>[
        'reg',
        'add',
        r'HKCU\Software\Wine',
        '-v',
        'Version',
        '-t',
        'REG_SZ',
        '-d',
        'win10',
        '-f',
      ]),
    );
    expect(
      registryQueryArguments(
        RegistryValueQuery(
          key: ProgramRegistryKey(r'HKCU\Software\Wine'),
          name: ProgramRegistryValueName('Version'),
        ),
      ),
      ProgramRunArguments(const <String>[
        'reg',
        'query',
        r'HKCU\Software\Wine',
        '/v',
        'Version',
      ]),
    );
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

  test('program mutation request records compare by semantic values', () {
    final settings = ProgramSettingsRecord(
      locale: ProgramLocale('ja_JP'),
      arguments: ProgramArguments('-novid'),
    );

    expect(
      ProgramPinRequest(
        bottleId: BottleId('steam'),
        name: ProgramName('Steam'),
        programPath: ProgramPath('/steam.exe'),
      ),
      ProgramPinRequest(
        bottleId: BottleId('steam'),
        name: ProgramName('Steam'),
        programPath: ProgramPath('/steam.exe'),
      ),
    );
    expect(
      ProgramUnpinRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
      ),
      ProgramUnpinRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
      ),
    );
    expect(
      ProgramRenameRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        name: ProgramName('Steam Beta'),
      ),
      ProgramRenameRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        name: ProgramName('Steam Beta'),
      ),
    );
    expect(
      PinnedProgramLauncherManifest(
        launcherId: ProgramLauncherId('steam'),
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        programName: ProgramName('Steam'),
      ),
      PinnedProgramLauncherManifest(
        launcherId: ProgramLauncherId('steam'),
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        programName: ProgramName('Steam'),
      ),
    );
    expect(
      WineProcessTerminationRequest(
        bottleId: BottleId('steam'),
        processId: WineProcessId('42'),
      ),
      WineProcessTerminationRequest(
        bottleId: BottleId('steam'),
        processId: WineProcessId('42'),
      ),
    );
    expect(
      WineProcessGroupTerminationRequest(
        bottleId: Option.of(BottleId('steam')),
      ),
      WineProcessGroupTerminationRequest(
        bottleId: Option.of(BottleId('steam')),
      ),
    );
    expect(WineProcessGroupTerminationRequest().bottleId.isNone(), isTrue);
    expect(
      ProgramSettingsRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
      ),
      ProgramSettingsRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
      ),
    );
    expect(
      ProgramSettingsUpdateRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        settings: settings,
      ),
      ProgramSettingsUpdateRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        settings: ProgramSettingsRecord(
          locale: ProgramLocale('ja_JP'),
          arguments: ProgramArguments('-novid'),
        ),
      ),
    );
  });

  test('program settings results compare by semantic values', () {
    final settings = ProgramSettingsRecord(
      locale: ProgramLocale('ja_JP'),
      arguments: ProgramArguments('-novid'),
    );

    expect(
      ProgramSettingsReadResult.read(settings),
      ProgramSettingsReadResult.read(
        ProgramSettingsRecord(
          locale: ProgramLocale('ja_JP'),
          arguments: ProgramArguments('-novid'),
        ),
      ),
    );
    expect(
      ProgramSettingsReadResult.missingBottle(BottleId('steam')),
      ProgramSettingsReadResult.missingBottle(BottleId('steam')),
    );
    expect(
      ProgramSettingsReadResult.failed('read failed'),
      ProgramSettingsReadResult.failed('read failed'),
    );
    expect(
      ProgramSettingsUpdateResult.updated(settings),
      ProgramSettingsUpdateResult.updated(
        ProgramSettingsRecord(
          locale: ProgramLocale('ja_JP'),
          arguments: ProgramArguments('-novid'),
        ),
      ),
    );
    expect(
      ProgramSettingsUpdateResult.missingBottle(BottleId('steam')),
      ProgramSettingsUpdateResult.missingBottle(BottleId('steam')),
    );
    expect(
      ProgramSettingsUpdateResult.failed('write failed'),
      ProgramSettingsUpdateResult.failed('write failed'),
    );
  });

  test('program pin results compare by semantic values', () {
    BottleRecord bottle() {
      return BottleRecord(
        id: 'steam',
        name: 'Steam',
        path: '/bottles/steam',
        windowsVersion: 'win10',
      );
    }

    expect(
      ProgramPinResult.pinned(bottle()),
      ProgramPinResult.pinned(bottle()),
    );
    expect(
      ProgramPinResult.missing(BottleId('steam')),
      ProgramPinResult.missing(BottleId('steam')),
    );
    expect(
      ProgramPinResult.conflict(ProgramPath('/steam.exe')),
      ProgramPinResult.conflict(ProgramPath('/steam.exe')),
    );
    expect(
      ProgramPinResult.failed('pin failed'),
      ProgramPinResult.failed('pin failed'),
    );
  });

  test('program update results compare by semantic values', () {
    BottleRecord bottle() {
      return BottleRecord(
        id: 'steam',
        name: 'Steam',
        path: '/bottles/steam',
        windowsVersion: 'win10',
      );
    }

    expect(
      ProgramUpdateResult.updated(bottle()),
      ProgramUpdateResult.updated(bottle()),
    );
    expect(
      ProgramUpdateResult.missingBottle(BottleId('steam')),
      ProgramUpdateResult.missingBottle(BottleId('steam')),
    );
    expect(
      ProgramUpdateResult.missingProgram(ProgramPath('/steam.exe')),
      ProgramUpdateResult.missingProgram(ProgramPath('/steam.exe')),
    );
    expect(
      ProgramUpdateResult.failed('update failed'),
      ProgramUpdateResult.failed('update failed'),
    );
  });

  test('Wine process kill plans model process ids with WineProcessId', () {
    expect(winedbgAttachProcessId(WineProcessId('000000d8')), '0x000000d8');
    expect(winedbgAttachProcessId(WineProcessId('0x000000d8')), '0x000000d8');

    final killPlan = winedbgProcessKillPlan(WineProcessId('000000d8'));

    expect(killPlan.command, WinedbgCommand('kill'));
    expect(killPlan.logFileName, ProgramLogFileName('wine-process-kill.log'));
    expect(
      killPlan.trailingArguments,
      ProgramRunArguments(const <String>['0x000000d8']),
    );

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

  test('Wine process list plans use a typed winedbg command plan', () {
    final listPlan = winedbgProcessListPlan();

    expect(listPlan.command, WinedbgCommand('info proc'));
    expect(listPlan.logFileName, ProgramLogFileName('wine-processes.log'));
    expect(listPlan.trailingArguments, ProgramRunArguments(const <String>[]));

    final request =
        ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: const HostEnvironment.empty(),
        ).planWineProcessList(
          bottle: BottleRecord(
            id: 'steam',
            name: 'Steam',
            path:
                '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
            windowsVersion: 'win10',
          ),
        );

    expect(
      request.arguments,
      ProgramRunArguments(const <String>['winedbg', '--command', 'info proc']),
    );
    expect(
      request.logPath,
      ProgramLogPath(
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/wine-processes.log',
      ),
    );
  });

  test('runtime install source value objects reject blank present sources', () {
    expect(() => RuntimeArchivePath(' '), throwsA(isA<ArgumentError>()));
    expect(() => RuntimeSourceManifestUrl(' '), throwsA(isA<ArgumentError>()));
    expect(
      () => RuntimeArchiveChecksumValue(' '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('program settings records compare by semantic values', () {
    expect(
      ProgramSettingsRecord(
        locale: ProgramLocale('ja_JP'),
        arguments: ProgramArguments('-novid'),
        environment: ProgramEnvironmentOverrides({'LANG': 'ja_JP.UTF-8'}),
        logging: Option.of(
          ProgramLoggingSettingsRecord(
            createLogFile: false,
            additionalWineLoggingChannels: WineDebugChannels(' +seh '),
            logFilePath: ProgramLogPath(' /tmp/steam.log '),
          ),
        ),
      ),
      ProgramSettingsRecord(
        locale: ProgramLocale('ja_JP'),
        arguments: ProgramArguments('-novid'),
        environment: ProgramEnvironmentOverrides({'LANG': 'ja_JP.UTF-8'}),
        logging: Option.of(
          ProgramLoggingSettingsRecord(
            createLogFile: false,
            additionalWineLoggingChannels: WineDebugChannels('+seh'),
            logFilePath: ProgramLogPath('/tmp/steam.log'),
          ),
        ),
      ),
    );
  });

  test('program settings expose immutable environment snapshots', () {
    final environment = <String, String>{'LANG': 'ja_JP.UTF-8'};
    final settings = ProgramSettingsRecord(
      environment: ProgramEnvironmentOverrides(environment),
      logging: Option.of(
        ProgramLoggingSettingsRecord(
          additionalWineLoggingChannels: WineDebugChannels(' +seh '),
          logFilePath: ProgramLogPath(' /tmp/steam.log '),
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
    expect(
      settings.environment
          .add(
            ProgramEnvironmentVariableName('WINEDEBUG'),
            ProgramEnvironmentVariableValue('-all'),
          )
          .toMap(),
      {'LANG': 'ja_JP.UTF-8', 'WINEDEBUG': '-all'},
    );
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
    expect(
      request,
      ProgramRunRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/steam.exe'),
        runnerKind: RunnerKind('wine'),
        executable: ProgramExecutable('wine'),
        arguments: ProgramRunArguments(const <String>['/steam.exe']),
        environment: const ProgramRunEnvironment.empty(),
        logPath: ProgramLogPath('/bottles/steam/logs/latest.log'),
        workingDirectory: Option.of(ProgramWorkingDirectoryPath('/downloads')),
      ),
    );
  });

  test('program run result unions compare by semantic values', () {
    expect(
      ProgramRunCompleted(processExitCode: 0, stdout: 'launched', stderr: ''),
      ProgramRunCompleted(processExitCode: 0, stdout: 'launched', stderr: ''),
    );
    expect(
      ProgramRunFailed(message: 'wine not found'),
      ProgramRunFailed(message: 'wine not found'),
    );
    expect(PathOpenCompleted(), PathOpenCompleted());
    expect(PathOpenFailed('open failed'), PathOpenFailed('open failed'));
    expect(DetachedProcessStartCompleted(), DetachedProcessStartCompleted());
    expect(
      DetachedProcessStartFailed('start failed'),
      DetachedProcessStartFailed('start failed'),
    );
  });

  test('detached process starters expose typed executable requests', () {
    final starter = RecordingDomainDetachedProcessStarter();

    final result = starter.start(
      executable: ProgramExecutable('/usr/bin/open'),
      arguments: ProgramRunArguments(const <String>[
        '/Applications/Konyak.app',
      ]),
    );

    expect(result, const DetachedProcessStartCompleted());
    expect(starter.executable, ProgramExecutable('/usr/bin/open'));
    expect(
      starter.arguments,
      ProgramRunArguments(const <String>['/Applications/Konyak.app']),
    );
  });

  test('path openers expose typed open and reveal targets', () {
    final opener = RecordingDomainPathOpener();

    final openResult = opener.openPath(PathOpenTarget('https://konyak.test'));
    final revealResult = opener.revealPath(
      PathRevealTarget('/Games/Steam.exe'),
    );

    expect(openResult, const PathOpenCompleted());
    expect(revealResult, const PathOpenCompleted());
    expect(opener.openedTarget, PathOpenTarget('https://konyak.test'));
    expect(opener.revealedTarget, PathRevealTarget('/Games/Steam.exe'));
  });

  test('runtime executable probes expose typed executable requests', () {
    final probe = RecordingDomainRuntimeExecutableProbe();
    final environment = ProgramRunEnvironment(const <String, String>{
      'PATH': '/runtime/bin',
    });

    final result = probe.run(
      executable: ProgramExecutable('/runtime/bin/wine'),
      arguments: ProgramRunArguments(const <String>['--version']),
      environment: environment,
      workingDirectory: ProgramWorkingDirectoryPath('/runtime/bin'),
    );

    expect(result.exitCode, 0);
    expect(probe.executable, ProgramExecutable('/runtime/bin/wine'));
    expect(probe.arguments, ProgramRunArguments(const <String>['--version']));
    expect(probe.environment, environment);
    expect(probe.workingDirectory, ProgramWorkingDirectoryPath('/runtime/bin'));
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
      bottleId: BottleId('steam'),
      status: WineProcessStatus('terminated'),
      runnerKind: RunnerKind('wine'),
      executable: ProgramExecutable('wine'),
      argv: argv,
    );
    argv.add('--changed');

    expect(record.bottleId, BottleId('steam'));
    expect(record.status, WineProcessStatus('terminated'));
    expect(record.runnerKind, RunnerKind('wine'));
    expect(record.executable, ProgramExecutable('wine'));
    expect(record.argv, ['wine', '/steam.exe']);
    expect(() => record.argv.add('--other'), throwsUnsupportedError);
    expect(
      record,
      WineProcessTerminationRecord(
        bottleId: BottleId('steam'),
        status: WineProcessStatus('terminated'),
        runnerKind: RunnerKind('wine'),
        executable: ProgramExecutable('wine'),
        argv: <String>['wine', '/steam.exe'],
      ),
    );
  });

  test(
    'runtime package install requests expose immutable collection snapshots',
    () {
      final componentArchivePaths = <RuntimeArchivePath>[
        RuntimeArchivePath('/dxvk.tar.gz'),
      ];
      final componentVersions = <String, String>{'dxvk': '2.7'};
      final request = RuntimePackageInstallRequest(
        runtimeLabel: 'Konyak Wine',
        archivePath: RuntimeArchivePath('/wine.tar.gz'),
        archiveSha256: const Option.none(),
        componentArchivePaths: componentArchivePaths,
        componentVersions: RuntimeComponentVersions(componentVersions),
        runtimeRoot: RuntimeRootPath('/tmp/konyak-runtime'),
        requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),
        expectedExecutablePath: RuntimeComponentPath(
          '/tmp/konyak-runtime/bin/wine',
        ),
      );
      componentArchivePaths.clear();
      componentVersions['dxvk'] = 'changed';

      expect(request.archivePath, RuntimeArchivePath('/wine.tar.gz'));
      expect(request.componentArchivePaths, [
        RuntimeArchivePath('/dxvk.tar.gz'),
      ]);
      expect(request.componentVersions.toMap(), {'dxvk': '2.7'});
      expect(
        request.componentVersions[RuntimeComponentId('dxvk')].toNullable(),
        RuntimeVersion('2.7'),
      );
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
      expect(
        request.componentVersions
            .add(RuntimeComponentId('vkd3d'), RuntimeVersion('2.14'))
            .toMap(),
        {'dxvk': '2.7', 'vkd3d': '2.14'},
      );
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
        archivePath: RuntimeArchivePath('/wine.tar.gz'),
        archiveSha256: const Option.none(),
        componentArchivePaths: const <RuntimeArchivePath>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: RuntimeRootPath('/tmp/konyak-runtime'),
        requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),
        expectedExecutablePath: RuntimeComponentPath(
          '/tmp/konyak-runtime/bin/wine',
        ),
      );

      expect(request.archiveSha256.isNone(), isTrue);
    },
  );

  test('runtime package install requests reject blank required values', () {
    expect(
      () => RuntimePackageInstallRequest(
        runtimeLabel: ' ',
        archivePath: RuntimeArchivePath('/wine.tar.gz'),
        archiveSha256: const Option.none(),
        componentArchivePaths: const <RuntimeArchivePath>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: RuntimeRootPath('/tmp/konyak-runtime'),
        requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),
        expectedExecutablePath: RuntimeComponentPath(
          '/tmp/konyak-runtime/bin/wine',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimePackageInstallRequest(
        runtimeLabel: 'Konyak Wine',
        archivePath: RuntimeArchivePath('/wine.tar.gz'),
        archiveSha256: Option.of(RuntimeArchiveChecksumValue(' ')),
        componentArchivePaths: const <RuntimeArchivePath>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: RuntimeRootPath('/tmp/konyak-runtime'),
        requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),
        expectedExecutablePath: RuntimeComponentPath(
          '/tmp/konyak-runtime/bin/wine',
        ),
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
          archivePath: RuntimeArchivePath('/tmp/dxvk.tar.xz'),
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
    expect(
      _expectFound(bottleCatalog.findBottle(BottleId('steam'))),
      isNotNull,
    );
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
