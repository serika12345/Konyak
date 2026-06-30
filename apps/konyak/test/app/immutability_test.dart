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
      bottle.pinnedPrograms.add(
        const PinnedProgramSummary(
          name: 'Other',
          path: '/other.exe',
          removable: true,
        ),
      ),
      hasLength(2),
    );
    expect(bottle.pinnedPrograms, hasLength(1));

    final environment = <String, String>{'LANG': 'ja_JP.UTF-8'};
    final settings = ProgramSettingsSummary(environment: environment);
    environment['LANG'] = 'en_US.UTF-8';

    expect(settings.environment.unlockView, {'LANG': 'ja_JP.UTF-8'});
    expect(settings.environment.add('WINEDEBUG', '-all').unlockView, {
      'LANG': 'ja_JP.UTF-8',
      'WINEDEBUG': '-all',
    });
    expect(settings.environment.unlockView, {'LANG': 'ja_JP.UTF-8'});
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
      knownRuntimesState: StartupKnownRuntimesState.loaded(const []),
      konyakUpdateState: const StartupKonyakUpdateState.unavailable(),
    );
    labels.add('changed');

    expect(result.availableUpdateLabels, ['Konyak 1.0']);
    expect(() => result.availableUpdateLabels.add('x'), throwsUnsupportedError);
    switch (result.knownRuntimesState) {
      case StartupKnownRuntimesLoaded(:final runtimes):
        expect(runtimes.clear, throwsUnsupportedError);
      case StartupKnownRuntimesSkipped():
        fail('Expected loaded known runtimes.');
    }
  });
}

final class _NoopProcessRunner implements ProcessRunner {
  const _NoopProcessRunner();

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    ProcessWorkingDirectory workingDirectory =
        const InheritedProcessWorkingDirectory(),
    Map<String, String> environment = const <String, String>{},
    ProcessRunObservation observation = const UnobservedProcessRun(),
  }) async {
    return const ProcessRunResult(exitCode: 0, stdout: '', stderr: '');
  }
}
