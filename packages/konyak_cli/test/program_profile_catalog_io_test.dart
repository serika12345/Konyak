import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
    expect(profile.dependencyWinetricksVerbs.map((verb) => verb.value), [
      'corefonts',
    ]);
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
    profile['dependencyWinetricksVerbs'] = ['corefonts;rm'];
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
          contains('dependencyWinetricksVerbs'),
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
    profile['dependencyWinetricksVerbs'] = [
      for (var index = 0; index < 65; index++) 'verb$index',
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
          contains('dependencyWinetricksVerbs'),
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
    profile['dependencyWinetricksVerbs'] = ['vcrun2022', 'corefonts'];
    File(
      '${temporaryDirectory.path}/ordered-winetricks.json',
    ).writeAsStringSync(jsonEncode(profile));

    final catalog = DartIoInstallProfileCatalog.fromDirectory(
      temporaryDirectory.path,
      schemaPath: 'profiles/$konyakProfileSchemaFileName',
    );

    expect(
      catalog.profiles.single.dependencyWinetricksVerbs.map(
        (verb) => verb.value,
      ),
      ['vcrun2022', 'corefonts'],
    );
  });

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
  "managedProgramPath": "Invalid.exe",
  "dependencyWinetricksVerbs": [],
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
