import 'support/cli_contract_full_helpers.dart';

void main() {
  group('macOS version capability type fronts', () {
    test('operating system version parser returns typed macOS versions', () {
      expect(
        macosMajorVersionFromOperatingSystemVersion(
          'Version 16.0.0 (Build 25A1)',
        ).toNullable(),
        MacosMajorVersion(16),
      );
      expect(
        macosMajorVersionFromOperatingSystemVersion(
          'Darwin Kernel Version 25',
        ).toNullable(),
        MacosMajorVersion(25),
      );
      expect(
        macosMajorVersionFromOperatingSystemVersion('macOS').isNone(),
        isTrue,
      );
      expect(() => MacosMajorVersion(0), throwsA(isA<ArgumentError>()));
    });

    test('planner keeps DLSS MetalFX gated by typed macOS version', () {
      final bottle = BottleRecord(
        id: 'steam',
        name: 'Steam',
        path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
        windowsVersion: 'win10',
        runtimeSettings: Option.of(
          BottleRuntimeSettings(dxrEnabled: true, dlssMetalFx: true),
        ),
      );

      final macos16Request = ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const HostEnvironment.empty(),
        macosMajorVersion: Option.of(MacosMajorVersion(16)),
      ).plan(bottle: bottle, programPath: ProgramPath('/Games/steam.exe'));
      final macos15Request = ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const HostEnvironment.empty(),
        macosMajorVersion: Option.of(MacosMajorVersion(15)),
      ).plan(bottle: bottle, programPath: ProgramPath('/Games/steam.exe'));

      expect(
        macos16Request.toNullable()?.environment.toMap(),
        containsPair('D3DM_ENABLE_METALFX', '1'),
      );
      expect(
        macos15Request.toNullable()?.environment.toMap(),
        isNot(containsPair('D3DM_ENABLE_METALFX', '1')),
      );
    });
  });
}
