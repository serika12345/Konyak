import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
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
    expect(
      () => bottle.pinnedPrograms.add(
        PinnedProgramRecord(name: 'Other', path: '/other.exe'),
      ),
      throwsUnsupportedError,
    );
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
      () => validBottle().copyWith(id: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().copyWith(name: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().copyWith(path: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => validBottle().copyWith(windowsVersion: ' '),
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
    final withIcon = withoutIcon.copyWith(iconPath: Option.of('/steam.icns'));
    final clearedIcon = withIcon.copyWith(iconPath: const Option.none());

    expect(withoutIcon.iconPath.isNone(), isTrue);
    expect(withIcon.iconPath.toNullable(), '/steam.icns');
    expect(clearedIcon.iconPath.isNone(), isTrue);
    expect(withIcon.toJson(), containsPair('iconPath', '/steam.icns'));
    expect(clearedIcon.toJson(), isNot(contains('iconPath')));
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
    expect(metadata.architecture.toNullable(), 'x86_64');
    expect(metadata.toJson(), {
      'architecture': 'x86_64',
      'fileDescription': 'Steam',
      'iconPath': '/steam.icns',
    });
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
    expect(process.metadata.isNone(), isTrue);
    expect(process.hostPath.isNone(), isTrue);
    expect(program.toJson(), isNot(contains('metadata')));
    expect(process.toJson(), isNot(contains('metadata')));
    expect(process.toJson(), isNot(contains('hostPath')));
  });

  test('runtime release metadata models absent fields with Option', () {
    final metadata = RuntimeReleaseMetadata(version: '1.0.0');

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
    expect(update.archiveUrl.isNone(), isTrue);
    expect(update.toJson(), isNot(contains('archiveUrl')));
    expect(available.toJson(), containsPair('currentVersion', '1.0.0'));
    expect(
      available.toJson(),
      containsPair('archiveUrl', 'https://example.invalid/wine.tar.xz'),
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

    expect(update.currentVersion.isNone(), isTrue);
    expect(update.latestVersion.isNone(), isTrue);
    expect(update.archiveUrl.isNone(), isTrue);
    expect(update.archiveSha256.isNone(), isTrue);
    expect(update.toJson(), isNot(contains('archiveUrl')));
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

    expect(install.currentVersion.isNone(), isTrue);
    expect(install.installedVersion.isNone(), isTrue);
    expect(install.archiveUrl.isNone(), isTrue);
    expect(install.archiveSha256.isNone(), isTrue);
    expect(install.installPath.isNone(), isTrue);
    expect(install.toJson(), isNot(contains('installPath')));
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

  test('runtime install operations model absent sources with Option', () {
    final operation = RuntimeFullInstallOperation();

    expect(operation.archivePath.isNone(), isTrue);
    expect(operation.archiveUrl.isNone(), isTrue);
    expect(operation.archiveSha256.isNone(), isTrue);
    expect(operation.sourceManifest.isNone(), isTrue);
    expect(operation.sourceManifestSignature.isNone(), isTrue);
  });

  test('runtime install operations reject blank present sources', () {
    expect(
      () => RuntimeFullInstallOperation(archivePath: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeRepairOperation(sourceManifest: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeUpdateInstallOperation(archiveSha256: ' '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('program settings expose immutable environment snapshots', () {
    final environment = <String, String>{'LANG': 'ja_JP.UTF-8'};
    final settings = ProgramSettingsRecord(environment: environment);
    environment['LANG'] = 'en_US.UTF-8';

    expect(settings.environment, {'LANG': 'ja_JP.UTF-8'});
    expect(
      () => settings.environment['WINEDEBUG'] = '-all',
      throwsUnsupportedError,
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
        archiveSha256: null,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory('/tmp/konyak-runtime'),
        requiredExecutableRelativePath: requiredExecutableRelativePath,
        expectedExecutablePath: '/tmp/konyak-runtime/bin/wine',
      );
      componentArchivePaths.clear();
      componentVersions['dxvk'] = 'changed';
      requiredExecutableRelativePath.add('changed');

      expect(request.componentArchivePaths, ['/dxvk.tar.gz']);
      expect(request.componentVersions, {'dxvk': '2.7'});
      expect(request.requiredExecutableRelativePath, ['bin', 'wine']);
      expect(request.componentArchivePaths.clear, throwsUnsupportedError);
      expect(
        () => request.componentVersions['vkd3d'] = '2.14',
        throwsUnsupportedError,
      );
      expect(
        request.requiredExecutableRelativePath.clear,
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
        archiveSha256: null,
        componentArchivePaths: const <String>[],
        componentVersions: const <String, String>{},
        runtimeRoot: Directory('/tmp/konyak-runtime'),
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
        archiveSha256: null,
        componentArchivePaths: const <String>[],
        componentVersions: const <String, String>{},
        runtimeRoot: Directory('/tmp/konyak-runtime'),
        requiredExecutableRelativePath: const <String>['bin', 'wine'],
        expectedExecutablePath: '/tmp/konyak-runtime/bin/wine',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimePackageInstallRequest(
        runtimeLabel: 'Konyak Wine',
        archivePath: '/wine.tar.gz',
        archiveSha256: ' ',
        componentArchivePaths: const <String>[],
        componentVersions: const <String, String>{},
        runtimeRoot: Directory('/tmp/konyak-runtime'),
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

    expect(component.version.isNone(), isTrue);
    expect(component.toJson(), isNot(contains('version')));
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
        version: ' ',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('runtime source manifests model missing components with Option', () {
    final manifest = RuntimeSourceManifest(
      runtimeId: 'wine',
      stackId: 'konyak',
      components: const <RuntimeSourceComponent>[
        RuntimeSourceComponent(
          id: 'wine',
          version: '1.0.0',
          archiveUrl: 'https://example.invalid/wine.tar.xz',
          sha256: 'digest',
        ),
      ],
    );

    expect(manifest.componentById('wine').toNullable()?.id, 'wine');
    expect(manifest.componentById('dxvk').isNone(), isTrue);
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
        archiveUrl: ' ',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('installed runtime states model absent layout paths with Option', () {
    final state = InstalledRuntimeState(isInstalled: false);
    const unknown = InstalledRuntimeState.unknown();

    expect(state.isInstalled.toNullable(), isFalse);
    expect(state.applicationSupportPath.isNone(), isTrue);
    expect(state.libraryPath.isNone(), isTrue);
    expect(state.executablePath.isNone(), isTrue);
    expect(unknown.isInstalled.isNone(), isTrue);
  });

  test('installed runtime states reject blank present layout paths', () {
    expect(
      () => InstalledRuntimeState(isInstalled: true, executablePath: ' '),
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

    expect(runtime.distributionKind.isNone(), isTrue);
    expect(runtime.isInstalled.isNone(), isTrue);
    expect(runtime.libraryPath.isNone(), isTrue);
    expect(runtime.executablePath.isNone(), isTrue);
    expect(runtime.archiveUrl.isNone(), isTrue);
    expect(runtime.versionUrl.isNone(), isTrue);
    expect(runtime.stack.isNone(), isTrue);
    expect(runtime.toJson(), isNot(contains('isInstalled')));
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
        executablePath: ' ',
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
