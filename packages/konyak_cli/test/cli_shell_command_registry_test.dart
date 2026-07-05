import 'dart:io';

import 'package:konyak_cli/src/cli/cli_shell_command_registry.dart';
import 'package:test/test.dart';

void main() {
  test('shell command registry exposes canonical groups in public order', () {
    final groupNames = <String>[
      for (final group in cliShellCommandGroups) group.name,
    ];

    expect(groupNames, <String>[
      'bottle',
      'program',
      'runtime',
      'winetricks',
      'process',
      'update',
      'shell',
    ]);

    for (final group in cliShellCommandGroups) {
      expect(group.summary.trim(), isNotEmpty, reason: group.name);
      expect(group.commands, isNotEmpty, reason: group.name);
    }
  });

  test('shell command registry covers the planned canonical command paths', () {
    final commandPaths = <String>[
      for (final command in cliShellCommands()) command.path.join(' '),
    ];

    expect(
      commandPaths,
      containsAll(<String>[
        'bottle list',
        'bottle show',
        'bottle create',
        'bottle rename',
        'bottle move',
        'bottle delete',
        'bottle export',
        'bottle import',
        'program list',
        'program run',
        'program pin',
        'program unpin',
        'program rename',
        'program settings get',
        'program settings set',
        'runtime list',
        'runtime validate',
        'runtime install',
        'runtime reinstall',
        'runtime update check',
        'runtime update install',
        'runtime import gptk',
        'winetricks list',
        'winetricks run',
        'process list',
        'process kill',
        'process kill-all',
        'update check',
        'update install',
        'shell install',
        'shell uninstall',
        'shell status',
      ]),
    );

    for (final group in cliShellCommandGroups) {
      for (final command in group.commands) {
        expect(command.path.first, group.name, reason: command.path.join(' '));
        expect(command.summary.trim(), isNotEmpty);
        expect(command.supportsJson, isTrue);
      }
    }
  });

  test('shell command registry records compatibility aliases', () {
    expect(
      shellCommandAt(const <String>['bottle', 'list']).compatibilityAliases,
      contains('list-bottles'),
    );
    expect(
      shellCommandAt(const <String>['program', 'run']).compatibilityAliases,
      contains('run-program'),
    );
    expect(
      shellCommandAt(const <String>['runtime', 'install']).compatibilityAliases,
      containsAll(<String>['install-macos-wine', 'install-linux-wine']),
    );
    expect(
      shellCommandAt(const <String>[
        'runtime',
        'import',
        'gptk',
      ]).compatibilityAliases,
      contains('install-gptk-wine'),
    );
    expect(
      shellCommandAt(const <String>[
        'process',
        'kill-all',
      ]).compatibilityAliases,
      contains('terminate-wine-processes'),
    );
    expect(
      cliShellInternalCompatibilityCommands,
      containsAll(<String>[
        'launch-pinned-program',
        'install-linux-file-associations',
        'run-bottle-command',
      ]),
    );
  });

  test('shell command registry is represented in the maintained contract', () {
    final contract = File(
      '../../docs/cli-shell-contract.md',
    ).readAsStringSync();

    cliShellCommands().forEach((command) {
      expect(contract, contains('konyak ${command.path.join(' ')}'));
    });

    for (final alias in <String>[
      'list-bottles',
      'run-program',
      'install-macos-wine',
      'install-linux-wine',
      'install-gptk-wine',
      'terminate-wine-processes',
      'launch-pinned-program',
    ]) {
      expect(contract, contains(alias));
    }
  });
}

Iterable<CliShellCommandSpec> cliShellCommands() {
  return cliShellCommandGroups.expand((group) => group.commands);
}

CliShellCommandSpec shellCommandAt(List<String> path) {
  return cliShellCommands().singleWhere(
    (command) => command.path.join(' ') == path.join(' '),
  );
}
