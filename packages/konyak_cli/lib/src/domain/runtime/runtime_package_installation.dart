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
    required RuntimeArchivePath archivePath,
    required Option<RuntimeArchiveChecksumValue> archiveSha256,
    required Iterable<RuntimeArchivePath> componentArchivePaths,
    required RuntimeComponentVersions componentVersions,
    required RuntimeRootPath runtimeRoot,
    required RuntimeRelativePath requiredExecutableRelativePath,
    required RuntimeComponentPath expectedExecutablePath,
    bool preserveExistingRuntimeFiles = false,
    Iterable<RuntimeRelativePath> preserveExistingRuntimeSkipRelativePaths =
        const <RuntimeRelativePath>[],
  }) {
    return RuntimePackageInstallRequest._validated(
      runtimeLabel: requiredNonBlankDomainString(runtimeLabel, 'runtimeLabel'),
      archivePath: archivePath,
      archiveSha256: archiveSha256,
      componentArchivePaths: componentArchivePaths.toIList(),
      componentVersions: componentVersions,
      runtimeRoot: runtimeRoot,
      requiredExecutableRelativePath: requiredExecutableRelativePath,
      expectedExecutablePath: expectedExecutablePath,
      preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
      preserveExistingRuntimeSkipRelativePaths:
          preserveExistingRuntimeSkipRelativePaths.toIList(),
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
    required IList<RuntimeRelativePath>
    preserveExistingRuntimeSkipRelativePaths,
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
