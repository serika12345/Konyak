import '../domain/runtime/runtime_catalogs.dart';
import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_update_checker.dart';
import '../domain/runtime/runtime_update_support.dart';
import '../domain/shared/domain_value_objects.dart';
import '../domain/update/update_records.dart';
import 'release_metadata_fetcher.dart';

class DartIoRuntimeUpdateChecker implements RuntimeUpdateChecker {
  const DartIoRuntimeUpdateChecker({
    required this.runtimeCatalog,
    this.releaseMetadataFetcher = const DartIoRuntimeReleaseMetadataFetcher(),
  });

  final RuntimeCatalog runtimeCatalog;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  RuntimeUpdateCheckResult check(RuntimeId runtimeId) {
    final runtime = runtimeById(runtimeCatalog.listRuntimes(), runtimeId.value);
    return runtime.match(
      () => RuntimeUpdateCheckResult.runtimeNotFound(runtimeId),
      checkRuntime,
    );
  }

  RuntimeUpdateCheckResult checkRuntime(RuntimeRecord runtime) {
    final currentVersion = runtimeWineVersion(runtime);
    return runtime.versionUrl.match(
      () => unknownRuntimeUpdateRecord(
        runtime: runtime,
        currentVersion: currentVersion,
      ),
      (versionUrl) {
        if (versionUrl.value.trim().isEmpty) {
          return unknownRuntimeUpdateRecord(
            runtime: runtime,
            currentVersion: currentVersion,
          );
        }

        final metadata = releaseMetadataFetcher.fetch(versionUrl);
        return switch (metadata) {
          RuntimeReleaseMetadataFetched(:final metadata) =>
            runtimeUpdateFromMetadata(
              runtime: runtime,
              versionUrl: versionUrl.value,
              currentVersion: currentVersion,
              metadata: metadata,
            ),
          RuntimeReleaseMetadataFetchFailed(:final message) =>
            RuntimeUpdateCheckFailed(message),
        };
      },
    );
  }
}
