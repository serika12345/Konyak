import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/bottles/bottle_runtime_control_availability.dart';
import 'package:konyak/src/runtimes/runtime_summary.dart';

void main() {
  test('disables every runtime control while a settings update is pending', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(
        isComplete: true,
        components: const <String>[
          'dxvk-macos',
          'dxmt',
          'moltenvk',
          'gptk-d3dmetal',
        ],
      ),
      canChangeSettings: true,
      hasPendingRuntimeSettings: true,
    );

    expect(availability.canUseWineRuntime, isFalse);
    expect(availability.canUseDxvk, isFalse);
    expect(availability.canUseDxmt, isFalse);
    expect(availability.canUseVkd3dProton, isFalse);
    expect(availability.canUseMetal, isFalse);
    expect(availability.canUseDxr, isFalse);
  });

  test('uses macOS runtime components for macOS controls', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(
        isComplete: true,
        components: const <String>[
          'dxvk-macos',
          'dxmt',
          'moltenvk',
          'gptk-d3dmetal',
        ],
      ),
      canChangeSettings: true,
      hasPendingRuntimeSettings: false,
    );

    expect(availability.canUseWineRuntime, isTrue);
    expect(availability.canUseDxvk, isTrue);
    expect(availability.canUseDxmt, isTrue);
    expect(availability.canUseMetal, isTrue);
    expect(availability.canUseDxr, isTrue);
    expect(availability.canUseVkd3dProton, isFalse);
  });

  test('uses Linux runtime components for Vulkan controls', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.linux,
      runtime: _runtime(
        isComplete: true,
        components: const <String>['dxvk', 'vkd3d-proton'],
      ),
      canChangeSettings: true,
      hasPendingRuntimeSettings: false,
    );

    expect(availability.canUseWineRuntime, isTrue);
    expect(availability.canUseDxvk, isTrue);
    expect(availability.canUseDxmt, isFalse);
    expect(availability.canUseVkd3dProton, isTrue);
    expect(availability.canUseMetal, isFalse);
    expect(availability.canUseDxr, isFalse);
  });
}

RuntimeSummary _runtime({
  required bool isComplete,
  required List<String> components,
}) {
  return RuntimeSummary(
    id: 'runtime',
    name: 'Runtime',
    platform: 'test',
    architecture: 'x86_64',
    runnerKind: 'wine',
    isBundled: false,
    isUpdateable: true,
    isInstalled: true,
    stack: RuntimeStackSummary(
      id: 'stack',
      name: 'Stack',
      compatibilityTarget: 'stack',
      isComplete: isComplete,
      components: components
          .map(
            (id) => RuntimeStackComponentSummary(
              id: id,
              name: id,
              role: 'test',
              isRequired: true,
              isInstalled: true,
              paths: const <String>['/runtime/component'],
              missingPaths: const <String>[],
            ),
          )
          .toList(growable: false),
    ),
  );
}
