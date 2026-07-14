import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/io/wine_path_mapping.dart';
import 'package:test/test.dart';

void main() {
  final bottle = BottleRecord(
    id: 'test',
    name: 'Test',
    path: '/tmp/konyak-bottle',
    windowsVersion: 'win10',
  );

  group('wineWindowsPathToHostPath', () {
    test('maps supported absolute Windows and POSIX paths', () {
      final cases = <String, String>{
        r'C:\Program Files/Test\Test.exe':
            '/tmp/konyak-bottle/drive_c/Program Files/Test/Test.exe',
        'c:/Games\\Test.exe': '/tmp/konyak-bottle/drive_c/Games/Test.exe',
        r'z:\Applications/Test.app': '/Applications/Test.app',
        'Z:/Applications/Test.app': '/Applications/Test.app',
        '/Applications/Test.app': '/Applications/Test.app',
      };

      cases.forEach((windowsPath, expected) {
        expect(
          wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath),
          Option.of(expected),
          reason: windowsPath,
        );
      });
    });

    test('returns none for unsupported and drive-relative paths', () {
      final invalidPaths = <String>[
        'relative.exe',
        r'C:',
        r'Z:',
        r'C:relative.exe',
        r'Z:relative.exe',
        r'D:\Games\Test.exe',
      ];

      for (final windowsPath in invalidPaths) {
        expect(
          wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath),
          const Option<String>.none(),
          reason: windowsPath,
        );
      }
    });

    test('returns none for dot segments in Windows and POSIX paths', () {
      final invalidPaths = <String>[
        r'C:\..\outside.exe',
        r'C:\Program Files\.\Test.exe',
        'c:/Games/../outside.exe',
        r'Z:\..\private\outside.exe',
        '/Applications/./Test.app',
        '/Applications/../Applications/Test.app',
      ];

      for (final windowsPath in invalidPaths) {
        expect(
          wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath),
          const Option<String>.none(),
          reason: windowsPath,
        );
      }
    });

    test('returns none for control characters in Windows and POSIX paths', () {
      final invalidPaths = <String>[
        'C:\\Games\\\u0000Test.exe',
        'C:\\Games\\Test\u001f.exe',
        'C:\\Games\\Test\u007f.exe',
        'C:\\Games\\Test.exe\n',
        '/Applications/\u0000Test.app',
        '/Applications/Test\u0085.app',
      ];

      for (final windowsPath in invalidPaths) {
        expect(
          wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath),
          const Option<String>.none(),
        );
      }
    });
  });
}
