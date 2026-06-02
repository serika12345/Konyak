part of '../konyak_cli.dart';

RuntimeRecord? _runtimeById(List<RuntimeRecord> runtimes, String runtimeId) {
  for (final runtime in runtimes) {
    if (runtime.id == runtimeId) {
      return runtime;
    }
  }

  return null;
}

String? _runtimeWineVersion(RuntimeRecord runtime) {
  final stack = runtime.stack.toNullable();
  if (stack == null) {
    return null;
  }

  for (final component in stack.components) {
    if (component.id == 'wine') {
      return component.version.toNullable();
    }
  }

  return null;
}

String _updateStatus({
  required String? currentVersion,
  required String latestVersion,
}) {
  if (currentVersion == null || currentVersion.trim().isEmpty) {
    return 'unknown';
  }

  if (_normalizeRuntimeVersion(currentVersion) ==
      _normalizeRuntimeVersion(latestVersion)) {
    return 'current';
  }

  return 'available';
}

String _normalizeRuntimeVersion(String version) {
  return version
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^wine-devel-'), '')
      .replaceFirst(RegExp(r'^v'), '');
}
