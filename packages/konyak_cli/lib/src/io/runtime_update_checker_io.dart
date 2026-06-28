part of '../../konyak_cli.dart';

class DartIoRuntimeUpdateChecker implements RuntimeUpdateChecker {
  const DartIoRuntimeUpdateChecker({
    required this.runtimeCatalog,
    this.releaseMetadataFetcher = const DartIoRuntimeReleaseMetadataFetcher(),
  });

  final RuntimeCatalog runtimeCatalog;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  RuntimeUpdateCheckResult check(String runtimeId) {
    final runtime = runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    return runtime.match(
      () => RuntimeUpdateRuntimeNotFound(runtimeId),
      _checkRuntime,
    );
  }

  RuntimeUpdateCheckResult _checkRuntime(RuntimeRecord runtime) {
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

        final metadata = releaseMetadataFetcher.fetch(versionUrl.value);
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
