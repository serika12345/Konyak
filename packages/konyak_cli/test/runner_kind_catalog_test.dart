import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

void main() {
  test('stable runner-kind catalog preserves public request strings', () {
    expect(
      RunnerKind.stableRequestKinds.map((runnerKind) => runnerKind.value),
      [
        'wine',
        'wineRegistry',
        'wineRegistryQuery',
        'wineboot',
        'wineserver',
        'winedbg',
        'winetricks',
        'terminal',
        'macosWine',
        'macosWineRegistry',
        'macosWineRegistryQuery',
        'macosWineserver',
        'macosWinedbg',
        'macosWinetricks',
        'macosTerminal',
      ],
    );
  });

  test('stable runner-kind catalog exposes named request entries', () {
    expect(RunnerKind.wine.value, 'wine');
    expect(RunnerKind.wineRegistry.value, 'wineRegistry');
    expect(RunnerKind.wineRegistryQuery.value, 'wineRegistryQuery');
    expect(RunnerKind.wineboot.value, 'wineboot');
    expect(RunnerKind.wineserver.value, 'wineserver');
    expect(RunnerKind.winedbg.value, 'winedbg');
    expect(RunnerKind.winetricks.value, 'winetricks');
    expect(RunnerKind.terminal.value, 'terminal');
    expect(RunnerKind.macosWine.value, 'macosWine');
    expect(RunnerKind.macosWineRegistry.value, 'macosWineRegistry');
    expect(RunnerKind.macosWineRegistryQuery.value, 'macosWineRegistryQuery');
    expect(RunnerKind.macosWineserver.value, 'macosWineserver');
    expect(RunnerKind.macosWinedbg.value, 'macosWinedbg');
    expect(RunnerKind.macosWinetricks.value, 'macosWinetricks');
    expect(RunnerKind.macosTerminal.value, 'macosTerminal');
  });
}
