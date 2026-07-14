import 'package:konyak_cli/src/io/repository_storage_io.dart';
import 'package:test/test.dart';

void main() {
  test('rejects persisted profiles with more than 64 pre-install actions', () {
    final result = programProfileRecordsFromJson(<Object?>[
      _profile(<Object?>[
        for (var index = 0; index < 65; index++)
          <String, Object?>{'kind': 'winetricks', 'verb': 'verb$index'},
      ]),
    ]);

    expect(result.isNone(), isTrue);
  });

  test('rejects persisted profiles with duplicate winetricks verbs', () {
    final result = programProfileRecordsFromJson(<Object?>[
      _profile(<Object?>[
        <String, Object?>{'kind': 'winetricks', 'verb': 'corefonts'},
        <String, Object?>{'kind': 'winetricks', 'verb': 'corefonts'},
      ]),
    ]);

    expect(result.isNone(), isTrue);
  });

  test('rejects persisted profiles with duplicate native DLL targets', () {
    final result = programProfileRecordsFromJson(<Object?>[
      _profile(<Object?>[_nativeAction('first'), _nativeAction('second')]),
    ]);

    expect(result.isNone(), isTrue);
  });
}

Map<String, Object?> _profile(List<Object?> actions) => <String, Object?>{
  'profileSchemaVersion': 1,
  'profileId': 'synthetic',
  'profileVersion': 1,
  'profileSourceKind': 'builtin',
  'profileSourceId': 'synthetic.json',
  'profileDigest': 'a' * 64,
  'managedProgramPath': r'C:\Synthetic\Synthetic.exe',
  'compatibilityProfileId': 'synthetic',
  'compatibilityProfileVersion': 1,
  'installerResource': <String, Object?>{
    'kind': 'https',
    'url': 'https://downloads.example.test/Setup.exe',
    'sha256': 'b' * 64,
    'fileName': 'Setup.exe',
  },
  'preInstallActions': actions,
};

Map<String, Object?> _nativeAction(String componentId) => <String, Object?>{
  'kind': 'nativeDll',
  'componentId': componentId,
  'machine': 'x86',
  'destination': 'windowsSysWow64',
  'targetFileName': 'component.dll',
  'resource': <String, Object?>{
    'kind': 'https',
    'url': 'https://downloads.example.test/$componentId.dll',
    'sha256': 'c' * 64,
    'fileName': '$componentId.dll',
  },
};
