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
  required Option<String> configuredSourceManifest,
  required Option<String> configuredSourceManifestSignature,
  required Option<String> defaultArchiveUrl,
  required String defaultArchiveFileName,
  required Option<String> missingArchiveMessage,
  required Option<String> incompleteRuntimeMessage,
}) {
  if (!hostPlatformSupported) {
    return _RuntimeWineInstallUnsupported(unsupportedPlatformMessage);
  }

  final componentArchivePaths = List<String>.unmodifiable(
    requestOperation.componentArchivePaths,
  );
  final sourceManifest = requestOperation.sourceManifest.match(
    () => configuredSourceManifest,
    Option.of,
  );
  final sourceManifestSignature = requestOperation.sourceManifestSignature
      .match(() => configuredSourceManifestSignature, Option.of);
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
      sourceManifest.isNone()) {
    final incompleteRuntimePlan = incompleteRuntimeMessage.map(
      _RuntimeWineInstallIncompleteWithoutSource.new,
    );
    if (incompleteRuntimePlan.isSome()) {
      return incompleteRuntimePlan.getOrElse(
        () => throw StateError('Expected incomplete runtime install plan.'),
      );
    }
  }

  final sourceManifestPlan = sourceManifest.match(
    () => const Option<_RuntimeWineInstallPlan>.none(),
    (sourceManifest) => Option<_RuntimeWineInstallPlan>.of(
      _RuntimeWineInstallFromSourceManifest(
        sourceManifest: sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    ),
  );
  if (sourceManifestPlan.isSome()) {
    return sourceManifestPlan.getOrElse(
      () => throw StateError('Expected source manifest install plan.'),
    );
  }

  final archivePathPlan = requestOperation.archivePath.map(
    (archivePath) => _RuntimeWineInstallFromArchive(
      archivePath: archivePath,
      archiveSha256: requestOperation.archiveSha256,
      componentArchivePaths: componentArchivePaths,
      preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
    ),
  );
  if (archivePathPlan.isSome()) {
    return archivePathPlan.getOrElse(
      () => throw StateError('Expected archive install plan.'),
    );
  }

  final archiveUrl = requestOperation.archiveUrl.match(
    () => defaultArchiveUrl,
    Option.of,
  );
  return archiveUrl.match(
    () => _RuntimeWineInstallMissingArchiveSource(
      missingArchiveMessage.getOrElse(
        () => 'Runtime archive is not configured.',
      ),
    ),
    (archiveUrl) => _RuntimeWineInstallDownloadArchive(
      archiveUrl: archiveUrl,
      archiveFileName: _fileNameFromUrl(archiveUrl) ?? defaultArchiveFileName,
      archiveSha256: requestOperation.archiveSha256,
      componentArchivePaths: componentArchivePaths,
      preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
    ),
  );
}
