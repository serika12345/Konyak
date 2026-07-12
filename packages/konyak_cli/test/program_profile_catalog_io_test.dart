import 'dart:convert';
import 'dart:io';

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
    expect(
      profile.managedProgramPath.value,
      r'C:\Program Files (x86)\Steam\Steam.exe',
    );
    expect(profile.runCompletionPolicy.value, 'launchOnly');
    expect(profile.compatibilityProfile.childProcessRules, [
      ChildProcessCompatibilityRule(
        executableSuffix: 'steamwebhelper.exe',
        appendArgumentsIfMissing: const ['--disable-gpu', '--in-process-gpu'],
      ),
    ]);
  });

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
