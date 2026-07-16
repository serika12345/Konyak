import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/io/repository_storage_io.dart';
import 'package:test/test.dart';

void main() {
  final bottle = BottleRecord(
    id: 'games',
    name: 'Games',
    path: '/bottles/games',
    windowsVersion: 'win10',
  );

  test('defaults regular program CWD to the executable host parent', () {
    expect(
      resolveProgramWorkingDirectory(
        bottle: bottle,
        executableHostPath: ProgramPath(
          '/bottles/games/drive_c/Games/Touhou/th06.exe',
        ),
        setting: const ProgramWorkingDirectorySetting.executableDirectory(),
      ),
      Option.of(
        ProgramWorkingDirectoryPath('/bottles/games/drive_c/Games/Touhou'),
      ),
    );
  });

  test('resolves a portable custom C drive directory inside the bottle', () {
    expect(
      resolveProgramWorkingDirectory(
        bottle: bottle,
        executableHostPath: ProgramPath(
          '/bottles/games/drive_c/Games/Touhou/th06.exe',
        ),
        setting: ProgramWorkingDirectorySetting.custom(
          WindowsProgramWorkingDirectoryPath(r'C:\Games\Shared Data'),
        ),
      ),
      Option.of(
        ProgramWorkingDirectoryPath('/bottles/games/drive_c/Games/Shared Data'),
      ),
    );
  });

  test('maps Z drive executable paths to their host parent', () {
    expect(
      resolveProgramWorkingDirectory(
        bottle: bottle,
        executableHostPath: ProgramPath(r'Z:\Applications\Game\game.exe'),
        setting: const ProgramWorkingDirectorySetting.executableDirectory(),
      ),
      Option.of(ProgramWorkingDirectoryPath('/Applications/Game')),
    );
  });

  test('rejects unsafe executable paths during default CWD resolution', () {
    for (final path in <String>[
      r'C:\Games\..\outside.exe',
      r'Z:\Applications\.\game.exe',
      'Z:\\Applications\\game.exe\n',
    ]) {
      expect(
        resolveProgramWorkingDirectory(
          bottle: bottle,
          executableHostPath: ProgramPath(path),
          setting: const ProgramWorkingDirectorySetting.executableDirectory(),
        ),
        const Option<ProgramWorkingDirectoryPath>.none(),
        reason: path,
      );
    }
  });

  test('rejects custom paths outside the bottle C drive', () {
    for (final path in <String>[
      r'Z:\Users\user\Games',
      r'D:\Games',
      r'C:\Games\..\outside',
      r'C:relative',
      '/tmp/games',
    ]) {
      expect(
        () => WindowsProgramWorkingDirectoryPath(path),
        throwsA(isA<ArgumentError>()),
        reason: path,
      );
    }
  });

  test('round trips custom working directory settings on disk', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-working-directory-settings-test-',
    );
    addTearDown(() => tempDirectory.deleteSync(recursive: true));
    final path = '${tempDirectory.path}/settings.json';
    final settings = ProgramSettingsRecord(
      workingDirectory: ProgramWorkingDirectorySetting.custom(
        WindowsProgramWorkingDirectoryPath(r'C:\Games\Touhou'),
      ),
    );

    writeProgramSettingsJson(path: path, settings: settings);

    final restored = readProgramSettingsJson(path);
    expect(restored.workingDirectory, settings.workingDirectory);
  });
}
