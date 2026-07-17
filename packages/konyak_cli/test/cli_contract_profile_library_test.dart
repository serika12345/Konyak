import 'support/cli_contract_full_helpers.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory userDirectory;
  late DartIoInstallProfileLibrary library;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-library-cli-test-',
    );
    userDirectory = Directory('${temporaryDirectory.path}/user-profiles');
    library = DartIoInstallProfileLibrary(
      builtinDirectory: 'profiles',
      userDirectory: userDirectory.path,
      schemaPath: 'profiles/$konyakProfileSchemaFileName',
    );
  });

  tearDown(() {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('imports, updates, exports, lists, and deletes a user profile', () {
    final importPath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'incoming.json',
      name: 'Steam Custom',
      profileVersion: 1,
    );
    final imported = runCli(
      ['import-install-profile', '--from', importPath, '--json'],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    expect(imported.exitCode, 0);
    final importedPayload = jsonDecode(imported.stdout) as Map<String, Object?>;
    final importedMutation =
        importedPayload['installProfileMutation'] as Map<String, Object?>;
    final importedProfile =
        importedMutation['installProfile'] as Map<String, Object?>;
    final importedDigest = importedProfile['profileDigest'] as String;
    expect(importedMutation['operation'], 'import');
    expect(importedProfile['profileSourceKind'], 'user');

    final updatePath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'updated.json',
      name: 'Updated Steam Custom',
      profileVersion: 2,
    );
    final updated = runCli(
      [
        'update-install-profile',
        'steam-custom',
        '--from',
        updatePath,
        '--expected-digest',
        importedDigest,
        '--json',
      ],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    expect(updated.exitCode, 0);
    final updatedProfile =
        ((jsonDecode(updated.stdout)
                    as Map<String, Object?>)['installProfileMutation']
                as Map<String, Object?>)['installProfile']
            as Map<String, Object?>;
    final updatedDigest = updatedProfile['profileDigest'] as String;
    expect(updatedProfile['name'], 'Updated Steam Custom');

    final exportPath = '${temporaryDirectory.path}/exported.json';
    final exported = runCli(
      ['export-install-profile', 'steam-custom', '--to', exportPath, '--json'],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    expect(exported.exitCode, 0);
    expect(File(exportPath).readAsStringSync(), endsWith('\n'));

    final listed = runCli(
      const ['list-install-profiles', '--json'],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    final listedPayload = jsonDecode(listed.stdout) as Map<String, Object?>;
    final profiles = listedPayload['installProfiles'] as List<Object?>;
    final customProfile = profiles.cast<Map<String, Object?>>().singleWhere(
      (profile) => profile['id'] == 'steam-custom',
    );
    expect(customProfile['canEdit'], isTrue);
    expect(customProfile['canDelete'], isTrue);

    final deleted = runCli(
      [
        'delete-install-profile',
        'steam-custom',
        '--expected-digest',
        updatedDigest,
        '--json',
      ],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    expect(deleted.exitCode, 0);
    expect(
      File('${userDirectory.path}/steam-custom.json').existsSync(),
      isFalse,
    );
  });

  test('rejects bundled deletion and reports structured validation errors', () {
    final invalidPath = '${temporaryDirectory.path}/invalid.json';
    File(invalidPath).writeAsStringSync('{}');

    final validation = runCli(
      ['validate-install-profile', '--from', invalidPath, '--json'],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    final validationPayload =
        jsonDecode(validation.stdout) as Map<String, Object?>;
    final validationError = validationPayload['error'] as Map<String, Object?>;
    expect(validation.exitCode, 65);
    expect(validationError['code'], 'invalidProfile');
    expect(validationError['validationErrors'], isA<List<Object?>>());

    final deletion = runCli(
      [
        'delete-install-profile',
        'steam',
        '--expected-digest',
        '0' * 64,
        '--json',
      ],
      installProfileCatalog: library.loadCatalog(),
      installProfileLibrary: library,
    );
    final deletionPayload = jsonDecode(deletion.stdout) as Map<String, Object?>;
    expect(deletion.exitCode, 77);
    expect(
      (deletionPayload['error'] as Map<String, Object?>)['code'],
      'profileReadOnly',
    );
  });
}

String _writeProfile({
  required Directory directory,
  required String fileName,
  required String name,
  required int profileVersion,
}) {
  final profile =
      jsonDecode(File('profiles/steam.json').readAsStringSync())
          as Map<String, Object?>;
  profile['id'] = 'steam-custom';
  profile['name'] = name;
  profile['profileVersion'] = profileVersion;
  final compatibilityProfile =
      profile['compatibilityProfile'] as Map<String, Object?>;
  compatibilityProfile['id'] = 'steam-custom';
  compatibilityProfile['profileVersion'] = profileVersion;
  final path = '${directory.path}/$fileName';
  File(path).writeAsStringSync(jsonEncode(profile));
  return path;
}
