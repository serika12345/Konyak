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
       archivePath = _requiredNonBlankDomainString(archivePath, 'archivePath'),
       archiveSha256 = _optionalRuntimePackageInstallValue(
         archiveSha256,
         'archiveSha256',
       ),
       expectedExecutablePath = _requiredNonBlankDomainString(
         expectedExecutablePath,
         'expectedExecutablePath',
       ),
       componentArchivePaths = componentArchivePaths.toIList(),
       requiredExecutableRelativePath = List.unmodifiable(
         requiredExecutableRelativePath,
       ),
       preserveExistingRuntimeSkipRelativePaths =
           preserveExistingRuntimeSkipRelativePaths
               .map(List<String>.unmodifiable)
               .toList(growable: false);

  final String runtimeLabel;
  final String archivePath;
  final Option<String> archiveSha256;
  final IList<String> componentArchivePaths;
  final RuntimeComponentVersions componentVersions;
  final Directory runtimeRoot;
  final List<String> requiredExecutableRelativePath;
  final String expectedExecutablePath;
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
      archivePath: request.archivePath,
      archiveSha256: request.archiveSha256.toNullable(),
      componentArchivePaths: request.componentArchivePaths,
      componentVersions: request.componentVersions,
      runtimeRoot: request.runtimeRoot,
      requiredExecutableRelativePath: request.requiredExecutableRelativePath,
      expectedExecutablePath: request.expectedExecutablePath,
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

Option<String> _optionalRuntimePackageInstallValue(
  Option<String> value,
  String fieldName,
) {
  return value.map((item) => _requiredNonBlankDomainString(item, fieldName));
}

class RuntimeInstallProgress {
  const RuntimeInstallProgress({
    required this.stage,
    required this.message,
    required this.fraction,
  });

  final String stage;
  final String message;
  final double fraction;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'stage': stage,
      'message': message,
      'fraction': fraction,
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
