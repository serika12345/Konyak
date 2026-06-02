part of '../../../konyak_cli.dart';

Option<RuntimeRecord> _runtimeById(
  List<RuntimeRecord> runtimes,
  String runtimeId,
) {
  for (final runtime in runtimes) {
    if (runtime.id == runtimeId) {
      return Option.of(runtime);
    }
  }

  return const Option.none();
}

Option<String> _runtimeWineVersion(RuntimeRecord runtime) {
  return runtime.stack.flatMap((stack) {
    for (final component in stack.components) {
      if (component.id == 'wine') {
        return component.version;
      }
    }

    return const Option.none();
  });
}

String _updateStatus({
  required Option<String> currentVersion,
  required String latestVersion,
}) {
  return currentVersion.match(() => 'unknown', (version) {
    if (version.trim().isEmpty) {
      return 'unknown';
    }

    if (_normalizeRuntimeVersion(version) ==
        _normalizeRuntimeVersion(latestVersion)) {
      return 'current';
    }

    return 'available';
  });
}

String _normalizeRuntimeVersion(String version) {
  return version
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^wine-devel-'), '')
      .replaceFirst(RegExp(r'^v'), '');
}
