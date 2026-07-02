part of 'cli_contract_test.dart';

void defineCommandDispatchContractTests() {
  test('runtime command dispatch reports matched commands explicitly', () {
    final match = handleRuntimeCommand(const [
      'list-runtimes',
      '--json',
    ], _commandDispatchContext());

    switch (match) {
      case CliCommandMatched(:final result):
        expect(result.exitCode, 0);
        expect(result.stderr, isEmpty);
      case CliCommandNotMatched():
        fail('Expected the runtime command to match.');
    }
  });

  test('runtime command dispatch reports unmatched commands explicitly', () {
    final match = handleRuntimeCommand(const [
      'open-bottle-location',
      'steam',
      '--location',
      'c-drive',
      '--json',
    ], _commandDispatchContext());

    expect(match, isA<CliCommandNotMatched>());
  });

  test('location command dispatch reports matched commands explicitly', () {
    final match = handleLocationCommand(const [
      'open-bottle-location',
      'steam',
      '--location',
      'c-drive',
      '--json',
    ], _commandDispatchContext());

    switch (match) {
      case CliCommandMatched(:final result):
        expect(result.exitCode, 74);
        final payload = jsonDecode(result.stdout) as Map<String, Object?>;
        expect(
          payload['error'],
          containsPair('code', 'bottleRepositoryUnavailable'),
        );
      case CliCommandNotMatched():
        fail('Expected the location command to match.');
    }
  });

  test('location command dispatch reports unmatched commands explicitly', () {
    final match = handleLocationCommand(const [
      'list-runtimes',
      '--json',
    ], _commandDispatchContext());

    expect(match, isA<CliCommandNotMatched>());
  });
}

CliCommandContext _commandDispatchContext() {
  return _testCliCommandContext(
    bottleCatalog: null,
    bottleRepository: null,
    bottleProgramRepository: const EmptyBottleProgramRepository(),
    programMetadataExtractor: const NoopProgramMetadataExtractor(),
    winetricksVerbRepository: const UnavailableWinetricksVerbRepository(),
    runtimeCatalog: null,
    programRunPlanner: null,
    programGraphicsBackendHintsInspector:
        const UnavailableProgramGraphicsBackendHintsInspector(),
    programRunner: null,
    bottlePrefixInitializer: null,
    pathOpener: null,
    macosWineInstaller: null,
    linuxWineInstaller: null,
    gptkWineInstaller: null,
    runtimeUpdateChecker: null,
    appUpdateChecker: null,
    appUpdateInstaller: null,
    runtimeValidator: null,
    macosSetupChecker: null,
    appSettingsRepository: null,
    runtimeInstallProgressSink: null,
    linuxExternalProgramLauncherDiagnosticSink: null,
  );
}
