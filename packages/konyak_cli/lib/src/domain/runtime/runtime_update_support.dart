import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import 'runtime_models.dart';

Option<RuntimeRecord> runtimeById(
  List<RuntimeRecord> runtimes,
  RuntimeId runtimeId,
) {
  for (final runtime in runtimes) {
    if (runtime.id == runtimeId) {
      return Option.of(runtime);
    }
  }

  return const Option.none();
}

Option<RuntimeVersion> runtimeWineVersion(RuntimeRecord runtime) {
  return runtime.stack.flatMap((stack) {
    for (final component in stack.components) {
      if (component.id.value == 'wine') {
        return component.version;
      }
    }

    return const Option.none();
  });
}

UpdateCheckStatus updateStatus({
  required Option<StringDomainValueObject> currentVersion,
  required StringDomainValueObject latestVersion,
}) {
  return currentVersion.match(() => UpdateCheckStatus('unknown'), (version) {
    if (version.value.trim().isEmpty) {
      return UpdateCheckStatus('unknown');
    }

    if (_normalizeRuntimeVersion(version.value) ==
        _normalizeRuntimeVersion(latestVersion.value)) {
      return UpdateCheckStatus('current');
    }

    return UpdateCheckStatus('available');
  });
}

String _normalizeRuntimeVersion(String version) {
  return version
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^wine-devel-'), '')
      .replaceFirst(RegExp(r'^v'), '');
}
