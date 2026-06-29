import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'runtime_component_versions.dart';

part 'runtime_source_bundle_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackSourceArchiveBundle
    with _$RuntimeStackSourceArchiveBundle {
  const RuntimeStackSourceArchiveBundle._();

  factory RuntimeStackSourceArchiveBundle({
    required RuntimeArchivePath wineArchivePath,
    required Iterable<RuntimeArchivePath> componentArchivePaths,
    required RuntimeComponentVersions componentVersions,
  }) {
    return RuntimeStackSourceArchiveBundle._validated(
      wineArchivePath: wineArchivePath,
      componentArchivePaths: componentArchivePaths.toIList(),
      componentVersions: componentVersions,
    );
  }

  const factory RuntimeStackSourceArchiveBundle._validated({
    required RuntimeArchivePath wineArchivePath,
    required IList<RuntimeArchivePath> componentArchivePaths,
    required RuntimeComponentVersions componentVersions,
  }) = _RuntimeStackSourceArchiveBundle;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeStackSourceArchiveBundleResult
    with _$RuntimeStackSourceArchiveBundleResult {
  const RuntimeStackSourceArchiveBundleResult._();

  const factory RuntimeStackSourceArchiveBundleResult.resolved(
    RuntimeStackSourceArchiveBundle bundle,
  ) = RuntimeStackSourceArchiveBundleResolved;

  const factory RuntimeStackSourceArchiveBundleResult.failed(String message) =
      RuntimeStackSourceArchiveBundleFailed;
}
