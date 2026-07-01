import 'package:konyak_cli/src/cli/cli_app_runtime_json.dart';
import 'package:konyak_cli/src/io/gptk_wine_installation.dart';
import 'package:konyak_cli/src/platform/macos/macos_setup_checker.dart';
import 'package:test/test.dart';

void main() {
  test('macOS setup status JSON keeps the CLI contract stable', () {
    final status = MacosSetupStatus(
      isSupported: true,
      rosetta: RosettaSetupStatus(
        isRequired: true,
        isInstalled: false,
        installCommand: const <String>['softwareupdate', '--install-rosetta'],
      ),
      runtime: const RuntimeSetupStatus(
        runtimeId: 'macos-wine',
        isInstalled: true,
      ),
    );

    expect(macosSetupStatusJson(status), {
      'isSupported': true,
      'rosetta': {
        'isRequired': true,
        'isInstalled': false,
        'installCommand': ['softwareupdate', '--install-rosetta'],
      },
      'runtime': {'runtimeId': 'macos-wine', 'isInstalled': true},
    });
  });

  test('GPTK Wine install record JSON keeps the CLI contract stable', () {
    const record = GptkWineInstallRecord(
      componentId: 'gptk-d3dmetal',
      sourceDirectory: '/Applications/Game Porting Toolkit.app',
      runtimeRoot:
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
      installedExecutablePath:
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
    );

    expect(gptkWineInstallRecordJson(record), {
      'componentId': 'gptk-d3dmetal',
      'sourceDirectory': '/Applications/Game Porting Toolkit.app',
      'runtimeRoot':
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
      'installedExecutablePath':
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
    });
  });
}
