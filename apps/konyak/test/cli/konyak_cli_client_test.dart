import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';
import 'package:konyak/src/cli/runtime_install_contract.dart';
import 'package:konyak/src/settings/app_settings_summary.dart';

void main() {
  test(
    'loads bottles by invoking the JSON list-bottles CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: '/opt/konyak/bin/konyak',
        processRunner: runner,
      );

      final result = await client.listBottles();

      expect(runner.executable, '/opt/konyak/bin/konyak');
      expect(runner.arguments, const ['list-bottles', '--json']);
      expect(result, isA<LoadedBottleList>());

      final loaded = result as LoadedBottleList;
      expect(loaded.bottles.single.id, 'steam');
      expect(loaded.bottles.single.name, 'Steam');
    },
  );

  test(
    'passes CLI launcher environment for generated pinned app bundles',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: '/env/flutter/bin/dart',
        baseArguments: const ['run', 'bin/konyak.dart'],
        workingDirectory: '/repo/packages/konyak_cli',
        processRunner: runner,
      );

      await client.listBottles();

      expect(
        runner.environment['KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE'],
        '/env/flutter/bin/dart',
      );
      expect(
        runner.environment['KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON'],
        '["run","bin/konyak.dart"]',
      );
      expect(
        runner.environment['KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY'],
        '/repo/packages/konyak_cli',
      );
    },
  );

  test('loads pinned programs from bottle records', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/bottles/steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Steam",
                    "path": "/bottles/steam/drive_c/Steam.exe",
                    "removable": false,
                    "iconPath": "/bottles/steam/cache/icons/steam.ico"
                  }
                ]
              }
            ]
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.listBottles();

    expect(result, isA<LoadedBottleList>());
    final loaded = result as LoadedBottleList;
    expect(loaded.bottles.single.pinnedPrograms.single.name, 'Steam');
    expect(
      loaded.bottles.single.pinnedPrograms.single.path,
      '/bottles/steam/drive_c/Steam.exe',
    );
    expect(
      loaded.bottles.single.pinnedPrograms.single.iconPath,
      '/bottles/steam/cache/icons/steam.ico',
    );
  });

  test(
    'prepends configured base arguments before CLI command arguments',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'dart',
        baseArguments: const ['run', 'bin/konyak.dart'],
        workingDirectory: '/repo/packages/konyak_cli',
        processRunner: runner,
      );

      await client.listBottles();

      expect(runner.executable, 'dart');
      expect(runner.workingDirectory, '/repo/packages/konyak_cli');
      expect(runner.arguments, const [
        'run',
        'bin/konyak.dart',
        'list-bottles',
        '--json',
      ]);
    },
  );

  test('exports a bottle archive through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottleArchive": {
              "bottleId": "steam",
              "archivePath": "/exports/steam.konyak-bottle.tar"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.exportBottleArchive(
      bottleId: 'steam',
      archivePath: '/exports/steam.konyak-bottle.tar',
    );

    expect(runner.arguments, const [
      'export-bottle-archive',
      'steam',
      '--archive',
      '/exports/steam.konyak-bottle.tar',
      '--json',
    ]);
    expect(result, isA<ExportedBottleArchive>());
    final exported = result as ExportedBottleArchive;
    expect(exported.bottleId, 'steam');
    expect(exported.archivePath, '/exports/steam.konyak-bottle.tar');
  });

  test('imports a bottle archive through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.importBottleArchive(
      archivePath: '/imports/steam.konyak-bottle.tar',
    );

    expect(runner.arguments, const [
      'import-bottle-archive',
      '--archive',
      '/imports/steam.konyak-bottle.tar',
      '--json',
    ]);
    expect(result, isA<ImportedBottleArchive>());
    final imported = result as ImportedBottleArchive;
    expect(imported.bottle.id, 'steam');
  });

  test('builds default CLI client from Flutter dev environment paths', () {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
    );

    final client = createDefaultKonyakCliClient(
      environment: const {
        'FLUTTER_ROOT': '/repo/.dart_tool/konyak/flutter-sdk',
        'KONYAK_REPO_ROOT': '/repo',
      },
      processRunner: runner,
    );

    expect(client.executable, '/repo/.dart_tool/konyak/flutter-sdk/bin/dart');
    expect(client.baseArguments, const ['run', 'bin/konyak.dart']);
    expect(client.workingDirectory, '/repo/packages/konyak_cli');
  });

  test('passes development runtime defines to CLI commands', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"runtimes":[]}',
        stderr: '',
      ),
    );

    final client = createDefaultKonyakCliClient(
      environment: const {
        'FLUTTER_ROOT': '/repo/.dart_tool/konyak/flutter-sdk',
      },
      repoRootDefine: '/repo',
      runtimeProfileDefine: 'development',
      macosWineHomeDefine: '/repo/.dart_tool/konyak/dev-runtime/macos-wine',
      linuxWineHomeDefine: '/repo/.dart_tool/konyak/dev-runtime/linux-wine',
      linuxWineLibraryPathDefine: '/nix/store/linux-wine-host-libs/lib',
      macosWineStackManifestDefine:
          '/repo/.dart_tool/konyak/dev-runtime-source/macos-wine-stack/konyak-macos-wine-runtime-stack-source.json',
      linuxWineStackManifestDefine:
          '/repo/.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json',
      macosDevRuntimePrepareScriptDefine:
          '/repo/scripts/prepare_macos_dev_runtime_stack.zsh',
      processRunner: runner,
    );

    final result = await client.listKnownRuntimes();

    expect(result, isA<LoadedRuntimeList>());
    expect(runner.environment, {
      'KONYAK_RUNTIME_PROFILE': 'development',
      'KONYAK_MACOS_WINE_HOME':
          '/repo/.dart_tool/konyak/dev-runtime/macos-wine',
      'KONYAK_LINUX_WINE_HOME':
          '/repo/.dart_tool/konyak/dev-runtime/linux-wine',
      'KONYAK_LINUX_WINE_LIBRARY_PATH': '/nix/store/linux-wine-host-libs/lib',
      'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST':
          '/repo/.dart_tool/konyak/dev-runtime-source/macos-wine-stack/konyak-macos-wine-runtime-stack-source.json',
      'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST':
          '/repo/.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json',
      'KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT':
          '/repo/scripts/prepare_macos_dev_runtime_stack.zsh',
      'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE':
          '/repo/.dart_tool/konyak/flutter-sdk/bin/dart',
      'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
          '["run","bin/konyak.dart"]',
      'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
          '/repo/packages/konyak_cli',
    });
  });

  test('default CLI client prefers dart defines over process environment', () {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
    );

    final client = createDefaultKonyakCliClient(
      environment: const {
        'FLUTTER_ROOT': '/env/flutter',
        'KONYAK_REPO_ROOT': '/env/repo',
        'KONYAK_DART_EXECUTABLE': '/env/dart',
        'KONYAK_CLI_SCRIPT': '/env/bin/konyak.dart',
      },
      dartExecutableDefine: '/define/dart',
      cliScriptDefine: '/define/bin/konyak.dart',
      repoRootDefine: '/define/repo',
      processRunner: runner,
    );

    expect(client.executable, '/define/dart');
    expect(client.baseArguments, const ['run', 'bin/konyak.dart']);
    expect(client.workingDirectory, '/define');
  });

  test('default CLI client prefers bundled executable over Dart script', () {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
    );

    final client = createDefaultKonyakCliClient(
      environment: const {
        'KONYAK_DART_EXECUTABLE': '/env/dart',
        'KONYAK_CLI_SCRIPT': '/env/konyak.dart',
      },
      cliExecutableDefine: '/app/Contents/Resources/konyak-cli',
      processRunner: runner,
    );

    expect(client.executable, '/app/Contents/Resources/konyak-cli');
    expect(client.baseArguments, isEmpty);
  });

  test('default CLI client resolves packaged bundle resource paths', () {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
    );

    final client = createDefaultKonyakCliClient(
      environment: const {
        'KONYAK_APP_EXECUTABLE':
            '/Applications/Konyak.app/Contents/MacOS/Konyak',
      },
      cliExecutableDefine: '__KONYAK_BUNDLE_RESOURCES__/konyak-cli',
      processRunner: runner,
    );

    expect(
      client.executable,
      '/Applications/Konyak.app/Contents/Resources/konyak-cli',
    );
    expect(client.baseArguments, isEmpty);
  });

  test(
    'default CLI client resolves packaged executable from bundle resources env',
    () {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      );

      final client = createDefaultKonyakCliClient(
        environment: const {
          'KONYAK_BUNDLE_RESOURCES': '/tmp/Konyak.AppDir/usr/share/konyak',
        },
        cliExecutableDefine: '__KONYAK_BUNDLE_RESOURCES__/konyak-cli',
        processRunner: runner,
      );

      expect(
        client.executable,
        '/tmp/Konyak.AppDir/usr/share/konyak/konyak-cli',
      );
      expect(client.baseArguments, isEmpty);
    },
  );

  test(
    'default CLI client accepts explicit executable and script overrides',
    () {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      );

      final client = createDefaultKonyakCliClient(
        environment: const {
          'KONYAK_DART_EXECUTABLE': '/custom/dart',
          'KONYAK_CLI_SCRIPT': '/custom/konyak.dart',
        },
        processRunner: runner,
      );

      expect(client.executable, '/custom/dart');
      expect(client.baseArguments, const ['/custom/konyak.dart']);
      expect(client.workingDirectory, isNull);
    },
  );

  test('list-bottles failure includes startup diagnostics', () async {
    final client = KonyakCliClient(
      executable: 'dart',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 127,
          stdout: '',
          stderr: 'Failed to start dart: No such file or directory',
        ),
      ),
    );

    final result = await client.listBottles();

    expect(result, isA<BottleListLoadFailure>());
    final failure = result as BottleListLoadFailure;
    expect(failure.message, contains('exit code 127'));
    expect(failure.message, contains('Failed to start dart'));
  });

  test('converts missing executable failures into process results', () async {
    final result = await const DartIoProcessRunner().run(
      '/__missing_konyak_executable__',
      const ['list-bottles', '--json'],
    );

    expect(result.exitCode, 127);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('/__missing_konyak_executable__'));
  });

  test('Dart process runner passes app update handoff environment', () async {
    final result = await const DartIoProcessRunner().run('sh', const [
      '-c',
      r'printf "%s\n%s" "$KONYAK_APP_EXECUTABLE" "$KONYAK_APP_PID"',
    ]);

    expect(result.exitCode, 0);
    final lines = result.stdout.split('\n');
    expect(lines, hasLength(2));
    expect(lines[0], Platform.resolvedExecutable);
    expect(lines[1], '$pid');
  });

  test('returns a failure when the CLI exits with a non-zero code', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 64,
          stdout: '',
          stderr: 'Usage: konyak list-bottles --json\n',
        ),
      ),
    );

    final result = await client.listBottles();

    expect(result, isA<BottleListLoadFailure>());
    final failure = result as BottleListLoadFailure;
    expect(failure.exitCode, 64);
    expect(failure.message, contains('list-bottles failed'));
    expect(failure.diagnostic, contains('Usage: konyak'));
  });

  test('returns machine-readable list-bottles error messages', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 74,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "bottleRepositoryError",
                "message": "Cannot open file"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.listBottles();

    expect(result, isA<BottleListLoadFailure>());
    final failure = result as BottleListLoadFailure;
    expect(failure.exitCode, 74);
    expect(failure.message, 'Cannot open file');
  });

  test('returns a failure when the CLI stdout violates the contract', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":2,"bottles":[]}',
          stderr: '',
        ),
      ),
    );

    final result = await client.listBottles();

    expect(result, isA<BottleListLoadFailure>());
    final failure = result as BottleListLoadFailure;
    expect(failure.exitCode, 0);
    expect(failure.message, contains('Unsupported bottle list schema version'));
  });

  test(
    'inspects a bottle by invoking the JSON inspect-bottle contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.inspectBottle('steam');

      expect(runner.arguments, const ['inspect-bottle', 'steam', '--json']);
      expect(result, isA<LoadedBottleDetail>());

      final loaded = result as LoadedBottleDetail;
      expect(loaded.bottle.id, 'steam');
      expect(loaded.bottle.name, 'Steam');
    },
  );

  test('returns a typed missing result for bottle not-found JSON', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 66,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "bottleNotFound",
                "message": "Bottle not found.",
                "bottleId": "missing"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.inspectBottle('missing');

    expect(result, isA<MissingBottleDetail>());
    final missing = result as MissingBottleDetail;
    expect(missing.bottleId, 'missing');
    expect(missing.message, 'Bottle not found.');
  });

  test(
    'returns a detail failure when inspect-bottle exits without JSON',
    () async {
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: _FakeProcessRunner(
          result: const ProcessRunResult(
            exitCode: 64,
            stdout: '',
            stderr: 'Usage: konyak inspect-bottle <id> --json\n',
          ),
        ),
      );

      final result = await client.inspectBottle('steam');

      expect(result, isA<BottleDetailLoadFailure>());
      final failure = result as BottleDetailLoadFailure;
      expect(failure.exitCode, 64);
      expect(failure.diagnostic, contains('Usage: konyak'));
    },
  );

  test(
    'loads runtimes by invoking the JSON list-runtimes CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtimes": [
              {
                "id": "wine-stable-linux-x86_64",
                "name": "Wine Stable",
                "platform": "linux",
                "architecture": "x86_64",
                "runnerKind": "wine",
                "isBundled": false,
                "isUpdateable": true
              }
            ]
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.listKnownRuntimes();

      expect(runner.arguments, const ['list-runtimes', '--json']);
      expect(result, isA<LoadedRuntimeList>());

      final loaded = result as LoadedRuntimeList;
      expect(loaded.runtimes.single.id, 'wine-stable-linux-x86_64');
      expect(loaded.runtimes.single.runnerKind, 'wine');
    },
  );

  test('returns a runtime failure when list-runtimes exits non-zero', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 64,
          stdout: '',
          stderr: 'Usage: konyak list-runtimes --json\n',
        ),
      ),
    );

    final result = await client.listKnownRuntimes();

    expect(result, isA<RuntimeListLoadFailure>());
    final failure = result as RuntimeListLoadFailure;
    expect(failure.exitCode, 64);
    expect(failure.diagnostic, contains('Usage: konyak'));
  });

  test(
    'installs Konyak macOS Wine by invoking the JSON CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtime": {
              "id": "konyak-macos-wine",
              "name": "Konyak macOS Wine",
              "platform": "macos",
              "architecture": "x86_64",
              "runnerKind": "macosWine",
              "isBundled": false,
              "isUpdateable": true,
              "isInstalled": true
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.installMacosWine();

      expect(runner.arguments, const ['install-macos-wine', '--json']);
      expect(result, isA<InstalledRuntime>());
      final installed = result as InstalledRuntime;
      expect(installed.runtime.id, 'konyak-macos-wine');
      expect(installed.runtime.isInstalled, isTrue);
    },
  );

  test('reports runtime install progress from JSON lines', () async {
    final progressEvents = <RuntimeInstallProgress>[];
    final runner = _FakeProcessRunner(
      stdoutLines: const [
        '{"schemaVersion":1,"runtimeInstallProgress":{"stage":"downloading","message":"Downloading Konyak macOS Wine...","fraction":0.42}}',
        '{"schemaVersion":1,"runtime":{"id":"konyak-macos-wine","name":"Konyak macOS Wine","platform":"macos","architecture":"x86_64","runnerKind":"macosWine","isBundled":false,"isUpdateable":true,"isInstalled":true}}',
      ],
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {"schemaVersion":1,"runtimeInstallProgress":{"stage":"downloading","message":"Downloading Konyak macOS Wine...","fraction":0.42}}
          {"schemaVersion":1,"runtime":{"id":"konyak-macos-wine","name":"Konyak macOS Wine","platform":"macos","architecture":"x86_64","runnerKind":"macosWine","isBundled":false,"isUpdateable":true,"isInstalled":true}}
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.installMacosWine(
      onProgress: progressEvents.add,
    );

    expect(runner.arguments, const [
      'install-macos-wine',
      '--progress-json',
      '--json',
    ]);
    expect(progressEvents, hasLength(1));
    expect(progressEvents.single.message, 'Downloading Konyak macOS Wine...');
    expect(progressEvents.single.fraction, 0.42);
    expect(result, isA<InstalledRuntime>());
  });

  test('returns install failures from install-macos-wine JSON', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 75,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "macosWineInstallFailed",
                "message": "download failed"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.installMacosWine();

    expect(result, isA<RuntimeInstallLoadFailure>());
    final failure = result as RuntimeInstallLoadFailure;
    expect(failure.exitCode, 75);
    expect(failure.message, 'download failed');
  });

  test(
    'installs Konyak Linux Wine by invoking the JSON CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtime": {
              "id": "konyak-linux-wine",
              "name": "Konyak Linux Wine",
              "platform": "linux",
              "architecture": "x86_64",
              "runnerKind": "wine",
              "isBundled": false,
              "isUpdateable": true,
              "isInstalled": true
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.installLinuxWine();

      expect(runner.arguments, const ['install-linux-wine', '--json']);
      expect(result, isA<InstalledRuntime>());
      final installed = result as InstalledRuntime;
      expect(installed.runtime.id, 'konyak-linux-wine');
      expect(installed.runtime.isInstalled, isTrue);
    },
  );

  test('checks Konyak updates through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdate": {
              "appId": "konyak",
              "status": "available",
              "currentVersion": "1.0.0",
              "latestVersion": "1.1.0",
              "versionUrl": "https://api.github.com/repos/serika12345/Konyak/releases/latest",
              "archiveUrl": "https://example.invalid/Konyak.dmg"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.checkKonyakUpdate();

    expect(runner.arguments, const ['check-app-update', '--json']);
    expect(result, isA<LoadedUpdateCheck>());
    final loaded = result as LoadedUpdateCheck;
    expect(loaded.update.id, 'konyak');
    expect(loaded.update.status, 'available');
    expect(loaded.update.latestVersion, '1.1.0');
  });

  test('checks Konyak Wine updates through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtimeUpdate": {
              "runtimeId": "konyak-macos-wine",
              "status": "current",
              "currentVersion": "wine-devel-11.9",
              "latestVersion": "11.9"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.checkRuntimeUpdate('konyak-macos-wine');

    expect(runner.arguments, const [
      'check-runtime-update',
      'konyak-macos-wine',
      '--json',
    ]);
    expect(result, isA<LoadedUpdateCheck>());
    final loaded = result as LoadedUpdateCheck;
    expect(loaded.update.id, 'konyak-macos-wine');
    expect(loaded.update.status, 'current');
  });

  test('terminates Wine processes through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "wineProcessTermination": {
              "hasFailures": false,
              "bottles": []
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.terminateWineProcesses();

    expect(runner.arguments, const ['terminate-wine-processes', '--json']);
    expect(result, isA<TerminatedWineProcesses>());
  });

  test(
    'terminates Wine processes in one bottle through the JSON CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "wineProcessTermination": {
              "hasFailures": false,
              "bottles": [
                {
                  "bottleId": "steam",
                  "status": "terminated",
                  "runnerKind": "wineserver",
                  "executable": "wineserver",
                  "argv": ["wineserver", "-k"],
                  "processExitCode": 0
                }
              ]
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.terminateWineProcesses(bottleId: 'steam');

      expect(runner.arguments, const [
        'terminate-wine-processes',
        '--bottle',
        'steam',
        '--json',
      ]);
      expect(result, isA<TerminatedWineProcesses>());
    },
  );

  test('lists Wine processes through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "wineProcesses": {
              "processes": [
                {
                  "bottleId": "steam",
                  "processId": "00000034",
                  "executable": "C:\\\\Program Files\\\\Steam\\\\steam.exe",
                  "hostPath": "/bottles/steam/drive_c/Program Files/Steam/steam.exe",
                  "metadata": {
                    "fileDescription": "Steam Client",
                    "iconPath": "/bottles/steam/cache/icons/steam.ico"
                  }
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.listWineProcesses();

    expect(runner.arguments, const ['list-wine-processes', '--json']);
    expect(result, isA<LoadedWineProcesses>());
    final loaded = result as LoadedWineProcesses;
    expect(loaded.processes.single.bottleId, 'steam');
    expect(loaded.processes.single.processId, '00000034');
    expect(loaded.processes.single.metadata?.displayName, 'Steam Client');
    expect(
      loaded.processes.single.metadata?.iconPath,
      '/bottles/steam/cache/icons/steam.ico',
    );
  });

  test('terminates one Wine process through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "wineProcessTermination": {
              "hasFailures": false,
              "processes": [
                {
                  "bottleId": "steam",
                  "processId": "00000034",
                  "status": "terminated",
                  "runnerKind": "winedbg",
                  "executable": "winedbg",
                  "argv": ["winedbg", "--command", "kill", "00000034"],
                  "processExitCode": 0
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.terminateWineProcess(
      bottleId: 'steam',
      processId: '00000034',
    );

    expect(runner.arguments, const [
      'terminate-wine-process',
      '--bottle',
      'steam',
      '--process',
      '00000034',
      '--json',
    ]);
    expect(result, isA<TerminatedWineProcesses>());
  });

  test('installs Konyak updates through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdateInstall": {
              "appId": "konyak",
              "status": "installed",
              "currentVersion": "1.0.0",
              "installedVersion": "1.1.0",
              "archiveUrl": "https://example.invalid/Konyak-1.1.0.dmg",
              "installPath": "/tmp/Konyak-1.1.0.dmg"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.installKonyakUpdate();

    expect(runner.arguments, const ['install-app-update', '--json']);
    expect(result, isA<InstalledUpdate>());
    final installed = result as InstalledUpdate;
    expect(installed.update.id, 'konyak');
    expect(installed.update.installedVersion, '1.1.0');
  });

  test('installs runtime updates through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtime": {
              "id": "konyak-macos-wine",
              "name": "Konyak macOS Wine",
              "platform": "macos",
              "architecture": "x86_64",
              "runnerKind": "macosWine",
              "isBundled": false,
              "isUpdateable": true,
              "isInstalled": true
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.installRuntimeUpdate('konyak-macos-wine');

    expect(runner.arguments, const [
      'install-runtime-update',
      'konyak-macos-wine',
      '--json',
    ]);
    expect(result, isA<InstalledRuntime>());
    final installed = result as InstalledRuntime;
    expect(installed.runtime.id, 'konyak-macos-wine');
  });

  test('loads app settings through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "appearanceMode": "light",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.getAppSettings();

    expect(runner.arguments, const ['get-app-settings', '--json']);
    expect(result, isA<LoadedAppSettings>());
    final loaded = result as LoadedAppSettings;
    expect(loaded.settings.terminateWineProcessesOnClose, isFalse);
    expect(loaded.settings.defaultBottlePath, '/Volumes/Games/Bottles');
    expect(loaded.settings.appearanceMode, AppAppearanceMode.light);
    expect(loaded.settings.automaticallyCheckForKonyakUpdates, isTrue);
    expect(loaded.settings.automaticallyCheckForWineUpdates, isFalse);
  });

  test(
    'installs Linux file associations through the JSON CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout:
              '{"schemaVersion":1,"linuxFileAssociations":{"desktopEntryPath":"/apps/app.konyak.Konyak.desktop","mimeAppsPath":"/config/mimeapps.list","mimeTypes":["application/x-ms-dos-executable"]}}',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.installLinuxFileAssociations();

      expect(result.exitCode, 0);
      expect(runner.arguments, const [
        'install-linux-file-associations',
        '--json',
      ]);
    },
  );

  test('sets app settings through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "appearanceMode": "light",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.setAppSettings(
      settings: const AppSettingsSummary(
        terminateWineProcessesOnClose: false,
        defaultBottlePath: '/Volumes/Games/Bottles',
        appearanceMode: AppAppearanceMode.light,
        automaticallyCheckForKonyakUpdates: true,
        automaticallyCheckForWineUpdates: false,
      ),
    );

    expect(runner.arguments, const [
      'set-app-settings',
      '--settings-json',
      '{"terminateWineProcessesOnClose":false,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"light","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":false}',
      '--json',
    ]);
    expect(result, isA<LoadedAppSettings>());
    final loaded = result as LoadedAppSettings;
    expect(loaded.settings.defaultBottlePath, '/Volumes/Games/Bottles');
    expect(loaded.settings.appearanceMode, AppAppearanceMode.light);
  });

  test(
    'loads and sets system appearance through the app settings contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "appearanceMode": "system",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final loadedResult = await client.getAppSettings();

      expect(loadedResult, isA<LoadedAppSettings>());
      expect(
        (loadedResult as LoadedAppSettings).settings.appearanceMode,
        AppAppearanceMode.system,
      );

      await client.setAppSettings(
        settings: const AppSettingsSummary(
          defaultBottlePath: '/Volumes/Games/Bottles',
          appearanceMode: AppAppearanceMode.system,
        ),
      );

      expect(runner.arguments, const [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"system","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":true}',
        '--json',
      ]);
    },
  );

  test(
    'creates a bottle by invoking the JSON create-bottle contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.createBottle(
        name: 'Steam',
        windowsVersion: 'win10',
      );

      expect(runner.arguments, const [
        'create-bottle',
        '--name',
        'Steam',
        '--windows-version',
        'win10',
        '--json',
      ]);
      expect(result, isA<CreatedBottle>());

      final created = result as CreatedBottle;
      expect(created.bottle.id, 'steam');
    },
  );

  test('returns a typed conflict result for create-bottle conflicts', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 73,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "bottleAlreadyExists",
                "message": "Bottle already exists.",
                "bottleId": "steam"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.createBottle(
      name: 'Steam',
      windowsVersion: 'win10',
    );

    expect(result, isA<ExistingBottle>());
    final conflict = result as ExistingBottle;
    expect(conflict.bottleId, 'steam');
  });

  test(
    'returns a create failure when create-bottle exits without JSON',
    () async {
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: _FakeProcessRunner(
          result: const ProcessRunResult(
            exitCode: 64,
            stdout: '',
            stderr: 'Usage: konyak create-bottle --name <name> --json\n',
          ),
        ),
      );

      final result = await client.createBottle(
        name: 'Steam',
        windowsVersion: 'win10',
      );

      expect(result, isA<BottleCreateLoadFailure>());
      final failure = result as BottleCreateLoadFailure;
      expect(failure.exitCode, 64);
      expect(failure.diagnostic, contains('Usage: konyak'));
    },
  );

  test(
    'deletes a bottle through the JSON delete-bottle CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "deletedBottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.deleteBottle('steam');

      expect(runner.arguments, const ['delete-bottle', 'steam', '--json']);
      expect(result, isA<DeletedBottle>());

      final deleted = result as DeletedBottle;
      expect(deleted.bottle.id, 'steam');
      expect(deleted.bottle.name, 'Steam');
    },
  );

  test(
    'renames a bottle through the JSON rename-bottle CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam-games",
              "name": "Steam Games",
              "path": "/home/user/.local/share/konyak/bottles/steam-games",
              "windowsVersion": "win10"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.renameBottle(
        bottleId: 'steam',
        name: 'Steam Games',
      );

      expect(runner.arguments, const [
        'rename-bottle',
        'steam',
        '--name',
        'Steam Games',
        '--json',
      ]);
      expect(result, isA<UpdatedBottle>());

      final updated = result as UpdatedBottle;
      expect(updated.bottle.id, 'steam-games');
      expect(updated.bottle.name, 'Steam Games');
    },
  );

  test('moves a bottle through the JSON move-bottle CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/mnt/games/Steam",
              "windowsVersion": "win10"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.moveBottle(
      bottleId: 'steam',
      path: '/mnt/games/Steam',
    );

    expect(runner.arguments, const [
      'move-bottle',
      'steam',
      '--path',
      '/mnt/games/Steam',
      '--json',
    ]);
    expect(result, isA<UpdatedBottle>());

    final updated = result as UpdatedBottle;
    expect(updated.bottle.path, '/mnt/games/Steam');
  });

  test('returns missing bottle when delete-bottle cannot find it', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 66,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "bottleNotFound",
                "message": "Bottle not found.",
                "bottleId": "missing"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.deleteBottle('missing');

    expect(result, isA<MissingBottleDelete>());
    final missing = result as MissingBottleDelete;
    expect(missing.bottleId, 'missing');
    expect(missing.message, 'Bottle not found.');
  });

  test('sets a bottle Windows version through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win11"
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.setWindowsVersion(
      bottleId: 'steam',
      windowsVersion: 'win11',
    );

    expect(runner.arguments, const [
      'set-windows-version',
      'steam',
      '--windows-version',
      'win11',
      '--json',
    ]);
    expect(result, isA<UpdatedBottle>());

    final updated = result as UpdatedBottle;
    expect(updated.bottle.id, 'steam');
    expect(updated.bottle.windowsVersion, 'win11');
  });

  test(
    'returns missing bottle when set-windows-version cannot find it',
    () async {
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: _FakeProcessRunner(
          result: const ProcessRunResult(
            exitCode: 66,
            stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "bottleNotFound",
                "message": "Bottle not found.",
                "bottleId": "missing"
              }
            }
          ''',
            stderr: '',
          ),
        ),
      );

      final result = await client.setWindowsVersion(
        bottleId: 'missing',
        windowsVersion: 'win11',
      );

      expect(result, isA<MissingBottleUpdate>());
      final missing = result as MissingBottleUpdate;
      expect(missing.bottleId, 'missing');
    },
  );

  test('runs a program through the JSON run-program CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.exe"],
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.runProgram(
      bottleId: 'steam',
      programPath: '/downloads/setup.exe',
    );

    expect(runner.arguments, const [
      'run-program',
      'steam',
      '--program',
      '/downloads/setup.exe',
      '--json',
    ]);
    expect(result, isA<CompletedProgramRun>());

    final completed = result as CompletedProgramRun;
    expect(completed.run.bottleId, 'steam');
    expect(completed.run.runnerKind, 'wine');
    expect(completed.run.executable, 'wine');
    expect(completed.run.workingDirectory, isNull);
    expect(completed.run.argv, const ['wine', '/downloads/setup.exe']);
    expect(completed.run.processExitCode, 0);
  });

  test('pins a program through the JSON pin-program CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
              "windowsVersion": "win10",
              "pinnedPrograms": [
                {
                  "name": "Steam",
                  "path": "/downloads/Steam.exe",
                  "removable": false
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.pinProgram(
      bottleId: 'steam',
      name: 'Steam',
      programPath: '/downloads/Steam.exe',
    );

    expect(runner.arguments, const [
      'pin-program',
      'steam',
      '--name',
      'Steam',
      '--program',
      '/downloads/Steam.exe',
      '--json',
    ]);
    expect(result, isA<UpdatedBottle>());
    final updated = result as UpdatedBottle;
    expect(updated.bottle.pinnedPrograms.single.path, '/downloads/Steam.exe');
  });

  test(
    'unpins a program through the JSON unpin-program CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.unpinProgram(
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
      );

      expect(runner.arguments, const [
        'unpin-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ]);
      expect(result, isA<UpdatedBottle>());
      final updated = result as UpdatedBottle;
      expect(updated.bottle.pinnedPrograms, isEmpty);
    },
  );

  test(
    'renames a pinned program through the JSON rename-pinned-program contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
              "windowsVersion": "win10",
              "pinnedPrograms": [
                {
                  "name": "Steam Client",
                  "path": "/downloads/Steam.exe",
                  "removable": false
                }
              ]
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.renamePinnedProgram(
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
        name: 'Steam Client',
      );

      expect(runner.arguments, const [
        'rename-pinned-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--name',
        'Steam Client',
        '--json',
      ]);
      expect(result, isA<UpdatedBottle>());
      final updated = result as UpdatedBottle;
      expect(updated.bottle.pinnedPrograms.single.name, 'Steam Client');
    },
  );

  test(
    'loads program settings through the JSON get-program-settings contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "programSettings": {
              "bottleId": "steam",
              "programPath": "/downloads/Steam.exe",
              "settings": {
                "locale": "ja_JP.UTF-8",
                "arguments": "-silent",
                "environment": {
                  "STEAM_COMPAT_DATA_PATH": "/compat"
                }
              }
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.getProgramSettings(
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
      );

      expect(runner.arguments, const [
        'get-program-settings',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ]);
      expect(result, isA<LoadedProgramSettings>());
      final loaded = result as LoadedProgramSettings;
      expect(loaded.bottleId, 'steam');
      expect(loaded.programPath, '/downloads/Steam.exe');
      expect(loaded.settings.locale, 'ja_JP.UTF-8');
      expect(loaded.settings.arguments, '-silent');
      expect(loaded.settings.environment.unlockView, {
        'STEAM_COMPAT_DATA_PATH': '/compat',
      });
    },
  );

  test(
    'sets program settings through the JSON set-program-settings contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "programSettings": {
              "bottleId": "steam",
              "programPath": "/downloads/Steam.exe",
              "settings": {
                "locale": "ja_JP.UTF-8",
                "arguments": "-silent",
                "environment": {
                  "STEAM_COMPAT_DATA_PATH": "/compat"
                }
              }
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.setProgramSettings(
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
        settings: ProgramSettingsSummary(
          locale: 'ja_JP.UTF-8',
          arguments: '-silent',
          environment: {'STEAM_COMPAT_DATA_PATH': '/compat'},
        ),
      );

      expect(runner.arguments, const [
        'set-program-settings',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--settings-json',
        '{"locale":"ja_JP.UTF-8","arguments":"-silent","environment":{"STEAM_COMPAT_DATA_PATH":"/compat"}}',
        '--json',
      ]);
      expect(result, isA<LoadedProgramSettings>());
      final loaded = result as LoadedProgramSettings;
      expect(loaded.settings.locale, 'ja_JP.UTF-8');
      expect(loaded.settings.arguments, '-silent');
      expect(loaded.settings.environment.unlockView, {
        'STEAM_COMPAT_DATA_PATH': '/compat',
      });
    },
  );

  test(
    'runs a bottle utility through the JSON run-bottle-command CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "winecfg",
              "runnerKind": "macosWine",
              "executable": "/runtime/bin/wine64",
              "workingDirectory": "/runtime/bin",
              "argv": ["/runtime/bin/wine64", "winecfg"],
              "logPath": "/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.runBottleCommand(
        bottleId: 'steam',
        command: 'winecfg',
      );

      expect(runner.arguments, const [
        'run-bottle-command',
        'steam',
        '--command',
        'winecfg',
        '--json',
      ]);
      expect(result, isA<CompletedProgramRun>());

      final completed = result as CompletedProgramRun;
      expect(completed.run.bottleId, 'steam');
      expect(completed.run.programPath, 'winecfg');
      expect(completed.run.runnerKind, 'macosWine');
      expect(completed.run.argv, const ['/runtime/bin/wine64', 'winecfg']);
    },
  );

  test(
    'opens a bottle location through the JSON open-bottle-location CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "openedLocation": {
              "bottleId": "steam",
              "location": "c-drive",
              "path": "/bottles/steam/drive_c"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.openBottleLocation(
        bottleId: 'steam',
        location: 'c-drive',
      );

      expect(runner.arguments, const [
        'open-bottle-location',
        'steam',
        '--location',
        'c-drive',
        '--json',
      ]);
      expect(result, isA<OpenedBottleLocation>());

      final opened = result as OpenedBottleLocation;
      expect(opened.bottleId, 'steam');
      expect(opened.location, 'c-drive');
      expect(opened.path, '/bottles/steam/drive_c');
    },
  );

  test(
    'opens a program location through the JSON open-program-location contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "openedProgramLocation": {
              "bottleId": "steam",
              "programPath": "/downloads/Steam.exe",
              "path": "/downloads/Steam.exe"
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.openProgramLocation(
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
      );

      expect(runner.arguments, const [
        'open-program-location',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ]);
      expect(result, isA<OpenedProgramLocation>());

      final opened = result as OpenedProgramLocation;
      expect(opened.bottleId, 'steam');
      expect(opened.programPath, '/downloads/Steam.exe');
      expect(opened.path, '/downloads/Steam.exe');
    },
  );

  test(
    'loads bottle programs through the JSON list-bottle-programs CLI contract',
    () async {
      final runner = _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottlePrograms": {
              "bottleId": "steam",
              "programs": [
                {
                  "id": "steam",
                  "name": "Steam",
                  "path": "/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk",
                  "source": "globalStartMenu",
                  "metadata": {
                    "architecture": "x86_64",
                    "fileDescription": "Steam Client",
                    "productName": "Steam",
                    "companyName": "Valve",
                    "fileVersion": "1.2.3",
                    "productVersion": "4.5.6",
                    "iconPath": "/bottles/steam/cache/icons/steam.ico"
                  }
                }
              ]
            }
          }
        ''',
          stderr: '',
        ),
      );
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: runner,
      );

      final result = await client.listBottlePrograms('steam');

      expect(runner.arguments, const [
        'list-bottle-programs',
        'steam',
        '--json',
      ]);
      expect(result, isA<LoadedBottlePrograms>());

      final loaded = result as LoadedBottlePrograms;
      expect(loaded.bottleId, 'steam');
      expect(loaded.programs.single.name, 'Steam');
      expect(loaded.programs.single.source, 'globalStartMenu');
      expect(loaded.programs.single.metadata?.architecture, 'x86_64');
      expect(loaded.programs.single.metadata?.displayName, 'Steam Client');
      expect(
        loaded.programs.single.metadata?.iconPath,
        '/bottles/steam/cache/icons/steam.ico',
      );
    },
  );

  test('loads winetricks verbs through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "winetricks": {
              "categories": [
                {
                  "id": "dlls",
                  "name": "DLLs",
                  "verbs": [
                    {
                      "id": "corefonts",
                      "name": "corefonts",
                      "description": "Microsoft Core Fonts"
                    }
                  ]
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.listWinetricksVerbs();

    expect(runner.arguments, const ['list-winetricks-verbs', '--json']);
    expect(result, isA<LoadedWinetricksVerbs>());

    final loaded = result as LoadedWinetricksVerbs;
    expect(loaded.categories.single.id, 'dlls');
    expect(loaded.categories.single.verbs.single.name, 'corefonts');
    expect(
      loaded.categories.single.verbs.single.description,
      'Microsoft Core Fonts',
    );
  });

  test('runs a winetricks verb through the JSON CLI contract', () async {
    final runner = _FakeProcessRunner(
      result: const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "corefonts",
              "runnerKind": "macosWinetricks",
              "executable": "/runtime/winetricks",
              "workingDirectory": "/runtime",
              "argv": ["/runtime/winetricks", "corefonts"],
              "logPath": "/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    );
    final client = KonyakCliClient(executable: 'konyak', processRunner: runner);

    final result = await client.runWinetricksVerb(
      bottleId: 'steam',
      verb: 'corefonts',
    );

    expect(runner.arguments, const [
      'run-winetricks',
      'steam',
      '--verb',
      'corefonts',
      '--json',
    ]);
    expect(result, isA<CompletedProgramRun>());

    final completed = result as CompletedProgramRun;
    expect(completed.run.programPath, 'corefonts');
    expect(completed.run.argv, const ['/runtime/winetricks', 'corefonts']);
  });

  test('returns unsupported program type from run-program JSON', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 65,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "unsupportedProgramType",
                "message": "Program type is not supported.",
                "programPath": "/downloads/readme.txt"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.runProgram(
      bottleId: 'steam',
      programPath: '/downloads/readme.txt',
    );

    expect(result, isA<UnsupportedProgramRun>());
    final unsupported = result as UnsupportedProgramRun;
    expect(unsupported.programPath, '/downloads/readme.txt');
    expect(unsupported.message, 'Program type is not supported.');
  });

  test('returns missing bottle from run-program JSON', () async {
    final client = KonyakCliClient(
      executable: 'konyak',
      processRunner: _FakeProcessRunner(
        result: const ProcessRunResult(
          exitCode: 66,
          stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "bottleNotFound",
                "message": "Bottle not found.",
                "bottleId": "missing"
              }
            }
          ''',
          stderr: '',
        ),
      ),
    );

    final result = await client.runProgram(
      bottleId: 'missing',
      programPath: '/downloads/setup.exe',
    );

    expect(result, isA<MissingProgramRunBottle>());
    final missing = result as MissingProgramRunBottle;
    expect(missing.bottleId, 'missing');
  });

  test(
    'returns a typed failure when run-program cannot start the runner',
    () async {
      final client = KonyakCliClient(
        executable: 'konyak',
        processRunner: _FakeProcessRunner(
          result: const ProcessRunResult(
            exitCode: 75,
            stdout: '''
            {
              "schemaVersion": 1,
              "error": {
                "code": "programRunFailed",
                "message": "wine not found",
                "bottleId": "steam",
                "programPath": "/downloads/setup.exe",
                "runnerKind": "wine",
                "executable": "wine",
                "workingDirectory": null,
                "argv": ["wine", "/downloads/setup.exe"],
                "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log"
              }
            }
          ''',
            stderr: '',
          ),
        ),
      );

      final result = await client.runProgram(
        bottleId: 'steam',
        programPath: '/downloads/setup.exe',
      );

      expect(result, isA<FailedProgramRun>());
      final failure = result as FailedProgramRun;
      expect(failure.bottleId, 'steam');
      expect(failure.programPath, '/downloads/setup.exe');
      expect(failure.runnerKind, 'wine');
      expect(failure.executable, 'wine');
      expect(failure.workingDirectory, isNull);
      expect(failure.argv, const ['wine', '/downloads/setup.exe']);
      expect(
        failure.logPath,
        '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
      );
      expect(failure.message, 'wine not found');
    },
  );
}

final class _FakeProcessRunner implements ProcessRunner {
  _FakeProcessRunner({
    required this.result,
    this.stdoutLines = const <String>[],
  });

  final ProcessRunResult result;
  final List<String> stdoutLines;
  String? executable;
  String? workingDirectory;
  List<String> arguments = const [];
  Map<String, String> environment = const <String, String>{};

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    void Function(String line)? onStdoutLine,
  }) async {
    this.executable = executable;
    this.arguments = List.unmodifiable(arguments);
    this.workingDirectory = workingDirectory;
    this.environment = Map.unmodifiable(environment);

    for (final line in stdoutLines) {
      onStdoutLine?.call(line);
    }

    return result;
  }
}
