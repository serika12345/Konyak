import 'package:fpdart/fpdart.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_models.dart';

Option<RuntimeRecord> runtimeById(
  List<RuntimeRecord> runtimes,
  RuntimeId runtimeId,
) {
  return firstWhereOption(runtimes, (runtime) => runtime.id == runtimeId);
}

Option<RuntimeVersion> runtimeWineVersion(RuntimeRecord runtime) {
  return runtime.stack.flatMap(
    (stack) => firstWhereOption(
      stack.components,
      (component) => component.id.value == 'wine',
    ).flatMap((component) => component.version),
  );
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
