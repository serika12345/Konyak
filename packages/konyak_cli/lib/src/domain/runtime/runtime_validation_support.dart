import 'package:fpdart/fpdart.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_validation_models.dart';

abstract interface class FileStatusProbe {
  bool exists(String path);
}

abstract interface class RuntimeStackVersionProbe {
  Option<RuntimeVersion> versionFor({
    required RuntimeRootPath runtimeRoot,
    required RuntimeComponentId componentId,
  });
}

RuntimeValidationCheck runtimePathCheck({
  required String id,
  required String name,
  required String path,
  required FileStatusProbe fileStatusProbe,
}) {
  final exists = fileStatusProbe.exists(path);
  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: exists,
    message: exists ? 'Found $path.' : 'Missing $path.',
  );
}

RuntimeValidationCheck runtimeAnyPathCheck({
  required String id,
  required String name,
  required List<String> paths,
  required FileStatusProbe fileStatusProbe,
}) {
  return _firstExistingPath(paths, fileStatusProbe).match(
    () => RuntimeValidationCheck(
      id: id,
      name: name,
      isRequired: true,
      isPassed: false,
      message: 'Missing one of: ${paths.join(', ')}.',
    ),
    (existingPath) => RuntimeValidationCheck(
      id: id,
      name: name,
      isRequired: true,
      isPassed: true,
      message: 'Found $existingPath.',
    ),
  );
}

Option<String> _firstExistingPath(
  Iterable<String> paths,
  FileStatusProbe fileStatusProbe,
) {
  for (final path in paths) {
    if (fileStatusProbe.exists(path)) {
      return Option.of(path);
    }
  }

  return const Option.none();
}

List<String> macosWineLoaderLibraryPaths(String runtimeRoot) {
  return <String>[
    domainJoinPath(runtimeRoot, const ['lib']),
    domainJoinPath(runtimeRoot, const ['lib64']),
  ];
}

String runtimeLoaderFailureMessage(RuntimeExecutableProbeResult result) {
  final stderr = result.stderr.trim();
  if (stderr.isNotEmpty) {
    return stderr;
  }

  final stdout = result.stdout.trim();
  if (stdout.isNotEmpty) {
    return stdout;
  }

  return 'wineloader --version exited with code ${result.exitCode}.';
}

bool isSha256Hex(String value) {
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);
}
