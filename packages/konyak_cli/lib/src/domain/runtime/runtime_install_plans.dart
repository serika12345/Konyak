import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_install_operation_models.dart';
import 'runtime_models.dart';

sealed class RuntimeWineInstallPlan {
  const RuntimeWineInstallPlan();
}

final class RuntimeWineInstallUnsupported extends RuntimeWineInstallPlan {
  const RuntimeWineInstallUnsupported(this.message);

  final String message;
}

final class RuntimeWineInstallAlreadyInstalled extends RuntimeWineInstallPlan {
  const RuntimeWineInstallAlreadyInstalled(this.runtime);

  final RuntimeRecord runtime;
}

final class RuntimeWineInstallIncompleteWithoutSource
    extends RuntimeWineInstallPlan {
  const RuntimeWineInstallIncompleteWithoutSource(this.message);

  final String message;
}

final class RuntimeWineInstallFromSourceManifest
    extends RuntimeWineInstallPlan {
  const RuntimeWineInstallFromSourceManifest({
    required this.sourceManifest,
    required this.sourceManifestSignature,
    required this.preserveExistingRuntimeFiles,
  });

  final RuntimeSourceManifestUrl sourceManifest;
  final RuntimeSourceManifestSignature sourceManifestSignature;
  final bool preserveExistingRuntimeFiles;
}

final class RuntimeWineInstallFromArchive extends RuntimeWineInstallPlan {
  RuntimeWineInstallFromArchive({
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

final class RuntimeWineInstallDownloadArchive extends RuntimeWineInstallPlan {
  RuntimeWineInstallDownloadArchive({
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

final class RuntimeWineInstallMissingArchiveSource
    extends RuntimeWineInstallPlan {
  const RuntimeWineInstallMissingArchiveSource(this.message);

  final String message;
}

RuntimeWineInstallPlan runtimeWineInstallPlan({
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
    return RuntimeWineInstallUnsupported(unsupportedPlatformMessage);
  }

  final requestSource = requestOperation.installSource;
  final installSource = _runtimeInstallSourceWithConfiguredManifest(
    requestSource: requestSource,
    configuredSourceManifest: configuredSourceManifest,
    configuredSourceManifestSignature: configuredSourceManifestSignature,
  );
  final hasExplicitInstallSource = requestSource.hasExplicitInstallSource;
  final currentRuntimeInstalled = currentRuntime.isInstalled.match(
    () => false,
    (isInstalled) => isInstalled,
  );
  final currentRuntimeStackComplete = currentRuntime.stack.match(
    () => false,
    (stack) => stack.isComplete,
  );
  final currentRuntimeStackIncompleteOrMissing = currentRuntime.stack.match(
    () => true,
    (stack) => !stack.isComplete,
  );
  final shouldPreserveExistingRuntimeFiles =
      !requestOperation.force &&
      currentRuntimeInstalled &&
      currentRuntimeStackIncompleteOrMissing &&
      !hasExplicitInstallSource;

  if (!requestOperation.force &&
      !hasExplicitInstallSource &&
      currentRuntimeInstalled &&
      currentRuntimeStackComplete) {
    return RuntimeWineInstallAlreadyInstalled(currentRuntime);
  }

  if (!requestOperation.force &&
      currentRuntimeInstalled &&
      currentRuntimeStackIncompleteOrMissing &&
      !hasExplicitInstallSource &&
      installSource is! RuntimeSourceManifestInstallSource) {
    return incompleteRuntimeMessage.match(
      () => _runtimeWineInstallPlanForSource(
        installSource: installSource,
        shouldPreserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        defaultArchiveFileName: defaultArchiveFileName,
        missingArchiveMessage: missingArchiveMessage,
      ),
      RuntimeWineInstallIncompleteWithoutSource.new,
    );
  }

  return _runtimeWineInstallPlanForSource(
    installSource: installSource,
    shouldPreserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
    defaultArchiveFileName: defaultArchiveFileName,
    missingArchiveMessage: missingArchiveMessage,
  );
}

RuntimeWineInstallPlan _runtimeWineInstallPlanForSource({
  required RuntimeInstallSource installSource,
  required bool shouldPreserveExistingRuntimeFiles,
  required String defaultArchiveFileName,
  required Option<String> missingArchiveMessage,
}) {
  return switch (installSource) {
    RuntimeSourceManifestInstallSource(
      :final sourceManifest,
      :final signature,
    ) =>
      RuntimeWineInstallFromSourceManifest(
        sourceManifest: sourceManifest,
        sourceManifestSignature: signature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeLocalArchiveSource(
      :final archivePath,
      :final archiveChecksum,
      :final componentArchivePaths,
    ) =>
      RuntimeWineInstallFromArchive(
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
      RuntimeWineInstallDownloadArchive(
        archiveUrl: archiveUrl,
        archiveFileName: fileNameFromUrl(
          archiveUrl.value,
        ).match(() => defaultArchiveFileName, (value) => value),
        archiveSha256: archiveChecksum,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeConfiguredArchiveSource() => RuntimeWineInstallMissingArchiveSource(
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
      signature: runtimeSourceManifestSignature(
        configuredSourceManifestSignature,
      ),
    ),
  );
}
