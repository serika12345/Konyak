import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:konyak_cli/src/domain/program/program_profile_catalog.dart';
import 'package:konyak_cli/src/domain/program/program_profile_models.dart';
import 'package:konyak_cli/src/io/program_profile_catalog_io.dart'
    show
        DartIoInstallProfileCatalog,
        konyakProfileSchemaFileName,
        konyakProfileSchemaUri,
        resolveBuiltinInstallProfileDirectory,
        resolveBuiltinInstallProfileSchemaPath;
import 'package:test/test.dart';

void main() {
  test('loads the built-in Steam profile from the JSON directory', () {
    final catalog = DartIoInstallProfileCatalog.fromDirectory(
      'profiles',
      schemaPath: 'profiles/$konyakProfileSchemaFileName',
    );
    final profile = catalog.profiles.single;

    expect(profile.id.value, 'steam');
    expect(profile.sourceKind, ProfileSourceKind.builtin);
    expect(profile.sourceId.value, 'steam.json');
    expect(
      profile.manifestDigest.value,
      sha256.convert(File('profiles/steam.json').readAsBytesSync()).toString(),
    );
    expect(profile.installerResource.kind.value, 'https');
    expect(
      profile.installerResource.url.value,
      'https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe',
    );
    expect(
      profile.installerResource.sha256.value,
      '7d3654531c32d941b8cae81c4137fc542172bfa9635f169cb392f245a0a12bcb',
    );
    expect(profile.installerResource.fileName.value, 'SteamSetup.exe');
    expect(
      profile.installerCompletion.match(
        () => throw StateError('Steam installer completion is missing.'),
        (completion) => completion,
      ),
      InstallerCompletionRecord(ignoreChildExecutable: 'steam.exe'),
    );
    expect(
      profile.preInstallActions.map(preInstallActionId).map((id) => id.value),
      [
        'corefonts',
        'vcrun2022',
        'd3dcompiler_47-x86',
        'd3dcompiler_47-x64',
        'fakejapanese',
      ],
    );
    final nativeActions = profile.preInstallActions
        .whereType<NativeDllPreInstallAction>()
        .toList(growable: false);
    expect(nativeActions.first.machine, NativeDllMachine.x86);
    expect(
      nativeActions.first.destination,
      NativeDllDestination.windowsSysWow64,
    );
    expect(
      nativeActions.first.resource.url.value,
      'https://raw.githubusercontent.com/mozilla/fxc2/'
      '9aba9b11079303d5577e0e3eb455f4d00f3b5946/'
      'dll/d3dcompiler_47_32.dll',
    );
    expect(
      nativeActions.first.resource.sha256.value,
      '2ad0d4987fc4624566b190e747c9d95038443956ed816abfd1e2d389b5ec0851',
    );
    expect(nativeActions.last.machine, NativeDllMachine.x64);
    expect(
      nativeActions.last.destination,
      NativeDllDestination.windowsSystem32,
    );
    expect(
      nativeActions.last.resource.sha256.value,
      '4432bbd1a390874f3f0a503d45cc48d346abc3a8c0213c289f4b615bf0ee84f3',
    );
    expect(
      profile.managedProgramPath.value,
      r'C:\Program Files (x86)\Steam\Steam.exe',
    );
    expect(profile.runCompletionPolicy.value, 'launchOnly');
    expect(profile.compatibilityProfile.childProcessRules, [
      ChildProcessCompatibilityRule(
        executableSuffix: 'steamwebhelper.exe',
        appendArgumentsIfMissing: const [
          '--no-sandbox',
          '--in-process-gpu',
          '--disable-gpu',
        ],
      ),
    ]);
  });

  test('loads a profile with a declarative HTTPS installer resource', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-installer-resource-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    profile['installerResource'] = _validInstallerResourceJson();
    File(
      '${temporaryDirectory.path}/valid.json',
    ).writeAsStringSync(jsonEncode(profile));

    final catalog = DartIoInstallProfileCatalog.fromDirectory(
      temporaryDirectory.path,
      schemaPath: 'profiles/$konyakProfileSchemaFileName',
    );

    expect(catalog.profiles.single.id.value, 'steam');
  });

  test('allows a profile to omit installer completion behavior', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-no-installer-completion-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
              as Map<String, Object?>
          ..remove('installerCompletion');
    File(
      '${temporaryDirectory.path}/valid.json',
    ).writeAsStringSync(jsonEncode(profile));

    final catalog = DartIoInstallProfileCatalog.fromDirectory(
      temporaryDirectory.path,
      schemaPath: 'profiles/$konyakProfileSchemaFileName',
    );

    expect(catalog.profiles.single.installerCompletion.isNone(), isTrue);
  });

  test('rejects installer completion on a Linux profile', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-linux-installer-completion-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    profile['platforms'] = <String>['linux'];
    File(
      '${temporaryDirectory.path}/invalid.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  final invalidInstallerCompletions = <String, Object?>{
    'non-object value': 'steam.exe',
    'empty executable basename': <String, Object?>{
      'ignoreChildExecutable': '.exe',
    },
    'non-EXE executable basename': <String, Object?>{
      'ignoreChildExecutable': 'steam',
    },
    'nested POSIX executable basename': <String, Object?>{
      'ignoreChildExecutable': 'nested/steam.exe',
    },
    'nested Windows executable basename': <String, Object?>{
      'ignoreChildExecutable': r'nested\steam.exe',
    },
    'control character in executable basename': <String, Object?>{
      'ignoreChildExecutable': 'steam\u0000.exe',
    },
    'executable basename longer than 255 characters': <String, Object?>{
      'ignoreChildExecutable': '${'s' * 252}.exe',
    },
    'unknown field': <String, Object?>{
      'ignoreChildExecutable': 'steam.exe',
      'environment': <String, String>{'ARBITRARY': '1'},
    },
  };
  invalidInstallerCompletions.forEach((description, completionValue) {
    test('rejects installer completion with $description', () {
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'konyak-profile-invalid-installer-completion-test-',
      );
      addTearDown(() {
        if (temporaryDirectory.existsSync()) {
          temporaryDirectory.deleteSync(recursive: true);
        }
      });
      final profile =
          jsonDecode(File('profiles/steam.json').readAsStringSync())
              as Map<String, Object?>;
      profile['installerCompletion'] = completionValue;
      File(
        '${temporaryDirectory.path}/invalid-installer-completion.json',
      ).writeAsStringSync(jsonEncode(profile));

      expect(
        () => DartIoInstallProfileCatalog.fromDirectory(
          temporaryDirectory.path,
          schemaPath: 'profiles/$konyakProfileSchemaFileName',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('installerCompletion'),
          ),
        ),
      );
    });
  });

  final invalidInstallerResources = <String, Map<String, Object?>>{
    'unsupported kind': <String, Object?>{
      ..._validInstallerResourceJson(),
      'kind': 'http',
    },
    'non-HTTPS URL': <String, Object?>{
      ..._validInstallerResourceJson(),
      'url': 'http://downloads.example.test/Setup.exe',
    },
    'URL without a host': <String, Object?>{
      ..._validInstallerResourceJson(),
      'url': 'https:///Setup.exe',
    },
    'URL with userinfo': <String, Object?>{
      ..._validInstallerResourceJson(),
      'url': 'https://user@downloads.example.test/Setup.exe',
    },
    'URL with a fragment': <String, Object?>{
      ..._validInstallerResourceJson(),
      'url': 'https://downloads.example.test/Setup.exe#fragment',
    },
    'invalid SHA-256': <String, Object?>{
      ..._validInstallerResourceJson(),
      'sha256': '0123456789abcdef',
    },
    'nested POSIX file name': <String, Object?>{
      ..._validInstallerResourceJson(),
      'fileName': 'nested/Setup.exe',
    },
    'nested Windows file name': <String, Object?>{
      ..._validInstallerResourceJson(),
      'fileName': r'nested\Setup.exe',
    },
    'unsupported installer extension': <String, Object?>{
      ..._validInstallerResourceJson(),
      'fileName': 'Setup.zip',
    },
    'unknown field': <String, Object?>{
      ..._validInstallerResourceJson(),
      'arbitraryCommand': 'not permitted',
    },
  };
  invalidInstallerResources.forEach((description, installerResource) {
    test('rejects installer resource with $description', () {
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'konyak-profile-invalid-installer-resource-test-',
      );
      addTearDown(() {
        if (temporaryDirectory.existsSync()) {
          temporaryDirectory.deleteSync(recursive: true);
        }
      });
      final profile =
          jsonDecode(File('profiles/steam.json').readAsStringSync())
              as Map<String, Object?>;
      profile['installerResource'] = installerResource;
      File(
        '${temporaryDirectory.path}/invalid-installer.json',
      ).writeAsStringSync(jsonEncode(profile));

      expect(
        () => DartIoInstallProfileCatalog.fromDirectory(
          temporaryDirectory.path,
          schemaPath: 'profiles/$konyakProfileSchemaFileName',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('requires an installer resource', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-required-installer-resource-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
              as Map<String, Object?>
          ..remove('installerResource');
    File(
      '${temporaryDirectory.path}/missing-installer.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('installerResource'),
        ),
      ),
    );
  });

  test('rejects unsafe dependency winetricks verbs', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-unsafe-winetricks-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    profile['installerResource'] = _validInstallerResourceJson();
    profile['preInstallActions'] = [
      {'kind': 'winetricks', 'verb': 'corefonts;rm'},
    ];
    File(
      '${temporaryDirectory.path}/unsafe-winetricks.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('preInstallActions'),
        ),
      ),
    );
  });

  test('rejects more than 64 dependency winetricks verbs', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-winetricks-limit-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    profile['installerResource'] = _validInstallerResourceJson();
    profile['preInstallActions'] = [
      for (var index = 0; index < 65; index++)
        {'kind': 'winetricks', 'verb': 'verb$index'},
    ];
    File(
      '${temporaryDirectory.path}/too-many-winetricks.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('preInstallActions'),
        ),
      ),
    );
  });

  test('preserves declared dependency winetricks order', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-winetricks-order-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    profile['installerResource'] = _validInstallerResourceJson();
    profile['preInstallActions'] = [
      {'kind': 'winetricks', 'verb': 'vcrun2022'},
      {'kind': 'winetricks', 'verb': 'corefonts'},
    ];
    File(
      '${temporaryDirectory.path}/ordered-winetricks.json',
    ).writeAsStringSync(jsonEncode(profile));

    final catalog = DartIoInstallProfileCatalog.fromDirectory(
      temporaryDirectory.path,
      schemaPath: 'profiles/$konyakProfileSchemaFileName',
    );

    expect(
      catalog.profiles.single.preInstallActions
          .whereType<WinetricksPreInstallAction>()
          .map((action) => action.verb.value),
      ['vcrun2022', 'corefonts'],
    );
  });

  for (final (length, accepted) in const <(int, bool)>[
    (128, true),
    (129, false),
  ]) {
    test('${accepted ? 'accepts' : 'rejects'} a $length-character native DLL '
        'component action identifier', () {
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'konyak-profile-native-component-id-limit-test-',
      );
      addTearDown(() {
        if (temporaryDirectory.existsSync()) {
          temporaryDirectory.deleteSync(recursive: true);
        }
      });
      final profile =
          jsonDecode(File('profiles/steam.json').readAsStringSync())
              as Map<String, Object?>;
      profile['installerResource'] = _validInstallerResourceJson();
      profile['preInstallActions'] = <Object?>[
        <String, Object?>{
          'kind': 'nativeDll',
          'componentId': 'a' * length,
          'machine': 'x86',
          'destination': 'windowsSysWow64',
          'targetFileName': 'component.dll',
          'resource': <String, Object?>{
            'kind': 'https',
            'url': 'https://downloads.example.test/component.dll',
            'sha256': 'a' * 64,
            'fileName': 'component.dll',
          },
        },
      ];
      File(
        '${temporaryDirectory.path}/component-id.json',
      ).writeAsStringSync(jsonEncode(profile));

      InstallProfileCatalog load() => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      );
      if (accepted) {
        expect(
          preInstallActionId(
            load().profiles.single.preInstallActions.single,
          ).value,
          'a' * length,
        );
      } else {
        expect(load, throwsA(isA<FormatException>()));
      }
    });
  }

  for (final invalidManagedProgramPath in <String>[
    'Steam.exe',
    r'D:\Program Files\Steam\Steam.exe',
    r'C:\Program Files\\Steam.exe',
    r'C:\Program Files\.\Steam.exe',
    r'C:\Program Files\..\Steam.exe',
    '${r'C:\Program Files\Steam'}\u0000.exe',
    r'C:\Program Files\Steam\Steam.msi',
  ]) {
    test('rejects unsafe managed program path $invalidManagedProgramPath', () {
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'konyak-profile-invalid-managed-path-test-',
      );
      addTearDown(() {
        if (temporaryDirectory.existsSync()) {
          temporaryDirectory.deleteSync(recursive: true);
        }
      });
      final profile =
          jsonDecode(File('profiles/steam.json').readAsStringSync())
              as Map<String, Object?>;
      profile['managedProgramPath'] = invalidManagedProgramPath;
      File(
        '${temporaryDirectory.path}/invalid-managed-path.json',
      ).writeAsStringSync(jsonEncode(profile));

      expect(
        () => DartIoInstallProfileCatalog.fromDirectory(
          temporaryDirectory.path,
          schemaPath: 'profiles/$konyakProfileSchemaFileName',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('managedProgramPath'),
          ),
        ),
      );
    });
  }

  test('uses the profile directory in bundled resources', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-directory-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profileDirectory = Directory(
      '${temporaryDirectory.path}/resources/profiles',
    )..createSync(recursive: true);

    expect(
      resolveBuiltinInstallProfileDirectory(
        environment: {
          'KONYAK_BUNDLE_RESOURCES': '${temporaryDirectory.path}/resources',
        },
        currentDirectory: temporaryDirectory.path,
        resolvedExecutable: '${temporaryDirectory.path}/missing/konyak-cli',
        script: Uri.parse('package:konyak_cli/konyak.dart'),
      ),
      profileDirectory.path,
    );
  });

  test('resolves the canonical schema from the source script', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-schema-resolution-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final canonicalSchema = File(
      '${temporaryDirectory.path}/source/profiles/'
      '$konyakProfileSchemaFileName',
    )..createSync(recursive: true);

    expect(
      resolveBuiltinInstallProfileSchemaPath(
        resolvedExecutable: '${temporaryDirectory.path}/missing/konyak-cli',
        script: Uri.file('${temporaryDirectory.path}/source/bin/konyak.dart'),
      ),
      canonicalSchema.path,
    );
  });

  test('rejects a current-working-directory schema as a trust root', () {
    final previousCurrentDirectory = Directory.current;
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-schema-ownership-test-',
    );
    addTearDown(() {
      Directory.current = previousCurrentDirectory;
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    Directory.current = temporaryDirectory;
    final currentDirectorySchema = Directory(
      '${temporaryDirectory.path}/packages/konyak_cli/profiles',
    )..createSync(recursive: true);
    File(
      '${currentDirectorySchema.path}/$konyakProfileSchemaFileName',
    ).writeAsStringSync('{"\$id":"$konyakProfileSchemaUri"}');

    expect(
      () => resolveBuiltinInstallProfileSchemaPath(
        resolvedExecutable: '${temporaryDirectory.path}/missing/konyak-cli',
        script: Uri.parse('package:konyak_cli/konyak.dart'),
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('rejects a profile that does not match the JSON schema', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-catalog-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    File('${temporaryDirectory.path}/invalid.json').writeAsStringSync('''
{
  "\$schema": "$konyakProfileSchemaUri",
  "schemaVersion": 1,
  "id": "invalid",
  "name": "Invalid",
  "profileVersion": 1,
  "summary": "A deliberately invalid profile.",
  "platforms": ["macos"],
  "windowsVersion": "win10",
  "managedProgramPath": "C:\\\\Invalid\\\\Invalid.exe",
  "installerResource": {
    "kind": "https",
    "url": "https://downloads.example.test/Setup.exe",
    "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "fileName": "Setup.exe"
  },
  "preInstallActions": [],
  "runCompletionPolicy": "launchOnly",
  "compatibilityProfile": {
    "id": "invalid",
    "profileVersion": 1,
    "childProcessRules": []
  },
  "arbitraryScript": "not permitted"
}
''');

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('invalid.json'), contains('arbitraryScript')),
        ),
      ),
    );
  });

  test('does not trust a schema supplied by the profile directory', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-schema-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });

    File(
      '${temporaryDirectory.path}/$konyakProfileSchemaFileName',
    ).writeAsStringSync('{}');
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    profile['arbitraryScript'] = 'not permitted';
    File(
      '${temporaryDirectory.path}/steam.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('arbitraryScript'),
        ),
      ),
    );
  });

  test('rejects child-process values that cannot use the line protocol', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-rule-value-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    final compatibilityProfile =
        profile['compatibilityProfile'] as Map<String, Object?>;
    final rules = compatibilityProfile['childProcessRules'] as List<Object?>;
    final rule = rules.single as Map<String, Object?>;
    rule['appendArgumentsIfMissing'] = ['--value\u0000ignored'];
    File(
      '${temporaryDirectory.path}/invalid-argument.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('appendArgumentsIfMissing'),
        ),
      ),
    );
  });

  test('rejects more child-process arguments than the runtime can apply', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-rule-limit-test-',
    );
    addTearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
    final profile =
        jsonDecode(File('profiles/steam.json').readAsStringSync())
            as Map<String, Object?>;
    final compatibilityProfile =
        profile['compatibilityProfile'] as Map<String, Object?>;
    compatibilityProfile['childProcessRules'] = [
      for (final ruleIndex in [0, 1])
        {
          'executableSuffix': 'helper-$ruleIndex.exe',
          'appendArgumentsIfMissing': [
            for (var argumentIndex = 0; argumentIndex < 33; argumentIndex++)
              '--rule-$ruleIndex-$argumentIndex',
          ],
        },
    ];
    File(
      '${temporaryDirectory.path}/too-many-arguments.json',
    ).writeAsStringSync(jsonEncode(profile));

    expect(
      () => DartIoInstallProfileCatalog.fromDirectory(
        temporaryDirectory.path,
        schemaPath: 'profiles/$konyakProfileSchemaFileName',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('at most 64 child-process arguments'),
        ),
      ),
    );
  });
}

Map<String, Object?> _validInstallerResourceJson() {
  return <String, Object?>{
    'kind': 'https',
    'url': 'https://downloads.example.test/Setup.exe',
    'sha256': '0123456789abcdef' * 4,
    'fileName': 'Setup.exe',
  };
}
