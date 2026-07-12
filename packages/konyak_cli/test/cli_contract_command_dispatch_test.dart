import 'dart:convert';

import 'package:konyak_cli/src/cli/cli_app_runtime_handlers.dart';
import 'package:konyak_cli/src/cli/cli_commands.dart';
import 'package:konyak_cli/src/cli/cli_injected_runner.dart' as injected;
import 'package:konyak_cli/src/cli/cli_location_winetricks_handlers.dart';
import 'package:konyak_cli/src/domain/program/program_profile_catalog.dart';
import 'package:test/test.dart';

import 'support/cli_contract_helpers.dart';

void main() {
  test('runtime command dispatch reports matched commands explicitly', () {
    final match = handleRuntimeCommand(const [
      'list-runtimes',
      '--json',
    ], testCliCommandContext());

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
    ], testCliCommandContext());

    expect(match, isA<CliCommandNotMatched>());
  });

  test('location command dispatch reports matched commands explicitly', () {
    final match = handleLocationCommand(const [
      'open-bottle-location',
      'steam',
      '--location',
      'c-drive',
      '--json',
    ], testCliCommandContext());

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
    ], testCliCommandContext());

    expect(match, isA<CliCommandNotMatched>());
  });

  test('unrelated commands do not load deferred install profiles', () {
    final context = testCliCommandContext(
      installProfileCatalog: InstallProfileCatalog.deferred(
        () => throw const InstallProfileCatalogException('invalid profile'),
      ),
    );

    final result = injected.runCli(const [
      'list-bottles',
      '--json',
    ], context: context);

    expect(result.exitCode, 0);
  });

  test('profile catalog failures are returned as structured errors', () {
    final context = testCliCommandContext(
      installProfileCatalog: InstallProfileCatalog.deferred(
        () => throw const InstallProfileCatalogException('invalid profile'),
      ),
    );

    final result = injected.runCli(const [
      'list-install-profiles',
      '--json',
    ], context: context);

    expect(result.exitCode, 65);
    expect(jsonDecode(result.stdout), {
      'schemaVersion': 1,
      'error': {
        'code': 'installProfileCatalogError',
        'message': 'invalid profile',
      },
    });
  });
}
