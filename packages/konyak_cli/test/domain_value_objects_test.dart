import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

void main() {
  test('semantic string value objects reject blank required values', () {
    final constructors = <String, Object Function(String)>{
      'AppId': AppId.new,
      'BottleId': BottleId.new,
      'BottleName': BottleName.new,
      'BottlePath': BottlePath.new,
      'ProgramId': ProgramId.new,
      'ProgramName': ProgramName.new,
      'ProgramPath': ProgramPath.new,
      'RuntimeId': RuntimeId.new,
      'RuntimeName': RuntimeName.new,
      'RuntimeStackId': RuntimeStackId.new,
      'RuntimeComponentId': RuntimeComponentId.new,
      'WinetricksVerbId': WinetricksVerbId.new,
    };

    for (final entry in constructors.entries) {
      expect(
        () => entry.value(' '),
        throwsA(isA<ArgumentError>()),
        reason: entry.key,
      );
    }
  });

  test('semantic string value objects compare by concrete type and value', () {
    expect(BottleId('steam'), BottleId('steam'));
    expect(BottleId('steam'), isNot(ProgramId('steam')));
  });

  test('domain value objects expose sealed bases for switch patterns', () {
    expect(_describeDomainValue(BottleId('steam')), 'bottle:steam');
    expect(_describeDomainValue(WindowsDpiScaling(144)), 'dpi:144');
    expect(
      _describeDomainValue(RuntimeInstallProgressFraction(0.25)),
      'progress:0.25',
    );
    expect(
      _describeDomainValue(RuntimeRelativePath(['drive_c', 'Program Files'])),
      'runtime-path:drive_c/Program Files',
    );
  });

  test('finite value objects reject unknown values', () {
    expect(WindowsVersion('win10').value, 'win10');
    expect(EnhancedSyncMode('msync').value, 'msync');
    expect(DxvkHudMode('partial').value, 'partial');
    expect(
      RuntimeSettingsControlKey('graphicsBackend').value,
      'graphicsBackend',
    );
    expect(GraphicsBackendKind('vkd3dProton').value, 'vkd3dProton');
    expect(GraphicsBackendSignalKind('peImport').value, 'peImport');
    expect(GraphicsBackendConfidence('high').value, 'high');
    expect(ProgramSource('globalStartMenu').value, 'globalStartMenu');
    expect(RuntimePlatformName('macos').value, 'macos');
    expect(RuntimeDistributionKind('managed').value, 'managed');
    expect(UpdateCheckStatus('available').value, 'available');
    expect(UpdateInstallStatus('installed').value, 'installed');

    expect(() => WindowsVersion('vista'), throwsA(isA<ArgumentError>()));
    expect(() => EnhancedSyncMode('sync'), throwsA(isA<ArgumentError>()));
    expect(() => DxvkHudMode('minimal'), throwsA(isA<ArgumentError>()));
    expect(
      () => RuntimeSettingsControlKey('unknown'),
      throwsA(isA<ArgumentError>()),
    );
    expect(() => GraphicsBackendKind('metal'), throwsA(isA<ArgumentError>()));
    expect(
      () => GraphicsBackendSignalKind('registry'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => GraphicsBackendConfidence('sure'),
      throwsA(isA<ArgumentError>()),
    );
    expect(() => ProgramSource('desktop'), throwsA(isA<ArgumentError>()));
    expect(() => RuntimePlatformName('windows'), throwsA(isA<ArgumentError>()));
    expect(
      () => RuntimeDistributionKind('external'),
      throwsA(isA<ArgumentError>()),
    );
    expect(() => UpdateCheckStatus('new'), throwsA(isA<ArgumentError>()));
    expect(() => UpdateInstallStatus('done'), throwsA(isA<ArgumentError>()));
  });

  test('numeric value objects enforce existing bounds and steps', () {
    expect(WindowsBuildVersion(0).value, 0);
    expect(WindowsBuildVersion(999999).value, 999999);
    expect(WindowsDpiScaling(96).value, 96);
    expect(WindowsDpiScaling(480).value, 480);
    expect(RuntimeInstallProgressFraction(0).value, 0);
    expect(RuntimeInstallProgressFraction(0.5).value, 0.5);
    expect(RuntimeInstallProgressFraction(1).value, 1);

    expect(() => WindowsBuildVersion(-1), throwsA(isA<ArgumentError>()));
    expect(() => WindowsBuildVersion(1000000), throwsA(isA<ArgumentError>()));
    expect(() => WindowsDpiScaling(95), throwsA(isA<ArgumentError>()));
    expect(() => WindowsDpiScaling(121), throwsA(isA<ArgumentError>()));
    expect(() => WindowsDpiScaling(481), throwsA(isA<ArgumentError>()));
    expect(
      () => RuntimeInstallProgressFraction(-0.01),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => RuntimeInstallProgressFraction(1.01),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('optional semantic strings preserve explicit empty defaults', () {
    expect(ProgramLocale('').value, '');
    expect(ProgramArguments('').value, '');
    expect(ProgramLogPath('  ').value, '');
    expect(WineDebugChannels('  +seh,+pid  ').value, '+seh,+pid');
  });

  test('environment variable names reject shell assignment syntax', () {
    expect(ProgramEnvironmentVariableName('WINEDEBUG').value, 'WINEDEBUG');
    expect(
      () => ProgramEnvironmentVariableName('WINEDEBUG=+seh'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ProgramEnvironmentVariableName(' '),
      throwsA(isA<ArgumentError>()),
    );
  });
}

String _describeDomainValue(DomainValueObject<Object?> valueObject) {
  return switch (valueObject) {
    BottleId(:final value) => 'bottle:$value',
    WindowsDpiScaling(:final value) => 'dpi:$value',
    RuntimeInstallProgressFraction(:final value) => 'progress:$value',
    RuntimeRelativePath(:final components) =>
      'runtime-path:${components.join('/')}',
    _ => 'other',
  };
}
