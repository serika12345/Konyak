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
  final RuntimeInstallButtonLabel installButtonLabel;
}

enum RuntimeInstallButtonLabel { install, repair }

enum RuntimeStackStatusLabel { complete, incomplete, partial }

List<RuntimeSummary> upsertRuntime(
  List<RuntimeSummary> runtimes,
  RuntimeSummary runtime,
) {
  final replaced = runtimes.any(
    (existingRuntime) => existingRuntime.id == runtime.id,
  );
  final updated = <RuntimeSummary>[
    for (final existingRuntime in runtimes)
      existingRuntime.id == runtime.id ? runtime : existingRuntime,
    if (!replaced) runtime,
  ];

  return List.unmodifiable(updated);
}

bool showsRuntimeSection(KonyakPlatform platform) {
  return platform.isMacOS || platform.isLinux;
}

String runtimeSectionPlatform(KonyakPlatform platform) {
  return platform.isMacOS ? 'macos' : 'linux';
}

RuntimeSectionState resolveRuntimeSectionState({
  required List<RuntimeSummary> runtimes,
  required String platform,
}) {
  final runtime = (() {
    for (final candidate in runtimes.reversed) {
      if (candidate.platform == platform && candidate.stack != null) {
        return candidate;
      }
    }
    return null;
  })();
  final stack = runtime?.stack;
  final shouldOfferInstall =
      runtime != null &&
      stack != null &&
      (runtime.isInstalled != true || !stack.isComplete);
  final installButtonLabel = runtime?.isInstalled == true
      ? RuntimeInstallButtonLabel.repair
      : RuntimeInstallButtonLabel.install;

  return RuntimeSectionState(
    runtime: runtime,
    stack: stack,
    shouldOfferInstall: shouldOfferInstall,
    installButtonLabel: installButtonLabel,
  );
}

RuntimeStackStatusLabel runtimeStackStatusLabel(RuntimeStackSummary stack) {
  if (!stack.isComplete) {
    return RuntimeStackStatusLabel.incomplete;
  }

  final hasMissingOptionalComponent = stack.components.any(
    (component) => !component.isRequired && !component.isInstalled,
  );
  return hasMissingOptionalComponent
      ? RuntimeStackStatusLabel.partial
      : RuntimeStackStatusLabel.complete;
}
