part of '../../../konyak_cli.dart';

class RuntimePackageInstallRequest {
  RuntimePackageInstallRequest({
    required String runtimeLabel,
    required String archivePath,
    required Option<String> archiveSha256,
    required Iterable<String> componentArchivePaths,
    required this.componentVersions,
    required this.runtimeRoot,
    required List<String> requiredExecutableRelativePath,
    required String expectedExecutablePath,
    this.preserveExistingRuntimeFiles = false,
    List<List<String>> preserveExistingRuntimeSkipRelativePaths =
        const <List<String>>[],
    this.preserveExistingRuntimeComponents,
    this.normalizeStagingRoot,
    this.afterManifestWrite,
    this.progressSink,
  }) : runtimeLabel = _requiredNonBlankDomainString(
         runtimeLabel,
         'runtimeLabel',
       ),
       archivePath = RuntimeArchivePath(archivePath),
       archiveSha256 = archiveSha256.map(RuntimeArchiveChecksumValue.new),
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
  final Directory runtimeRoot;
  final RuntimeRelativePath requiredExecutableRelativePath;
  final RuntimeComponentPath expectedExecutablePath;
  final bool preserveExistingRuntimeFiles;
  final List<List<String>> preserveExistingRuntimeSkipRelativePaths;
  final RuntimeComponentVersions Function({
    required Directory existingRuntimeRoot,
    required Directory stagingRuntimeRoot,
    required RuntimeComponentVersions componentVersions,
  })?
  preserveExistingRuntimeComponents;
  final void Function(Directory runtimeRoot)? normalizeStagingRoot;
  final void Function(Directory runtimeRoot)? afterManifestWrite;
  final RuntimeInstallProgressSink? progressSink;
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

abstract interface class RuntimePackageInstaller {
  RuntimePackageInstallResult install(RuntimePackageInstallRequest request);
}

class DartIoRuntimePackageInstaller implements RuntimePackageInstaller {
  const DartIoRuntimePackageInstaller();

  @override
  RuntimePackageInstallResult install(RuntimePackageInstallRequest request) {
    final failure = _installRuntimeArchives(
      runtimeLabel: request.runtimeLabel,
      archivePath: request.archivePath.value,
      archiveSha256: request.archiveSha256
          .map((value) => value.value)
          .toNullable(),
      componentArchivePaths: request.componentArchivePaths
          .map((value) => value.value)
          .toIList(),
      componentVersions: request.componentVersions,
      runtimeRoot: request.runtimeRoot,
      requiredExecutableRelativePath:
          request.requiredExecutableRelativePath.value,
      expectedExecutablePath: request.expectedExecutablePath.value,
      preserveExistingRuntimeFiles: request.preserveExistingRuntimeFiles,
      preserveExistingRuntimeSkipRelativePaths:
          request.preserveExistingRuntimeSkipRelativePaths,
      preserveExistingRuntimeComponents:
          request.preserveExistingRuntimeComponents,
      normalizeStagingRoot: request.normalizeStagingRoot,
      afterManifestWrite: request.afterManifestWrite,
      progressSink: request.progressSink,
    );

    return failure == null
        ? const RuntimePackageInstallCompleted()
        : RuntimePackageInstallFailed(failure);
  }
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'stage': stage.value,
      'message': message,
      'fraction': fraction.value,
    };
  }
}

abstract interface class RuntimeInstallProgressSink {
  void emit(RuntimeInstallProgress progress);
}

final class JsonRuntimeInstallProgressSink
    implements RuntimeInstallProgressSink {
  const JsonRuntimeInstallProgressSink(this.output);

  final StringSink output;

  @override
  void emit(RuntimeInstallProgress progress) {
    output.writeln(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'runtimeInstallProgress': progress.toJson(),
      }),
    );
  }
}
