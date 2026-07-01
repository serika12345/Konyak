import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/src/cli/cli_bottle_parsers.dart';
import 'package:konyak_cli/src/cli/cli_location_parsers.dart';
import 'package:konyak_cli/src/cli/cli_program_run_parsers.dart';
import 'package:konyak_cli/src/cli/cli_runtime_parsers.dart';
import 'package:test/test.dart';

void main() {
  group('bottle parser options', () {
    test('parse valid bottle command inputs explicitly', () {
      final inspected = _expectSome(
        parseJsonBottleInspectCommandOption(const [
          'inspect-bottle',
          'steam',
          '--json',
        ]),
      );
      expect(inspected.value, 'steam');

      final created = _expectSome(
        parseJsonBottleCreateRequestOption(const [
          'create-bottle',
          '--name',
          'Steam',
          '--windows-version',
          'win11',
          '--json',
        ]),
      );
      expect(created.name.value, 'Steam');
      expect(created.windowsVersion.value, 'win11');

      final exported = _expectSome(
        parseJsonBottleArchiveExportRequestOption(const [
          'export-bottle-archive',
          'steam',
          '--archive',
          '/archives/steam.konyak',
          '--json',
        ]),
      );
      expect(exported.bottleId.value, 'steam');
      expect(exported.archivePath.value, '/archives/steam.konyak');

      final imported = _expectSome(
        parseJsonBottleArchiveImportRequestOption(const [
          'import-bottle-archive',
          '--archive',
          '/archives/steam.konyak',
          '--json',
        ]),
      );
      expect(imported.archivePath.value, '/archives/steam.konyak');

      final renamed = _expectSome(
        parseJsonBottleRenameRequestOption(const [
          'rename-bottle',
          'steam',
          '--name',
          'Steam Stable',
          '--json',
        ]),
      );
      expect(renamed.bottleId.value, 'steam');
      expect(renamed.name.value, 'Steam Stable');

      final moved = _expectSome(
        parseJsonBottleMoveRequestOption(const [
          'move-bottle',
          'steam',
          '--path',
          '/Volumes/Games/Steam',
          '--json',
        ]),
      );
      expect(moved.path.value, '/Volumes/Games/Steam');

      final runtimeSettings = _expectSome(
        parseJsonRuntimeSettingsUpdateRequestOption(const [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          '{"dxvk":true}',
          '--json',
        ]),
      );
      expect(runtimeSettings.bottleId.value, 'steam');
      expect(runtimeSettings.runtimeSettings.dxvk, isTrue);
    });

    test('reject incomplete bottle command inputs explicitly', () {
      _expectNone(
        parseJsonBottleCreateRequestOption(const [
          'create-bottle',
          '--windows-version',
          'win11',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonRuntimeSettingsUpdateRequestOption(const [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          '{',
          '--json',
        ]),
      );
    });

    test('reject empty bottle required options explicitly', () {
      _expectNone(
        parseJsonBottleRenameRequestOption(const [
          'rename-bottle',
          'steam',
          '--name',
          '  ',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonBottleMoveRequestOption(const [
          'move-bottle',
          'steam',
          '--path',
          '',
          '--json',
        ]),
      );
    });

    test('reject bottle rest-argument arity mismatches explicitly', () {
      _expectNone(
        parseJsonBottleInspectCommandOption(const [
          'inspect-bottle',
          'steam',
          'extra',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonBottleArchiveImportRequestOption(const [
          'import-bottle-archive',
          'steam',
          '--archive',
          '/archives/steam.konyak',
          '--json',
        ]),
      );
    });
  });

  group('program run parser options', () {
    test('parse valid program run command inputs explicitly', () {
      final runRequest = _expectSome(
        parseJsonProgramRunCliRequestOption(const [
          'run-program',
          'steam',
          '--program',
          '/games/Steam.exe',
          '--settings-json',
          '{"arguments":"-silent"}',
          '--json',
        ]),
      );
      expect(runRequest.bottleId.value, 'steam');
      expect(runRequest.programPath, '/games/Steam.exe');
      expect(_expectSome(runRequest.settings).arguments.value, '-silent');

      final hints = _expectSome(
        parseJsonGraphicsBackendHintsCliRequestOption(const [
          'suggest-graphics-backend',
          '--program',
          '/games/Steam.exe',
          '--json',
        ]),
      );
      expect(hints.programPath, '/games/Steam.exe');

      final winetricks = _expectSome(
        parseJsonWinetricksRunCliRequestOption(const [
          'run-winetricks',
          'steam',
          '--verb',
          'corefonts',
          '--json',
        ]),
      );
      expect(winetricks.bottleId.value, 'steam');
      expect(winetricks.verb, 'corefonts');

      final command = _expectSome(
        parseJsonBottleCommandRunCliRequestOption(const [
          'run-bottle-command',
          'steam',
          '--command',
          'winecfg',
          '--json',
        ]),
      );
      expect(command.command, 'winecfg');
    });

    test('reject incomplete program run inputs explicitly', () {
      _expectNone(
        parseJsonProgramRunCliRequestOption(const [
          'run-program',
          'steam',
          '--program',
          '/games/Steam.exe',
          '--settings-json',
          '{',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonWinetricksRunCliRequestOption(const [
          'run-winetricks',
          'steam',
          '--json',
        ]),
      );
    });

    test('reject empty program run required options explicitly', () {
      _expectNone(
        parseJsonGraphicsBackendHintsCliRequestOption(const [
          'suggest-graphics-backend',
          '--program',
          ' ',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonBottleCommandRunCliRequestOption(const [
          'run-bottle-command',
          'steam',
          '--command',
          '',
          '--json',
        ]),
      );
    });

    test('reject program run rest-argument arity mismatches explicitly', () {
      _expectNone(
        parseJsonProgramRunCliRequestOption(const [
          'run-program',
          'steam',
          'extra',
          '--program',
          '/games/Steam.exe',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonGraphicsBackendHintsCliRequestOption(const [
          'suggest-graphics-backend',
          'steam',
          '--program',
          '/games/Steam.exe',
          '--json',
        ]),
      );
    });
  });

  group('runtime parser options', () {
    test('parse valid runtime command inputs explicitly', () {
      final gptkInstall = _expectSome(
        parseJsonGptkWineInstallRequestOption(const [
          'install-gptk-wine',
          '--from',
          '/downloads/GPTK.dmg',
          '--json',
        ]),
      );
      expect(gptkInstall.sourcePath, '/downloads/GPTK.dmg');

      expect(
        _expectSome(
          parseJsonOpenUrlCommandOption(const [
            'open-url',
            'https://konyak.example',
            '--json',
          ]),
        ),
        'https://konyak.example',
      );

      expect(
        _expectSome(
          parseJsonRuntimeIdCommandOption(const [
            'validate-runtime',
            'macos-wine',
            '--json',
          ], 'validate-runtime'),
        ),
        'macos-wine',
      );

      final macosInstall = _expectSome(
        parseJsonMacosWineInstallRequestOption(const [
          'install-macos-wine',
          '--source-manifest',
          '/manifests/macos.json',
          '--reinstall',
          '--progress-json',
          '--json',
        ]),
      );
      expect(macosInstall.sourceManifest.toNullable(), '/manifests/macos.json');
      expect(macosInstall.force, isTrue);
      expect(macosInstall.emitProgress, isTrue);

      final linuxInstall = _expectSome(
        parseJsonLinuxWineInstallRequestOption(const [
          'install-linux-wine',
          '--source-manifest',
          '/manifests/linux.json',
          '--reinstall',
          '--json',
        ]),
      );
      expect(linuxInstall.sourceManifest.toNullable(), '/manifests/linux.json');
      expect(linuxInstall.force, isTrue);
    });

    test('reject incomplete runtime inputs explicitly', () {
      _expectNone(
        parseJsonGptkWineInstallRequestOption(const [
          'install-gptk-wine',
          '--json',
        ]),
      );
      _expectNone(
        parseRuntimeInstallCliOptionsOption(
          const ['install-macos-wine', '--reinstall', '--json'],
          command: 'install-macos-wine',
          allowReinstall: false,
        ),
      );
    });

    test('reject empty runtime required options explicitly', () {
      _expectNone(
        parseJsonGptkWineInstallRequestOption(const [
          'install-gptk-wine',
          '--from',
          ' ',
          '--json',
        ]),
      );
      _expectNone(
        parseRuntimeInstallCliOptionsOption(
          const ['install-macos-wine', '--source-manifest', '', '--json'],
          command: 'install-macos-wine',
          allowReinstall: true,
        ),
      );
    });

    test('reject runtime rest-argument arity mismatches explicitly', () {
      _expectNone(
        parseJsonOpenUrlCommandOption(const [
          'open-url',
          'https://konyak.example',
          'extra',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonRuntimeIdCommandOption(const [
          'validate-runtime',
          'macos-wine',
          'extra',
          '--json',
        ], 'validate-runtime'),
      );
    });
  });

  group('location parser options', () {
    test('parse valid location command inputs explicitly', () {
      final bottleLocation = _expectSome(
        parseJsonBottleLocationOpenCliRequestOption(const [
          'open-bottle-location',
          'steam',
          '--location',
          'drive-c',
          '--json',
        ]),
      );
      expect(bottleLocation.bottleId.value, 'steam');
      expect(bottleLocation.location.value, 'drive-c');

      final programLocation = _expectSome(
        parseJsonProgramLocationOpenCliRequestOption(const [
          'open-program-location',
          'steam',
          '--program',
          '/games/Steam.exe',
          '--json',
        ]),
      );
      expect(programLocation.bottleId.value, 'steam');
      expect(programLocation.programPath.value, '/games/Steam.exe');
    });

    test('reject incomplete location inputs explicitly', () {
      _expectNone(
        parseJsonBottleLocationOpenCliRequestOption(const [
          'open-bottle-location',
          'steam',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonProgramLocationOpenCliRequestOption(const [
          'open-program-location',
          '--program',
          '/games/Steam.exe',
          '--json',
        ]),
      );
    });

    test('reject empty location required options explicitly', () {
      _expectNone(
        parseJsonBottleLocationOpenCliRequestOption(const [
          'open-bottle-location',
          'steam',
          '--location',
          ' ',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonProgramLocationOpenCliRequestOption(const [
          'open-program-location',
          'steam',
          '--program',
          '',
          '--json',
        ]),
      );
    });

    test('reject location rest-argument arity mismatches explicitly', () {
      _expectNone(
        parseJsonBottleLocationOpenCliRequestOption(const [
          'open-bottle-location',
          'steam',
          'extra',
          '--location',
          'drive-c',
          '--json',
        ]),
      );
      _expectNone(
        parseJsonProgramLocationOpenCliRequestOption(const [
          'open-program-location',
          'steam',
          'extra',
          '--program',
          '/games/Steam.exe',
          '--json',
        ]),
      );
    });
  });
}

T _expectSome<T>(Option<T> option) {
  return option.match(
    () => fail('Expected an option value.'),
    (value) => value,
  );
}

void _expectNone<T>(Option<T> option) {
  option.match(() => null, (_) => fail('Expected an empty option.'));
}
