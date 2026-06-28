import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/bottles/bottle_runtime_control_availability.dart';
import 'package:konyak/src/runtimes/runtime_summary.dart';

void main() {
  test('disables every runtime control while a settings update is pending', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(
        components: const <String>[
          'dxvk-macos',
          'dxmt',
          'moltenvk',
          'gptk-d3dmetal',
        ],
        backends: [
          _backend('dxvk-macos', componentIds: const <String>['dxvk-macos']),
          _backend('dxmt', componentIds: const <String>['dxmt']),
          _backend(
            'gptk-d3dmetal',
            componentIds: const <String>['gptk-d3dmetal'],
          ),
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
    expect(availability.canUseDxmtDlssMetalFx, isFalse);
    expect(availability.canUseD3DMetalDlssMetalFx, isFalse);
  });

  test('uses macOS runtime components for macOS controls', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(
        components: const <String>[
          'dxvk-macos',
          'dxmt',
          'moltenvk',
          'gptk-d3dmetal',
        ],
        backends: [
          _backend('dxvk-macos', componentIds: const <String>['dxvk-macos']),
          _backend('dxmt', componentIds: const <String>['dxmt']),
          _backend(
            'gptk-d3dmetal',
            componentIds: const <String>['gptk-d3dmetal'],
          ),
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
    expect(availability.canUseDxmtDlssMetalFx, isTrue);
    expect(availability.canUseD3DMetalDlssMetalFx, isTrue);
    expect(availability.canUseVkd3dProton, isFalse);
  });

  test('requires NVIDIA shim paths for macOS DLSS MetalFX controls', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(
        components: const <String>['dxmt', 'gptk-d3dmetal'],
        missingPaths: const <String, List<String>>{
          'dxmt': <String>['/runtime/lib/dxmt/x86_64-windows/nvngx.dll'],
          'gptk-d3dmetal': <String>[
            '/runtime/components/gptk-d3dmetal/lib/wine/x86_64-unix/nvapi64.so',
          ],
        },
        backends: [
          RuntimeStackBackendSummary(
            id: 'dxmt',
            name: 'DXMT',
            role: 'd3d10-d3d11-metal-translation',
            componentIds: const <String>['dxmt'],
            missingComponentIds: const <String>[],
            missingPaths: const <String>[],
          ),
          RuntimeStackBackendSummary(
            id: 'gptk-d3dmetal',
            name: 'GPTK/D3DMetal',
            role: 'd3d12-metal-translation',
            componentIds: const <String>['gptk-d3dmetal'],
            missingComponentIds: const <String>[],
            missingPaths: const <String>[],
          ),
        ],
      ),
      canChangeSettings: true,
      hasPendingRuntimeSettings: false,
    );

    expect(availability.canUseDxmt, isTrue);
    expect(availability.canUseDxr, isTrue);
    expect(availability.canUseDxmtDlssMetalFx, isFalse);
    expect(availability.canUseD3DMetalDlssMetalFx, isFalse);
  });

  test('uses backend availability before component availability', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(
        components: const <String>['dxvk-macos', 'moltenvk'],
        backends: [
          RuntimeStackBackendSummary(
            id: 'dxvk-macos',
            name: 'DXVK-macOS',
            role: 'd3d9-d3d11-metal-translation',
            componentIds: const <String>['dxvk-macos', 'moltenvk'],
            missingComponentIds: const <String>['moltenvk'],
            missingPaths: const <String>['/runtime/lib/libMoltenVK.dylib'],
          ),
        ],
      ),
      canChangeSettings: true,
      hasPendingRuntimeSettings: false,
    );

    expect(availability.canUseDxvk, isFalse);
  });

  test('requires backend availability for runtime-backed controls', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.macos,
      runtime: _runtime(components: const <String>['dxvk-macos', 'moltenvk']),
      canChangeSettings: true,
      hasPendingRuntimeSettings: false,
    );

    expect(availability.canUseDxvk, isFalse);
  });

  test('uses Linux runtime components for Vulkan controls', () {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: KonyakPlatform.linux,
      runtime: _runtime(
        components: const <String>['dxvk', 'vkd3d-proton'],
        backends: [
          _backend('dxvk', componentIds: const <String>['dxvk']),
          _backend(
            'vkd3d-proton',
            componentIds: const <String>['vkd3d-proton'],
          ),
        ],
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
    expect(availability.canUseDxmtDlssMetalFx, isFalse);
    expect(availability.canUseD3DMetalDlssMetalFx, isFalse);
  });
}

RuntimeStackBackendSummary _backend(
  String id, {
  required List<String> componentIds,
}) {
  return RuntimeStackBackendSummary(
    id: id,
    name: id,
    role: 'test',
    componentIds: componentIds,
    missingComponentIds: const <String>[],
    missingPaths: const <String>[],
  );
}

RuntimeSummary _runtime({
  required List<String> components,
  Map<String, List<String>> missingPaths = const <String, List<String>>{},
  List<RuntimeStackBackendSummary> backends =
      const <RuntimeStackBackendSummary>[],
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
      backends: backends,
      components: components
          .map(
            (id) => RuntimeStackComponentSummary(
              id: id,
              name: id,
              role: 'test',
              isRequired: true,
              paths: const <String>['/runtime/component'],
              missingPaths: missingPaths[id] ?? const <String>[],
            ),
          )
          .toList(growable: false),
    ),
  );
}
