import 'dart:convert';
import 'dart:io';

import 'package:konyak_cli/src/domain/program/program_profile_models.dart';
import 'package:konyak_cli/src/domain/shared/domain_value_objects.dart';
import 'package:konyak_cli/src/io/program_profile_catalog_io.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory userDirectory;
  late DartIoInstallProfileLibrary library;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'konyak-user-profile-library-test-',
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

  test('imports canonical user JSON and loads it with bundled profiles', () {
    final importPath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'incoming.json',
      id: 'steam-custom',
      name: 'Steam Custom',
    );

    final result = library.importProfile(importPath);

    expect(result, isA<InstallProfileImported>());
    final imported = (result as InstallProfileImported).profile;
    expect(imported.sourceKind, ProfileSourceKind.user);
    expect(imported.sourceId.value, 'steam-custom.json');
    final stored = File('${userDirectory.path}/steam-custom.json');
    expect(stored.existsSync(), isTrue);
    expect(stored.readAsStringSync(), endsWith('\n'));
    final catalog = library.loadCatalog();
    expect(
      catalog.profiles.map((profile) => profile.id.value),
      containsAll(<String>['steam', 'steam-custom']),
    );
  });

  test('rejects an imported profile that shadows a bundled ID', () {
    final importPath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'shadow.json',
      id: 'steam',
      name: 'Shadow Steam',
    );

    final result = library.importProfile(importPath);

    expect(result, isA<InstallProfileLibraryFailure>());
    expect(
      (result as InstallProfileLibraryFailure).code,
      InstallProfileLibraryFailureCode.profileReadOnly,
    );
    expect(userDirectory.existsSync(), isFalse);
  });

  test('reports an invalid manual user manifest without hiding built-ins', () {
    userDirectory.createSync(recursive: true);
    File('${userDirectory.path}/invalid.json').writeAsStringSync('{invalid');

    final catalog = library.loadCatalog();

    expect(catalog.profiles.map((profile) => profile.id.value), ['steam']);
    expect(catalog.issues, hasLength(1));
    expect(catalog.issues.single.sourceId, 'invalid.json');
  });

  test('rejects a stale digest update without changing stored JSON', () {
    final importPath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'incoming.json',
      id: 'steam-custom',
      name: 'Steam Custom',
    );
    final imported =
        library.importProfile(importPath) as InstallProfileImported;
    final stored = File('${userDirectory.path}/steam-custom.json');
    final originalBytes = stored.readAsBytesSync();
    final updatePath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'updated.json',
      id: 'steam-custom',
      name: 'Updated Steam Custom',
      profileVersion: 2,
    );

    final result = library.updateProfile(
      profileId: ProfileId('steam-custom'),
      expectedDigest: ProfileManifestDigest('0' * 64),
      sourcePath: updatePath,
    );

    expect(imported.profile.manifestDigest.value, isNot('0' * 64));
    expect(result, isA<InstallProfileLibraryFailure>());
    expect(
      (result as InstallProfileLibraryFailure).code,
      InstallProfileLibraryFailureCode.profileModified,
    );
    expect(stored.readAsBytesSync(), originalBytes);
  });

  test('deletes only a user profile with the current digest', () {
    final importPath = _writeProfile(
      directory: temporaryDirectory,
      fileName: 'incoming.json',
      id: 'steam-custom',
      name: 'Steam Custom',
    );
    final imported =
        library.importProfile(importPath) as InstallProfileImported;

    final deleted = library.deleteProfile(
      profileId: imported.profile.id,
      expectedDigest: imported.profile.manifestDigest,
    );
    final builtinDelete = library.deleteProfile(
      profileId: ProfileId('steam'),
      expectedDigest: ProfileManifestDigest('0' * 64),
    );

    expect(deleted, isA<InstallProfileDeleted>());
    expect(
      File('${userDirectory.path}/steam-custom.json').existsSync(),
      isFalse,
    );
    expect(builtinDelete, isA<InstallProfileLibraryFailure>());
    expect(
      (builtinDelete as InstallProfileLibraryFailure).code,
      InstallProfileLibraryFailureCode.profileReadOnly,
    );
  });
}

String _writeProfile({
  required Directory directory,
  required String fileName,
  required String id,
  required String name,
  int profileVersion = 1,
}) {
  final profile =
      jsonDecode(File('profiles/steam.json').readAsStringSync())
          as Map<String, Object?>;
  profile['id'] = id;
  profile['name'] = name;
  profile['profileVersion'] = profileVersion;
  final compatibilityProfile =
      profile['compatibilityProfile'] as Map<String, Object?>;
  compatibilityProfile['id'] = id;
  compatibilityProfile['profileVersion'] = profileVersion;
  final path = '${directory.path}/$fileName';
  File(path).writeAsStringSync(jsonEncode(profile));
  return path;
}
