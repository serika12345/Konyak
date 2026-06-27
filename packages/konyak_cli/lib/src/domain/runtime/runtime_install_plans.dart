part of '../../../konyak_cli.dart';

sealed class _RuntimeWineInstallPlan {
  const _RuntimeWineInstallPlan();
}

final class _RuntimeWineInstallUnsupported extends _RuntimeWineInstallPlan {
  const _RuntimeWineInstallUnsupported(this.message);

  final String message;
}

final class _RuntimeWineInstallAlreadyInstalled
    extends _RuntimeWineInstallPlan {
  const _RuntimeWineInstallAlreadyInstalled(this.runtime);

  final RuntimeRecord runtime;
}

final class _RuntimeWineInstallIncompleteWithoutSource
    extends _RuntimeWineInstallPlan {
  const _RuntimeWineInstallIncompleteWithoutSource(this.message);

  final String message;
}

final class _RuntimeWineInstallFromSourceManifest
    extends _RuntimeWineInstallPlan {
  const _RuntimeWineInstallFromSourceManifest({
    required this.sourceManifest,
    required this.sourceManifestSignature,
    required this.preserveExistingRuntimeFiles,
  });

  final RuntimeSourceManifestUrl sourceManifest;
  final RuntimeSourceManifestSignature sourceManifestSignature;
  final bool preserveExistingRuntimeFiles;
}

final class _RuntimeWineInstallFromArchive extends _RuntimeWineInstallPlan {
  _RuntimeWineInstallFromArchive({
    required this.archivePath,
    required this.archiveSha256,
    required Iterable<RuntimeArchivePath> componentArchivePaths,
    required this.preserveExistingRuntimeFiles,
  }) : componentArchivePaths = componentArchivePaths.toIList();

  final RuntimeArchivePath archivePath;
  final RuntimeArchiveChecksum archiveSha256;
  final IList<RuntimeArchivePath> componentArchivePaths;
  final bool preserveExistingRuntimeFiles;
}

final class _RuntimeWineInstallDownloadArchive extends _RuntimeWineInstallPlan {
  _RuntimeWineInstallDownloadArchive({
    required this.archiveUrl,
    required this.archiveFileName,
    required this.archiveSha256,
    required Iterable<RuntimeArchivePath> componentArchivePaths,
    required this.preserveExistingRuntimeFiles,
  }) : componentArchivePaths = componentArchivePaths.toIList();

  final RuntimeArchiveUrl archiveUrl;
  final String archiveFileName;
  final RuntimeArchiveChecksum archiveSha256;
  final IList<RuntimeArchivePath> componentArchivePaths;
  final bool preserveExistingRuntimeFiles;
}

final class _RuntimeWineInstallMissingArchiveSource
    extends _RuntimeWineInstallPlan {
  const _RuntimeWineInstallMissingArchiveSource(this.message);

  final String message;
}

_RuntimeWineInstallPlan _runtimeWineInstallPlan({
  required bool hostPlatformSupported,
  required String unsupportedPlatformMessage,
  required RuntimeInstallRequestOperation requestOperation,
  required RuntimeRecord currentRuntime,
  required Option<String> configuredSourceManifest,
  required Option<String> configuredSourceManifestSignature,
  required String defaultArchiveFileName,
  required Option<String> missingArchiveMessage,
  required Option<String> incompleteRuntimeMessage,
}) {
  if (!hostPlatformSupported) {
    return _RuntimeWineInstallUnsupported(unsupportedPlatformMessage);
  }

  final requestSource = requestOperation.installSource;
  final installSource = _runtimeInstallSourceWithConfiguredManifest(
    requestSource: requestSource,
    configuredSourceManifest: configuredSourceManifest,
    configuredSourceManifestSignature: configuredSourceManifestSignature,
  );
  final hasExplicitInstallSource = requestSource.hasExplicitInstallSource;
  final shouldPreserveExistingRuntimeFiles =
      !requestOperation.force &&
      currentRuntime.isInstalled.toNullable() == true &&
      currentRuntime.stack.toNullable()?.isComplete != true &&
      !hasExplicitInstallSource;

  if (!requestOperation.force &&
      !hasExplicitInstallSource &&
      currentRuntime.isInstalled.toNullable() == true &&
      currentRuntime.stack.toNullable()?.isComplete == true) {
    return _RuntimeWineInstallAlreadyInstalled(currentRuntime);
  }

  if (!requestOperation.force &&
      currentRuntime.isInstalled.toNullable() == true &&
      currentRuntime.stack.toNullable()?.isComplete != true &&
      !hasExplicitInstallSource &&
      installSource is! RuntimeSourceManifestInstallSource) {
    final incompleteRuntimePlan = incompleteRuntimeMessage.map(
      _RuntimeWineInstallIncompleteWithoutSource.new,
    );
    if (incompleteRuntimePlan.isSome()) {
      return incompleteRuntimePlan.getOrElse(
        () => throw StateError('Expected incomplete runtime install plan.'),
      );
    }
  }

  return switch (installSource) {
    RuntimeSourceManifestInstallSource(
      :final sourceManifest,
      :final signature,
    ) =>
      _RuntimeWineInstallFromSourceManifest(
        sourceManifest: sourceManifest,
        sourceManifestSignature: signature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeLocalArchiveSource(
      :final archivePath,
      :final archiveChecksum,
      :final componentArchivePaths,
    ) =>
      _RuntimeWineInstallFromArchive(
        archivePath: archivePath,
        archiveSha256: archiveChecksum,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeRemoteArchiveSource(
      :final archiveUrl,
      :final archiveChecksum,
      :final componentArchivePaths,
    ) =>
      _RuntimeWineInstallDownloadArchive(
        archiveUrl: archiveUrl,
        archiveFileName: _fileNameFromUrl(
          archiveUrl.value,
        ).match(() => defaultArchiveFileName, (value) => value),
        archiveSha256: archiveChecksum,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeConfiguredArchiveSource() => _RuntimeWineInstallMissingArchiveSource(
      missingArchiveMessage.getOrElse(
        () => 'Runtime source manifest is not configured.',
      ),
    ),
  };
}

RuntimeInstallSource _runtimeInstallSourceWithConfiguredManifest({
  required RuntimeInstallSource requestSource,
  required Option<String> configuredSourceManifest,
  required Option<String> configuredSourceManifestSignature,
}) {
  if (requestSource is! RuntimeConfiguredArchiveSource) {
    return requestSource;
  }

  return configuredSourceManifest.match(
    () => requestSource,
    (sourceManifest) => RuntimeSourceManifestInstallSource(
      sourceManifest: sourceManifest,
      signature: _runtimeSourceManifestSignature(
        configuredSourceManifestSignature,
      ),
    ),
  );
}
