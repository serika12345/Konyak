import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_component_versions.dart';

class RuntimePackageInstallRequest {
  RuntimePackageInstallRequest({
    required String runtimeLabel,
    required String archivePath,
    required Option<String> archiveSha256,
    required Iterable<String> componentArchivePaths,
    required this.componentVersions,
    required String runtimeRoot,
    required List<String> requiredExecutableRelativePath,
    required String expectedExecutablePath,
    this.preserveExistingRuntimeFiles = false,
    List<List<String>> preserveExistingRuntimeSkipRelativePaths =
        const <List<String>>[],
  }) : runtimeLabel = requiredNonBlankDomainString(
         runtimeLabel,
         'runtimeLabel',
       ),
       archivePath = RuntimeArchivePath(archivePath),
       archiveSha256 = archiveSha256.map(RuntimeArchiveChecksumValue.new),
       runtimeRoot = RuntimeRootPath(runtimeRoot),
       expectedExecutablePath = RuntimeComponentPath(expectedExecutablePath),
       componentArchivePaths = componentArchivePaths
           .map(RuntimeArchivePath.new)
           .toIList(),
       requiredExecutableRelativePath = RuntimeRelativePath(
         requiredExecutableRelativePath,
       ),
       preserveExistingRuntimeSkipRelativePaths =
           preserveExistingRuntimeSkipRelativePaths
               .map(List<String>.unmodifiable)
               .toList(growable: false);

  final String runtimeLabel;
  final RuntimeArchivePath archivePath;
  final Option<RuntimeArchiveChecksumValue> archiveSha256;
  final IList<RuntimeArchivePath> componentArchivePaths;
  final RuntimeComponentVersions componentVersions;
  final RuntimeRootPath runtimeRoot;
  final RuntimeRelativePath requiredExecutableRelativePath;
  final RuntimeComponentPath expectedExecutablePath;
  final bool preserveExistingRuntimeFiles;
  final List<List<String>> preserveExistingRuntimeSkipRelativePaths;
}

sealed class RuntimePackageInstallResult {
  const RuntimePackageInstallResult();
}

class RuntimePackageInstallCompleted extends RuntimePackageInstallResult {
  const RuntimePackageInstallCompleted();
}

class RuntimePackageInstallFailed extends RuntimePackageInstallResult {
  const RuntimePackageInstallFailed(this.message);

  final String message;
}

class RuntimeInstallProgress {
  RuntimeInstallProgress({
    required String stage,
    required this.message,
    required num fraction,
  }) : stage = RuntimeInstallProgressStage(stage),
       fraction = RuntimeInstallProgressFraction(fraction);

  final RuntimeInstallProgressStage stage;
  final String message;
  final RuntimeInstallProgressFraction fraction;
}
