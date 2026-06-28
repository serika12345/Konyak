import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../shared/domain_value_objects.dart';
import 'runtime_component_versions.dart';

class RuntimeStackSourceArchiveBundle {
  RuntimeStackSourceArchiveBundle({
    required String wineArchivePath,
    required Iterable<String> componentArchivePaths,
    required this.componentVersions,
  }) : wineArchivePath = RuntimeArchivePath(wineArchivePath),
       componentArchivePaths = componentArchivePaths
           .map(RuntimeArchivePath.new)
           .toIList();

  final RuntimeArchivePath wineArchivePath;
  final IList<RuntimeArchivePath> componentArchivePaths;
  final RuntimeComponentVersions componentVersions;
}

sealed class RuntimeStackSourceArchiveBundleResult {
  const RuntimeStackSourceArchiveBundleResult();
}

class RuntimeStackSourceArchiveBundleResolved
    extends RuntimeStackSourceArchiveBundleResult {
  const RuntimeStackSourceArchiveBundleResolved(this.bundle);

  final RuntimeStackSourceArchiveBundle bundle;
}

class RuntimeStackSourceArchiveBundleFailed
    extends RuntimeStackSourceArchiveBundleResult {
  const RuntimeStackSourceArchiveBundleFailed(this.message);

  final String message;
}
