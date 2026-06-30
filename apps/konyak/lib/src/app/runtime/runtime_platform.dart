import '../../cli/konyak_cli_client.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';

final class ManagedRuntimePlatform {
  const ManagedRuntimePlatform({
    required this.runtimeId,
    required this.platformName,
    required this.displayName,
  });

  final String runtimeId;
  final String platformName;
  final String displayName;
}

sealed class RuntimeForPlatformSelection {
  const RuntimeForPlatformSelection();
}

final class RuntimeForPlatformFound extends RuntimeForPlatformSelection {
  const RuntimeForPlatformFound(this.runtime);

  final RuntimeSummary runtime;
}

final class RuntimeForPlatformMissing extends RuntimeForPlatformSelection {
  const RuntimeForPlatformMissing(this.managedRuntime);

  final ManagedRuntimePlatform managedRuntime;
}

ManagedRuntimePlatform managedRuntimePlatform(KonyakPlatform platform) {
  return switch (platform) {
    KonyakPlatform.macos => const ManagedRuntimePlatform(
      runtimeId: macosWineRuntimeId,
      platformName: 'macos',
      displayName: 'Konyak macOS Wine',
    ),
    KonyakPlatform.linux => const ManagedRuntimePlatform(
      runtimeId: linuxWineRuntimeId,
      platformName: 'linux',
      displayName: 'Konyak Linux Wine',
    ),
  };
}

RuntimeForPlatformSelection runtimeForPlatformSelection(
  KonyakPlatform platform,
  List<RuntimeSummary> runtimes,
) {
  final managedRuntime = managedRuntimePlatform(platform);
  final matchingRuntimes = runtimes
      .where((runtime) => runtime.id == managedRuntime.runtimeId)
      .take(1)
      .toList(growable: false);
  return switch (matchingRuntimes) {
    [final runtime] => RuntimeForPlatformFound(runtime),
    _ => RuntimeForPlatformMissing(managedRuntime),
  };
}

List<RuntimeSummary> runtimesForPlatform(
  KonyakPlatform platform,
  List<RuntimeSummary> runtimes,
) {
  final managedRuntime = managedRuntimePlatform(platform);

  return List.unmodifiable(
    runtimes.where(
      (runtime) => runtime.platform == managedRuntime.platformName,
    ),
  );
}

RuntimeInstallLoadResult installedRuntimeForPlatform(
  List<RuntimeSummary> runtimes,
  KonyakPlatform platform,
) {
  return switch (runtimeForPlatformSelection(platform, runtimes)) {
    RuntimeForPlatformFound(:final runtime) => InstalledRuntime(runtime),
    RuntimeForPlatformMissing() => const RuntimeInstallLoadFailure(
      exitCode: 75,
      message: 'Runtime was installed but could not be reloaded.',
      diagnostic: '',
    ),
  };
}

List<RuntimeSummary> upsertRuntimeSummary(
  List<RuntimeSummary> runtimes,
  RuntimeSummary runtime,
) {
  final hasExistingRuntime = runtimes.any(
    (existingRuntime) => existingRuntime.id == runtime.id,
  );
  return List.unmodifiable([
    ...runtimes.map(
      (existingRuntime) =>
          existingRuntime.id == runtime.id ? runtime : existingRuntime,
    ),
    if (!hasExistingRuntime) runtime,
  ]);
}
