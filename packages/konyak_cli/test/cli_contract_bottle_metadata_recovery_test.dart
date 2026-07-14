import 'package:konyak_cli/src/repository/composite_bottle_repository.dart';

import 'support/cli_contract_full_helpers.dart';

void main() {
  test(
    'list-bottles reports invalid profile metadata without hiding valid bottles',
    () {
      final fixture = _BottleMetadataRecoveryFixture.create();
      addTearDown(fixture.dispose);
      fixture.createValidBottle();
      fixture.writeLegacyProfileMetadata();

      final result = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: fixture.repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(
        (payload['bottles'] as List<Object?>).map(
          (value) => (value as Map<String, Object?>)['id'],
        ),
        ['valid'],
      );
      expect(payload['invalidBottles'], [
        {
          'storageId': 'legacy',
          'path': fixture.legacyBottlePath,
          'code': 'invalidProgramProfiles',
          'message':
              'Bottle metadata contains invalid program profile records.',
          'recoveryActions': ['discardInvalidProfiles'],
        },
      ]);
    },
  );

  test('list-bottles localizes a storage id that requires trimming', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);
    fixture.createValidBottle();
    const storageId = ' legacy ';
    final bottlePath = joinTestPath(fixture.dataHome, const [
      'bottles',
      storageId,
    ]);
    final metadataFile = File(
      joinTestPath(bottlePath, const ['metadata.json']),
    );
    metadataFile
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'bottle': {
            'id': storageId,
            'name': 'Legacy',
            'path': bottlePath,
            'windowsVersion': 'win10',
            'profiles': [
              {
                'profileId': 'steam',
                'managedProgramPath': r'C:\Program Files (x86)\Steam\Steam.exe',
              },
            ],
          },
        }),
      );

    final listResult = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(listResult.exitCode, 0);
    final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
    expect(
      (listPayload['bottles'] as List<Object?>).map(
        (value) => (value as Map<String, Object?>)['id'],
      ),
      ['valid'],
    );
    expect(listPayload['invalidBottles'], isEmpty);
    expect(metadataFile.existsSync(), isTrue);
  });

  test('list-bottles localizes an invalid directory basename', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);
    fixture.createValidBottle();
    final invalidMetadata = File(
      joinTestPath(fixture.dataHome, const [
        'bottles',
        r'bad\id',
        'metadata.json',
      ]),
    );
    invalidMetadata
      ..createSync(recursive: true)
      ..writeAsStringSync('[]');

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(
      (payload['bottles'] as List<Object?>).map(
        (value) => (value as Map<String, Object?>)['id'],
      ),
      ['valid'],
    );
    expect(payload['invalidBottles'], isEmpty);
  });

  test('list-bottles does not advertise repair for a symlinked bottle', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);
    final outsideBottle = Directory(
      joinTestPath(fixture.root.path, const ['outside-bottle']),
    )..createSync();
    File(
      joinTestPath(outsideBottle.path, const ['metadata.json']),
    ).writeAsStringSync(fixture.legacyMetadataJson());
    Directory(fixture.legacyBottlePath).parent.createSync(recursive: true);
    Link(fixture.legacyBottlePath).createSync(outsideBottle.path);

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['invalidBottles'], [
      {
        'storageId': 'legacy',
        'path': fixture.legacyBottlePath,
        'code': 'invalidBottleMetadata',
        'message': 'Bottle storage uses an unsupported symbolic link.',
        'recoveryActions': <Object?>[],
      },
    ]);
  });

  test(
    'repair-bottle-metadata backs up and discards only invalid profiles',
    () {
      final fixture = _BottleMetadataRecoveryFixture.create();
      addTearDown(fixture.dispose);
      final originalMetadata = fixture.writeLegacyProfileMetadata();
      final prefixSentinel = fixture.writePrefixSentinel();

      final result = runCli(const [
        'repair-bottle-metadata',
        'legacy',
        '--action',
        'discard-invalid-profiles',
        '--json',
      ], bottleRepository: fixture.repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final repair = payload['bottleMetadataRepair'] as Map<String, Object?>;
      expect(repair['storageId'], 'legacy');
      expect(repair['action'], 'discardInvalidProfiles');
      expect(repair['bottle'], {
        'id': 'legacy',
        'name': 'Legacy',
        'path': fixture.legacyBottlePath,
        'windowsVersion': 'win10',
      });
      final backupPath = repair['backupPath'] as String;
      expect(File(backupPath).readAsStringSync(), originalMetadata);
      expect(prefixSentinel.readAsStringSync(), 'do not touch');

      final rewritten =
          jsonDecode(fixture.metadataFile.readAsStringSync())
              as Map<String, Object?>;
      expect(rewritten, {
        'schemaVersion': 1,
        'bottle': {
          'id': 'legacy',
          'name': 'Legacy',
          'path': fixture.legacyBottlePath,
          'windowsVersion': 'win10',
        },
      });
      expect(
        expectIo(
          fixture.repository.listBottles(),
        ).map((bottle) => bottle.id.value),
        ['legacy'],
      );
    },
  );

  test('repair-bottle-metadata never rewrites arbitrary corrupt metadata', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);
    const corruptMetadata = '[]';
    fixture.metadataFile
      ..createSync(recursive: true)
      ..writeAsStringSync(corruptMetadata);

    final result = runCli(const [
      'repair-bottle-metadata',
      'legacy',
      '--action',
      'discard-invalid-profiles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(result.exitCode, 65);
    expect(jsonDecode(result.stdout), {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleMetadataNotRepairable',
        'message': 'Bottle metadata is not repairable by this action.',
        'storageId': 'legacy',
      },
    });
    expect(fixture.metadataFile.readAsStringSync(), corruptMetadata);
    expect(
      fixture.metadataFile.parent.listSync().whereType<File>().map(
        (file) => file.path,
      ),
      [fixture.metadataFile.path],
    );
  });

  test('repair-bottle-metadata rejects a symlinked metadata file', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);
    final outsideMetadata = File(
      joinTestPath(fixture.root.path, const ['outside-metadata.json']),
    )..writeAsStringSync(fixture.legacyMetadataJson());
    fixture.metadataFile.parent.createSync(recursive: true);
    Link(fixture.metadataFile.path).createSync(outsideMetadata.path);

    final listResult = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: fixture.repository);
    final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
    expect(listPayload['invalidBottles'], [
      {
        'storageId': 'legacy',
        'path': fixture.legacyBottlePath,
        'code': 'invalidBottleMetadata',
        'message': 'Bottle metadata uses an unsupported symbolic link.',
        'recoveryActions': <Object?>[],
      },
    ]);

    final result = runCli(const [
      'repair-bottle-metadata',
      'legacy',
      '--action',
      'discard-invalid-profiles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(result.exitCode, 65);
    expect((jsonDecode(result.stdout) as Map<String, Object?>)['error'], {
      'code': 'bottleMetadataNotRepairable',
      'message': 'Bottle metadata uses an unsupported symbolic link.',
      'storageId': 'legacy',
    });
    expect(outsideMetadata.readAsStringSync(), fixture.legacyMetadataJson());
  });

  test('repair-bottle-metadata reports missing metadata distinctly', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);

    final result = runCli(const [
      'repair-bottle-metadata',
      'missing',
      '--action',
      'discard-invalid-profiles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(result.exitCode, 66);
    expect(jsonDecode(result.stdout), {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleMetadataNotFound',
        'message': 'Bottle metadata not found.',
        'storageId': 'missing',
      },
    });
  });

  test('repair-bottle-metadata rejects traversal in the storage id', () {
    final fixture = _BottleMetadataRecoveryFixture.create();
    addTearDown(fixture.dispose);
    final outsideMetadata = File(
      joinTestPath(fixture.root.path, const ['metadata.json']),
    )..writeAsStringSync(fixture.legacyMetadataJson());

    final result = runCli(const [
      'repair-bottle-metadata',
      '..',
      '--action',
      'discard-invalid-profiles',
      '--json',
    ], bottleRepository: fixture.repository);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(outsideMetadata.readAsStringSync(), fixture.legacyMetadataJson());
  });

  test('list-bottles keeps a repository root failure as a command failure', () {
    final root = Directory.systemTemp.createTempSync(
      'konyak-bottle-root-failure-test-',
    );
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    final invalidRoot = File(joinTestPath(root.path, const ['bottles']))
      ..writeAsStringSync('not a directory');
    final repository = FileBottleRepository(
      dataHome: root.path,
      bottleDirectory: Option.of(invalidRoot.path),
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
    );

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 74);
    expect(jsonDecode(result.stdout), {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleRepositoryError',
        'message': 'Bottle repository root is not a directory.',
      },
    });
  });

  test(
    'composite recovery uses the same writable-first storage id as listing',
    () {
      final writable = _BottleMetadataRecoveryFixture.create();
      final catalog = _BottleMetadataRecoveryFixture.create();
      addTearDown(writable.dispose);
      addTearDown(catalog.dispose);
      writable.writeLegacyProfileMetadata();
      catalog.metadataFile
        ..createSync(recursive: true)
        ..writeAsStringSync('[]');
      final repository = CompositeBottleRepository(
        catalogs: [catalog.repository],
        writableRepository: writable.repository,
      );

      final listResult = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: repository);
      final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
      expect(listPayload['invalidBottles'], [
        {
          'storageId': 'legacy',
          'path': writable.legacyBottlePath,
          'code': 'invalidProgramProfiles',
          'message':
              'Bottle metadata contains invalid program profile records.',
          'recoveryActions': ['discardInvalidProfiles'],
        },
      ]);

      final repairResult = runCli(const [
        'repair-bottle-metadata',
        'legacy',
        '--action',
        'discard-invalid-profiles',
        '--json',
      ], bottleRepository: repository);

      expect(repairResult.exitCode, 0);
      expect(catalog.metadataFile.readAsStringSync(), '[]');
    },
  );

  test(
    'composite recovery does not skip a higher-priority corrupt storage id',
    () {
      final writable = _BottleMetadataRecoveryFixture.create();
      final catalog = _BottleMetadataRecoveryFixture.create();
      addTearDown(writable.dispose);
      addTearDown(catalog.dispose);
      writable.metadataFile
        ..createSync(recursive: true)
        ..writeAsStringSync('[]');
      final catalogMetadata = catalog.writeLegacyProfileMetadata();
      final repository = CompositeBottleRepository(
        catalogs: [catalog.repository],
        writableRepository: writable.repository,
      );

      final listResult = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: repository);
      final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
      expect(listPayload['invalidBottles'], [
        {
          'storageId': 'legacy',
          'path': writable.legacyBottlePath,
          'code': 'invalidBottleMetadata',
          'message': 'Bottle metadata must be an object.',
          'recoveryActions': <Object?>[],
        },
      ]);

      final repairResult = runCli(const [
        'repair-bottle-metadata',
        'legacy',
        '--action',
        'discard-invalid-profiles',
        '--json',
      ], bottleRepository: repository);

      expect(repairResult.exitCode, 65);
      expect(catalog.metadataFile.readAsStringSync(), catalogMetadata);
    },
  );
}

final class _BottleMetadataRecoveryFixture {
  _BottleMetadataRecoveryFixture({
    required this.root,
    required this.dataHome,
    required this.repository,
  });

  factory _BottleMetadataRecoveryFixture.create() {
    final root = Directory.systemTemp.createTempSync(
      'konyak-bottle-metadata-recovery-test-',
    );
    final dataHome = joinTestPath(root.path, const ['data']);
    return _BottleMetadataRecoveryFixture(
      root: root,
      dataHome: dataHome,
      repository: FileBottleRepository(
        dataHome: dataHome,
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
      ),
    );
  }

  final Directory root;
  final String dataHome;
  final FileBottleRepository repository;

  String get legacyBottlePath =>
      joinTestPath(dataHome, const ['bottles', 'legacy']);

  File get metadataFile =>
      File(joinTestPath(legacyBottlePath, const ['metadata.json']));

  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }

  void createValidBottle() {
    final result = repository.createBottle(
      BottleCreateRequest(
        name: BottleName('Valid'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );
    expect(result, isA<BottleCreated>());
  }

  String writeLegacyProfileMetadata() {
    final metadata = legacyMetadataJson();
    metadataFile
      ..createSync(recursive: true)
      ..writeAsStringSync(metadata);
    return metadata;
  }

  String legacyMetadataJson() {
    return jsonEncode({
      'schemaVersion': 1,
      'bottle': {
        'id': 'legacy',
        'name': 'Legacy',
        'path': legacyBottlePath,
        'windowsVersion': 'win10',
        'profiles': [
          {
            'profileId': 'steam',
            'managedProgramPath': r'C:\Program Files (x86)\Steam\Steam.exe',
          },
        ],
      },
    });
  }

  File writePrefixSentinel() {
    return File(
        joinTestPath(legacyBottlePath, const ['drive_c', 'sentinel.txt']),
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('do not touch');
  }
}
