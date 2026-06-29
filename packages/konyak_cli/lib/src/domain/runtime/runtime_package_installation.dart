import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_component_versions.dart';

part 'runtime_package_installation.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimePackageInstallRequest
    with _$RuntimePackageInstallRequest {
  const RuntimePackageInstallRequest._();

  factory RuntimePackageInstallRequest({
    required String runtimeLabel,
    required String archivePath,
    required Option<String> archiveSha256,
    required Iterable<String> componentArchivePaths,
    required RuntimeComponentVersions componentVersions,
    required String runtimeRoot,
    required List<String> requiredExecutableRelativePath,
    required String expectedExecutablePath,
    bool preserveExistingRuntimeFiles = false,
    List<List<String>> preserveExistingRuntimeSkipRelativePaths =
        const <List<String>>[],
  }) {
    return RuntimePackageInstallRequest._validated(
      runtimeLabel: requiredNonBlankDomainString(runtimeLabel, 'runtimeLabel'),
      archivePath: RuntimeArchivePath(archivePath),
      archiveSha256: archiveSha256.map(RuntimeArchiveChecksumValue.new),
      componentArchivePaths: componentArchivePaths
          .map(RuntimeArchivePath.new)
          .toIList(),
      componentVersions: componentVersions,
      runtimeRoot: RuntimeRootPath(runtimeRoot),
      requiredExecutableRelativePath: RuntimeRelativePath(
        requiredExecutableRelativePath,
      ),
      expectedExecutablePath: RuntimeComponentPath(expectedExecutablePath),
      preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
      preserveExistingRuntimeSkipRelativePaths:
          preserveExistingRuntimeSkipRelativePaths
              .map(List<String>.unmodifiable)
              .toList(growable: false),
    );
  }

  const factory RuntimePackageInstallRequest._validated({
    required String runtimeLabel,
    required RuntimeArchivePath archivePath,
    required Option<RuntimeArchiveChecksumValue> archiveSha256,
    required IList<RuntimeArchivePath> componentArchivePaths,
    required RuntimeComponentVersions componentVersions,
    required RuntimeRootPath runtimeRoot,
    required RuntimeRelativePath requiredExecutableRelativePath,
    required RuntimeComponentPath expectedExecutablePath,
    required bool preserveExistingRuntimeFiles,
    required List<List<String>> preserveExistingRuntimeSkipRelativePaths,
  }) = _RuntimePackageInstallRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimePackageInstallResult with _$RuntimePackageInstallResult {
  const RuntimePackageInstallResult._();

  const factory RuntimePackageInstallResult.completed() =
      RuntimePackageInstallCompleted;

  const factory RuntimePackageInstallResult.failed(String message) =
      RuntimePackageInstallFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeInstallProgress with _$RuntimeInstallProgress {
  const RuntimeInstallProgress._();

  factory RuntimeInstallProgress({
    required String stage,
    required String message,
    required num fraction,
  }) {
    return RuntimeInstallProgress._validated(
      stage: RuntimeInstallProgressStage(stage),
      message: message,
      fraction: RuntimeInstallProgressFraction(fraction),
    );
  }

  const factory RuntimeInstallProgress._validated({
    required RuntimeInstallProgressStage stage,
    required String message,
    required RuntimeInstallProgressFraction fraction,
  }) = _RuntimeInstallProgress;
}
