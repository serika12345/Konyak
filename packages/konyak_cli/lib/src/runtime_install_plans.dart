part of '../konyak_cli.dart';

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

  final String sourceManifest;
  final Option<String> sourceManifestSignature;
  final bool preserveExistingRuntimeFiles;
}

final class _RuntimeWineInstallFromArchive extends _RuntimeWineInstallPlan {
  _RuntimeWineInstallFromArchive({
    required this.archivePath,
    required this.archiveSha256,
    required List<String> componentArchivePaths,
    required this.preserveExistingRuntimeFiles,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths);

  final String archivePath;
  final Option<String> archiveSha256;
  final List<String> componentArchivePaths;
  final bool preserveExistingRuntimeFiles;
}

final class _RuntimeWineInstallDownloadArchive extends _RuntimeWineInstallPlan {
  _RuntimeWineInstallDownloadArchive({
    required this.archiveUrl,
    required this.archiveFileName,
    required this.archiveSha256,
    required List<String> componentArchivePaths,
    required this.preserveExistingRuntimeFiles,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths);

  final String archiveUrl;
  final String archiveFileName;
  final Option<String> archiveSha256;
  final List<String> componentArchivePaths;
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
  required String? configuredSourceManifest,
  required String? configuredSourceManifestSignature,
  required String? defaultArchiveUrl,
  required String defaultArchiveFileName,
  required String? missingArchiveMessage,
  required String? incompleteRuntimeMessage,
}) {
  if (!hostPlatformSupported) {
    return _RuntimeWineInstallUnsupported(unsupportedPlatformMessage);
  }

  final componentArchivePaths = List<String>.unmodifiable(
    requestOperation.componentArchivePaths,
  );
  final sourceManifest =
      requestOperation.sourceManifest.toNullable() ?? configuredSourceManifest;
  final sourceManifestSignature =
      requestOperation.sourceManifestSignature.toNullable() ??
      configuredSourceManifestSignature;
  final hasExplicitInstallSource =
      requestOperation.archivePath.isSome() ||
      requestOperation.archiveUrl.isSome() ||
      componentArchivePaths.isNotEmpty ||
      requestOperation.sourceManifest.isSome();
  final shouldPreserveExistingRuntimeFiles =
      !requestOperation.force &&
      currentRuntime.isInstalled.toNullable() == true &&
      currentRuntime.stack.toNullable()?.isComplete != true &&
      !hasExplicitInstallSource;

  if (!requestOperation.force &&
      requestOperation.archivePath.isNone() &&
      requestOperation.archiveUrl.isNone() &&
      componentArchivePaths.isEmpty &&
      requestOperation.sourceManifest.isNone() &&
      currentRuntime.isInstalled.toNullable() == true &&
      currentRuntime.stack.toNullable()?.isComplete == true) {
    return _RuntimeWineInstallAlreadyInstalled(currentRuntime);
  }

  if (!requestOperation.force &&
      currentRuntime.isInstalled.toNullable() == true &&
      currentRuntime.stack.toNullable()?.isComplete != true &&
      !hasExplicitInstallSource &&
      sourceManifest == null) {
    final message = incompleteRuntimeMessage;
    if (message != null) {
      return _RuntimeWineInstallIncompleteWithoutSource(message);
    }
  }

  if (sourceManifest != null) {
    return _RuntimeWineInstallFromSourceManifest(
      sourceManifest: sourceManifest,
      sourceManifestSignature: Option.fromNullable(sourceManifestSignature),
      preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
    );
  }

  final archivePath = requestOperation.archivePath.toNullable();
  if (archivePath != null) {
    return _RuntimeWineInstallFromArchive(
      archivePath: archivePath,
      archiveSha256: requestOperation.archiveSha256,
      componentArchivePaths: componentArchivePaths,
      preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
    );
  }

  final archiveUrl =
      requestOperation.archiveUrl.toNullable() ?? defaultArchiveUrl;
  if (archiveUrl == null) {
    return _RuntimeWineInstallMissingArchiveSource(
      missingArchiveMessage ?? 'Runtime archive is not configured.',
    );
  }

  return _RuntimeWineInstallDownloadArchive(
    archiveUrl: archiveUrl,
    archiveFileName: _fileNameFromUrl(archiveUrl) ?? defaultArchiveFileName,
    archiveSha256: requestOperation.archiveSha256,
    componentArchivePaths: componentArchivePaths,
    preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
  );
}
