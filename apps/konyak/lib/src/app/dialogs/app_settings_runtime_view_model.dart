import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';

class RuntimeSectionState {
  const RuntimeSectionState({
    required this.runtime,
    required this.stack,
    required this.shouldOfferInstall,
    required this.installButtonLabel,
  });

  final RuntimeSummary? runtime;
  final RuntimeStackSummary? stack;
  final bool shouldOfferInstall;
  final String installButtonLabel;
}

List<RuntimeSummary> upsertRuntime(
  List<RuntimeSummary> runtimes,
  RuntimeSummary runtime,
) {
  final updated = <RuntimeSummary>[];
  var replaced = false;
  for (final existingRuntime in runtimes) {
    if (existingRuntime.id == runtime.id) {
      updated.add(runtime);
      replaced = true;
    } else {
      updated.add(existingRuntime);
    }
  }

  if (!replaced) {
    updated.add(runtime);
  }

  return List.unmodifiable(updated);
}

bool showsRuntimeSection(KonyakPlatform platform) {
  return platform.isMacOS || platform.isLinux;
}

String runtimeSectionTitle(KonyakPlatform platform) {
  return platform.isMacOS ? 'macOS Runtime' : 'Linux Runtime';
}

String runtimeSectionPlatform(KonyakPlatform platform) {
  return platform.isMacOS ? 'macos' : 'linux';
}

RuntimeSectionState resolveRuntimeSectionState({
  required List<RuntimeSummary> runtimes,
  required String platform,
}) {
  final runtime = runtimes
      .where((runtime) => runtime.platform == platform)
      .fold<RuntimeSummary?>(
        null,
        (selected, runtime) => runtime.stack != null ? runtime : selected,
      );
  final stack = runtime?.stack;
  final shouldOfferInstall =
      runtime != null &&
      stack != null &&
      (runtime.isInstalled != true || !stack.isComplete);
  final installButtonLabel = runtime?.isInstalled == true
      ? 'Repair'
      : 'Install';

  return RuntimeSectionState(
    runtime: runtime,
    stack: stack,
    shouldOfferInstall: shouldOfferInstall,
    installButtonLabel: installButtonLabel,
  );
}

String componentStatusLabel(RuntimeStackComponentSummary component) {
  final status = component.isInstalled ? 'Installed' : 'Missing';
  if (component.version == null || component.version!.trim().isEmpty) {
    return status;
  }

  return '$status | ${component.version}';
}

String runtimeStackStatusLabel(RuntimeStackSummary stack) {
  if (!stack.isComplete) {
    return 'Incomplete';
  }

  final hasMissingOptionalComponent = stack.components.any(
    (component) => !component.isRequired && !component.isInstalled,
  );
  return hasMissingOptionalComponent ? 'Partial' : 'Complete';
}
