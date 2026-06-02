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
      const RuntimeRecord(
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
