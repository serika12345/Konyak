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
  });

  final bool canUseWineRuntime;
  final bool canUseDxvk;
  final bool canUseDxmt;
  final bool canUseVkd3dProton;
  final bool canUseMetal;
  final bool canUseDxr;
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

  return BottleRuntimeControlAvailability(
    canUseWineRuntime: canUseRuntimeState && _isStackComplete(runtime),
    canUseDxvk:
        canUseRuntimeState &&
        _isRuntimeComponentAvailable(
          runtime,
          platform.isMacOS ? 'dxvk-macos' : 'dxvk',
        ),
    canUseDxmt:
        canUseRuntimeState &&
        platform.isMacOS &&
        _isRuntimeComponentAvailable(runtime, 'dxmt'),
    canUseVkd3dProton:
        canUseRuntimeState &&
        _isRuntimeComponentAvailable(runtime, 'vkd3d-proton'),
    canUseMetal:
        canUseRuntimeState && _isRuntimeComponentAvailable(runtime, 'moltenvk'),
    canUseDxr:
        canUseRuntimeState &&
        _isRuntimeComponentAvailable(runtime, 'gptk-d3dmetal'),
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
