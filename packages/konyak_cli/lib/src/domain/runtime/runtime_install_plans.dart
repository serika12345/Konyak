import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_install_operation_models.dart';
import 'runtime_models.dart';

part 'runtime_install_plans.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeWineInstallPlan with _$RuntimeWineInstallPlan {
  const RuntimeWineInstallPlan._();

  const factory RuntimeWineInstallPlan.unsupported(String message) =
      RuntimeWineInstallUnsupported;

  const factory RuntimeWineInstallPlan.alreadyInstalled(RuntimeRecord runtime) =
      RuntimeWineInstallAlreadyInstalled;

  const factory RuntimeWineInstallPlan.incompleteWithoutSource(String message) =
      RuntimeWineInstallIncompleteWithoutSource;

  const factory RuntimeWineInstallPlan.fromSourceManifest({
    required RuntimeSourceManifestUrl sourceManifest,
    required RuntimeSourceManifestSignature sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
  }) = RuntimeWineInstallFromSourceManifest;

  factory RuntimeWineInstallPlan.fromArchive({
    required RuntimeArchivePath archivePath,
    required RuntimeArchiveChecksum archiveSha256,
    required Iterable<RuntimeArchivePath> componentArchivePaths,
    required bool preserveExistingRuntimeFiles,
  }) {
    return RuntimeWineInstallPlan._fromArchive(
      archivePath: archivePath,
      archiveSha256: archiveSha256,
      componentArchivePaths: componentArchivePaths.toIList(),
      preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
    );
  }

  const factory RuntimeWineInstallPlan._fromArchive({
    required RuntimeArchivePath archivePath,
    required RuntimeArchiveChecksum archiveSha256,
    required IList<RuntimeArchivePath> componentArchivePaths,
    required bool preserveExistingRuntimeFiles,
  }) = RuntimeWineInstallFromArchive;

  factory RuntimeWineInstallPlan.downloadArchive({
    required RuntimeArchiveUrl archiveUrl,
    required String archiveFileName,
    required RuntimeArchiveChecksum archiveSha256,
    required Iterable<RuntimeArchivePath> componentArchivePaths,
    required bool preserveExistingRuntimeFiles,
  }) {
    return RuntimeWineInstallPlan._downloadArchive(
      archiveUrl: archiveUrl,
      archiveFileName: archiveFileName,
      archiveSha256: archiveSha256,
      componentArchivePaths: componentArchivePaths.toIList(),
      preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
    );
  }

  const factory RuntimeWineInstallPlan._downloadArchive({
    required RuntimeArchiveUrl archiveUrl,
    required String archiveFileName,
    required RuntimeArchiveChecksum archiveSha256,
    required IList<RuntimeArchivePath> componentArchivePaths,
    required bool preserveExistingRuntimeFiles,
  }) = RuntimeWineInstallDownloadArchive;

  const factory RuntimeWineInstallPlan.missingArchiveSource(String message) =
      RuntimeWineInstallMissingArchiveSource;
}

RuntimeWineInstallPlan runtimeWineInstallPlan({
  required bool hostPlatformSupported,
  required String unsupportedPlatformMessage,
  required RuntimeInstallRequestOperation requestOperation,
  required RuntimeRecord currentRuntime,
  required Option<RuntimeSourceManifestUrl> configuredSourceManifest,
  required Option<RuntimeSourceManifestSignatureUrl>
  configuredSourceManifestSignature,
  required String defaultArchiveFileName,
  required Option<String> missingArchiveMessage,
  required Option<String> incompleteRuntimeMessage,
}) {
  if (!hostPlatformSupported) {
    return RuntimeWineInstallPlan.unsupported(unsupportedPlatformMessage);
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
    return RuntimeWineInstallPlan.alreadyInstalled(currentRuntime);
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
      RuntimeWineInstallPlan.incompleteWithoutSource,
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
      RuntimeWineInstallPlan.fromSourceManifest(
        sourceManifest: sourceManifest,
        sourceManifestSignature: signature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeLocalArchiveSource(
      :final archivePath,
      :final archiveChecksum,
      :final componentArchivePaths,
    ) =>
      RuntimeWineInstallPlan.fromArchive(
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
      RuntimeWineInstallPlan.downloadArchive(
        archiveUrl: archiveUrl,
        archiveFileName: fileNameFromUrl(
          archiveUrl.value,
        ).match(() => defaultArchiveFileName, (value) => value),
        archiveSha256: archiveChecksum,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
      ),
    RuntimeConfiguredArchiveSource() =>
      RuntimeWineInstallPlan.missingArchiveSource(
        missingArchiveMessage.getOrElse(
          () => 'Runtime source manifest is not configured.',
        ),
      ),
  };
}

RuntimeInstallSource _runtimeInstallSourceWithConfiguredManifest({
  required RuntimeInstallSource requestSource,
  required Option<RuntimeSourceManifestUrl> configuredSourceManifest,
  required Option<RuntimeSourceManifestSignatureUrl>
  configuredSourceManifestSignature,
}) {
  if (requestSource is! RuntimeConfiguredArchiveSource) {
    return requestSource;
  }

  return configuredSourceManifest.match(
    () => requestSource,
    (sourceManifest) => RuntimeInstallSource.sourceManifest(
      sourceManifest: sourceManifest,
      signature: runtimeSourceManifestSignature(
        configuredSourceManifestSignature,
      ),
    ),
  );
}
