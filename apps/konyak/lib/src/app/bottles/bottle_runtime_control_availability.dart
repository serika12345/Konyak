import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import 'runtime_capabilities_state.dart';

export 'runtime_capabilities_state.dart';

class BottleRuntimeControlAvailability {
  const BottleRuntimeControlAvailability({
    required this.canUseWineRuntime,
    required this.canUseDxvk,
    required this.canUseDxmt,
    required this.canUseVkd3dProton,
    required this.canUseMetal,
    required this.canUseDxr,
    required this.canUseDxmtDlssMetalFx,
    required this.canUseD3DMetalDlssMetalFx,
  });

  const BottleRuntimeControlAvailability.disabled()
    : canUseWineRuntime = false,
      canUseDxvk = false,
      canUseDxmt = false,
      canUseVkd3dProton = false,
      canUseMetal = false,
      canUseDxr = false,
      canUseDxmtDlssMetalFx = false,
      canUseD3DMetalDlssMetalFx = false;

  final bool canUseWineRuntime;
  final bool canUseDxvk;
  final bool canUseDxmt;
  final bool canUseVkd3dProton;
  final bool canUseMetal;
  final bool canUseDxr;
  final bool canUseDxmtDlssMetalFx;
  final bool canUseD3DMetalDlssMetalFx;
}

BottleRuntimeControlAvailability resolveBottleRuntimeControlAvailability({
  required KonyakPlatform platform,
  required RuntimeCapabilitiesState runtimeCapabilitiesState,
  required bool canChangeSettings,
  required bool hasPendingRuntimeSettings,
}) {
  return switch (runtimeCapabilitiesState) {
    AvailableRuntimeCapabilities(:final runtime)
        when canChangeSettings &&
            !hasPendingRuntimeSettings &&
            runtime.isInstalled == true =>
      _runtimeControlAvailability(platform: platform, runtime: runtime),
    LoadingRuntimeCapabilities() ||
    UnavailableRuntimeCapabilities() ||
    AvailableRuntimeCapabilities() =>
      const BottleRuntimeControlAvailability.disabled(),
  };
}

BottleRuntimeControlAvailability _runtimeControlAvailability({
  required KonyakPlatform platform,
  required RuntimeSummary runtime,
}) {
  final canUseDxmt =
      platform.isMacOS && _isRuntimeBackendAvailable(runtime, 'dxmt');
  final canUseDxr = _isRuntimeBackendAvailable(runtime, 'gptk-d3dmetal');

  return BottleRuntimeControlAvailability(
    canUseWineRuntime: _isStackComplete(runtime),
    canUseDxvk: _isRuntimeBackendAvailable(
      runtime,
      platform.isMacOS ? 'dxvk-macos' : 'dxvk',
    ),
    canUseDxmt: canUseDxmt,
    canUseVkd3dProton: _isRuntimeBackendAvailable(runtime, 'vkd3d-proton'),
    canUseMetal: _isRuntimeComponentAvailable(runtime, 'moltenvk'),
    canUseDxr: canUseDxr,
    canUseDxmtDlssMetalFx:
        canUseDxmt && _runtimeHasRequiredShim(runtime, 'dxmt'),
    canUseD3DMetalDlssMetalFx:
        canUseDxr && _runtimeHasRequiredShim(runtime, 'gptk-d3dmetal'),
  );
}

bool _isStackComplete(RuntimeSummary runtime) {
  return switch (runtime.stack) {
    RuntimeStackSummary(:final isComplete) => isComplete,
    _ => false,
  };
}

bool _isRuntimeComponentAvailable(RuntimeSummary runtime, String componentId) {
  return switch (runtime.stack) {
    RuntimeStackSummary(:final components) =>
      components
          .where((component) => component.id == componentId)
          .any((component) => component.missingPaths.isEmpty),
    _ => false,
  };
}

bool _isRuntimeBackendAvailable(RuntimeSummary runtime, String backendId) {
  return switch (runtime.stack) {
    RuntimeStackSummary(:final backends) =>
      backends
          .where((backend) => backend.id == backendId)
          .any((backend) => backend.isAvailable),
    _ => false,
  };
}

bool _runtimeHasRequiredShim(RuntimeSummary runtime, String componentId) {
  final requiredNames = const <String>['nvapi64', 'nvngx'];
  return switch (runtime.stack) {
    RuntimeStackSummary(:final components) =>
      components
          .where((component) => component.id == componentId)
          .take(1)
          .any(
            (component) =>
                component.isInstalled &&
                requiredNames.every(
                  (name) => !component.missingPaths.any(
                    (path) => path.toLowerCase().contains(name),
                  ),
                ),
          ),
    _ => false,
  };
}
