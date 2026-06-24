import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';

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
  required RuntimeSummary? runtime,
  required bool canChangeSettings,
  required bool hasPendingRuntimeSettings,
}) {
  final canUseRuntimeState =
      canChangeSettings &&
      !hasPendingRuntimeSettings &&
      runtime?.isInstalled == true;

  final canUseDxmt =
      canUseRuntimeState &&
      platform.isMacOS &&
      _isRuntimeBackendAvailable(runtime, 'dxmt');
  final canUseDxr =
      canUseRuntimeState &&
      _isRuntimeBackendAvailable(runtime, 'gptk-d3dmetal');

  return BottleRuntimeControlAvailability(
    canUseWineRuntime: canUseRuntimeState && _isStackComplete(runtime),
    canUseDxvk:
        canUseRuntimeState &&
        _isRuntimeBackendAvailable(
          runtime,
          platform.isMacOS ? 'dxvk-macos' : 'dxvk',
        ),
    canUseDxmt: canUseDxmt,
    canUseVkd3dProton:
        canUseRuntimeState &&
        _isRuntimeBackendAvailable(runtime, 'vkd3d-proton'),
    canUseMetal:
        canUseRuntimeState && _isRuntimeComponentAvailable(runtime, 'moltenvk'),
    canUseDxr: canUseDxr,
    canUseDxmtDlssMetalFx:
        canUseDxmt && _runtimeHasRequiredShim(runtime, 'dxmt'),
    canUseD3DMetalDlssMetalFx:
        canUseDxr && _runtimeHasRequiredShim(runtime, 'gptk-d3dmetal'),
  );
}

bool _isStackComplete(RuntimeSummary? runtime) {
  return runtime?.stack?.isComplete == true;
}

bool _isRuntimeComponentAvailable(RuntimeSummary? runtime, String componentId) {
  if (runtime?.isInstalled != true) {
    return false;
  }

  final stack = runtime?.stack;
  if (stack == null) {
    return false;
  }

  for (final component in stack.components) {
    if (component.id == componentId) {
      return component.missingPaths.isEmpty;
    }
  }

  return false;
}

bool _isRuntimeBackendAvailable(RuntimeSummary? runtime, String backendId) {
  if (runtime?.isInstalled != true) {
    return false;
  }

  final stack = runtime?.stack;
  if (stack == null) {
    return false;
  }

  for (final backend in stack.backends) {
    if (backend.id == backendId) {
      return backend.isAvailable;
    }
  }

  return _isRuntimeComponentAvailable(runtime, backendId);
}

bool _runtimeHasRequiredShim(RuntimeSummary? runtime, String componentId) {
  final stack = runtime?.stack;
  if (runtime?.isInstalled != true || stack == null) {
    return false;
  }

  final requiredNames = const <String>['nvapi64', 'nvngx'];
  for (final component in stack.components) {
    if (component.id != componentId) {
      continue;
    }

    if (!component.isInstalled) {
      return false;
    }

    return requiredNames.every(
      (name) => !component.missingPaths.any(
        (path) => path.toLowerCase().contains(name),
      ),
    );
  }

  return false;
}
