import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/startup/startup_update_checker.dart';
import 'package:konyak/src/app/widgets/konyak_menu_bar.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';

void main() {
  test('bottle and program summaries defensively copy collections', () {
    final pinnedPrograms = <PinnedProgramSummary>[
      const PinnedProgramSummary(
        name: 'Setup',
        path: '/setup.exe',
        removable: true,
      ),
    ];
    final bottle = BottleSummary(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
      pinnedPrograms: pinnedPrograms,
    );
    pinnedPrograms.clear();

    expect(bottle.pinnedPrograms, hasLength(1));
    expect(
      () => bottle.pinnedPrograms.add(
        const PinnedProgramSummary(
          name: 'Other',
          path: '/other.exe',
          removable: true,
        ),
      ),
      throwsUnsupportedError,
    );

    final environment = <String, String>{'LANG': 'ja_JP.UTF-8'};
    final settings = ProgramSettingsSummary(environment: environment);
    environment['LANG'] = 'en_US.UTF-8';

    expect(settings.environment, {'LANG': 'ja_JP.UTF-8'});
    expect(
      () => settings.environment['WINEDEBUG'] = '-all',
      throwsUnsupportedError,
    );
  });

  test('menu and CLI configuration collections are immutable snapshots', () {
    final menuItems = <KonyakMenuItemDefinition>[
      const KonyakMenuItemDefinition(
        label: 'Settings',
        icon: Icons.settings,
        onPressed: null,
      ),
    ];
    final menu = KonyakMenuDefinition(label: 'Konyak', items: menuItems);
    menuItems.clear();

    expect(menu.items, hasLength(1));
    expect(menu.items.clear, throwsUnsupportedError);

    final menus = <KonyakMenuDefinition>[menu];
    final menuBar = KonyakMenuBar(menus: menus);
    menus.clear();

    expect(menuBar.menus, hasLength(1));
    expect(menuBar.menus.clear, throwsUnsupportedError);

    final baseArguments = <String>['run'];
    final environment = <String, String>{'K': 'V'};
    final client = KonyakCliClient(
      executable: 'konyak',
      baseArguments: baseArguments,
      environment: environment,
      processRunner: const _NoopProcessRunner(),
    );
    baseArguments.add('changed');
    environment['K'] = 'changed';

    expect(client.baseArguments, ['run']);
    expect(client.environment, {'K': 'V'});
    expect(() => client.baseArguments.add('x'), throwsUnsupportedError);
    expect(() => client.environment['X'] = 'Y', throwsUnsupportedError);
  });

  test('startup update result exposes immutable collections', () {
    final labels = <String>['Konyak 1.0'];
    final result = StartupUpdateCheckResult(
      availableUpdateLabels: labels,
      knownRuntimes: const [],
    );
    labels.add('changed');

    expect(result.availableUpdateLabels, ['Konyak 1.0']);
    expect(() => result.availableUpdateLabels.add('x'), throwsUnsupportedError);
    expect(() => result.knownRuntimes!.clear(), throwsUnsupportedError);
  });
}

final class _NoopProcessRunner implements ProcessRunner {
  const _NoopProcessRunner();

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    void Function(String line)? onStdoutLine,
  }) async {
    return const ProcessRunResult(exitCode: 0, stdout: '', stderr: '');
  }
}
