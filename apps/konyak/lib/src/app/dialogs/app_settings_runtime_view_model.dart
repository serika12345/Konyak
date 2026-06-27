import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';

sealed class RuntimeSectionState {
  const RuntimeSectionState();
}

final class RuntimeSectionUnavailable extends RuntimeSectionState {
  const RuntimeSectionUnavailable();
}

final class RuntimeSectionAvailable extends RuntimeSectionState {
  const RuntimeSectionAvailable({
    required this.runtime,
    required this.stack,
    required this.shouldOfferInstall,
    required this.installButtonLabel,
  });

  final RuntimeSummary runtime;
  final RuntimeStackSummary stack;
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
  for (final candidate in runtimes.reversed) {
    switch (candidate.stack) {
      case final RuntimeStackSummary stack when candidate.platform == platform:
        final shouldOfferInstall =
            candidate.isInstalled != true || !stack.isComplete;
        final installButtonLabel = candidate.isInstalled == true
            ? RuntimeInstallButtonLabel.repair
            : RuntimeInstallButtonLabel.install;

        return RuntimeSectionAvailable(
          runtime: candidate,
          stack: stack,
          shouldOfferInstall: shouldOfferInstall,
          installButtonLabel: installButtonLabel,
        );
      case _:
        break;
    }
  }

  return const RuntimeSectionUnavailable();
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
