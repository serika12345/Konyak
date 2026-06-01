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

ManagedRuntimePlatform? managedRuntimePlatform(KonyakPlatform platform) {
  if (platform.isMacOS) {
    return const ManagedRuntimePlatform(
      runtimeId: macosWineRuntimeId,
      platformName: 'macos',
      displayName: 'Konyak macOS Wine',
    );
  }

  if (platform.isLinux) {
    return const ManagedRuntimePlatform(
      runtimeId: linuxWineRuntimeId,
      platformName: 'linux',
      displayName: 'Konyak Linux Wine',
    );
  }

  return null;
}

RuntimeSummary? runtimeForPlatform(
  KonyakPlatform platform,
  List<RuntimeSummary> runtimes,
) {
  final managedRuntime = managedRuntimePlatform(platform);
  if (managedRuntime == null) {
    return null;
  }

  for (final runtime in runtimes) {
    if (runtime.id == managedRuntime.runtimeId) {
      return runtime;
    }
  }

  return null;
}

List<RuntimeSummary> runtimesForPlatform(
  KonyakPlatform platform,
  List<RuntimeSummary> runtimes,
) {
  final managedRuntime = managedRuntimePlatform(platform);
  if (managedRuntime == null) {
    return const <RuntimeSummary>[];
  }

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
  final runtime = runtimeForPlatform(platform, runtimes);
  if (runtime == null) {
    return const RuntimeInstallLoadFailure(
      exitCode: 75,
      message: 'Runtime was installed but could not be reloaded.',
      diagnostic: '',
    );
  }
  return InstalledRuntime(runtime);
}

List<RuntimeSummary> upsertRuntimeSummary(
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
