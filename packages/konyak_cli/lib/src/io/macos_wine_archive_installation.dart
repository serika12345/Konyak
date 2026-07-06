import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_component_versions.dart';
import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_package_installation.dart';
import '../domain/runtime/runtime_platform_support.dart';
import '../domain/runtime/runtime_source_bundle_models.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'directory_copy_support.dart';
import 'gptk_wine_installation.dart';
import 'macos_wine_installation.dart';
import 'platform_runtime_sources.dart';
import 'runtime_archive_install_support.dart';
import 'runtime_gptk_support.dart';
import 'runtime_install_progress_io.dart';
import 'runtime_platform_records.dart';
import 'runtime_probes.dart';
import 'runtime_source_archive_downloads.dart';
import 'runtime_source_archive_support.dart';
import 'runtime_source_manifest_support.dart';

extension MacosWineArchiveInstallation on DartIoMacosWineInstaller {
  MacosWineInstallResult installMacosWineArchive({
    required String archivePath,
    required Option<String> archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    RuntimeComponentVersions componentVersions =
        const RuntimeComponentVersions.empty(),
    bool preserveExistingRuntimeFiles = false,
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'macOS Wine',
        archivePath: RuntimeArchivePath(archivePath),
        archiveSha256: archiveSha256.map(RuntimeArchiveChecksumValue.new),
        componentArchivePaths: componentArchivePaths.map(
          RuntimeArchivePath.new,
        ),
        componentVersions: componentVersions,
        runtimeRoot: RuntimeRootPath(macosWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            macosKonyakRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: RuntimeComponentPath(
          macosWineExecutable(environment),
        ),
        preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
      ),
      progressSink: progressSink,
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return MacosWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: runtimeStackVersionProbe,
    );

    if (!runtime.isInstalled.match(() => false, (value) => value)) {
      return MacosWineInstallFailed(
        'macOS Wine archive did not install '
        '`${runtime.executablePath.match(() => 'unknown executable', (value) => value.value)}`.',
      );
    }

    return runtime.stack.match(
      () => const MacosWineInstallFailed(
        'macOS Wine archive installed but runtime stack is incomplete: '
        'runtime stack metadata is missing.',
      ),
      (stack) {
        if (!stack.isComplete) {
          return MacosWineInstallFailed(
            'macOS Wine archive installed but runtime stack is incomplete: '
            '${incompleteMacosWineStackSummary(stack)}.',
          );
        }

        emitRuntimeInstallProgress(
          progressSink,
          stage: 'complete',
          message: 'Installed Konyak macOS Wine.',
          fraction: 1,
        );

        return MacosWineInstallCompleted(runtime: runtime);
      },
    );
  }

  MacosWineInstallResult installMacosWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      return runtimeStackSourceManifestFromPayload(manifestPayload).match(
        () => const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        ),
        (manifest) {
          final bundleResult = resolveRuntimeStackSourceArchiveBundle(
            manifest: manifest,
            platformSpec: macosKonyakRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
          return switch (bundleResult) {
            RuntimeStackSourceArchiveBundleFailed(:final message) =>
              macosWineSourceManifestInstallResult(
                sourceManifest: sourceManifest,
                result: MacosWineInstallFailed(message),
              ),
            RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
              macosWineSourceManifestInstallResult(
                sourceManifest: sourceManifest,
                result: installMacosWineArchive(
                  archivePath: bundle.wineArchivePath.value,
                  archiveSha256: const Option.none(),
                  componentArchivePaths: bundle.componentArchivePaths.map(
                    (path) => path.value,
                  ),
                  componentVersions: bundle.componentVersions,
                  preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
                  progressSink: progressSink,
                ),
              ),
          };
        },
      );
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(
        'Runtime stack source manifest $sourceManifest failed: '
        '${error.message}',
      );
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(
        'Runtime stack source manifest $sourceManifest failed: '
        '${error.message}',
      );
    } finally {
      deleteDirectoryIfPresent(tempDirectory);
    }
  }

  Future<MacosWineInstallResult>
  installMacosWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      return await runtimeStackSourceManifestFromPayload(manifestPayload).match(
        () async => const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        ),
        (manifest) async {
          final bundleResult =
              await resolveRuntimeStackSourceArchiveBundleStreaming(
                manifest: manifest,
                platformSpec: macosKonyakRuntimePlatformSpec,
                tempDirectory: tempDirectory,
                progressSink: progressSink,
              );
          return switch (bundleResult) {
            RuntimeStackSourceArchiveBundleFailed(:final message) =>
              macosWineSourceManifestInstallResult(
                sourceManifest: sourceManifest,
                result: MacosWineInstallFailed(message),
              ),
            RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
              macosWineSourceManifestInstallResult(
                sourceManifest: sourceManifest,
                result: installMacosWineArchive(
                  archivePath: bundle.wineArchivePath.value,
                  archiveSha256: const Option.none(),
                  componentArchivePaths: bundle.componentArchivePaths.map(
                    (path) => path.value,
                  ),
                  componentVersions: bundle.componentVersions,
                  preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
                  progressSink: progressSink,
                ),
              ),
          };
        },
      );
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(
        'Runtime stack source manifest $sourceManifest failed: '
        '${error.message}',
      );
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(
        'Runtime stack source manifest $sourceManifest failed: '
        '${error.message}',
      );
    } finally {
      deleteDirectoryIfPresent(tempDirectory);
    }
  }

  String readRuntimeStackSourceText(
    String source, {
    required String? signatureSource,
  }) {
    return readAndVerifyRuntimeStackSourceText(
      source: source,
      signatureSource: signatureSource,
      publicKeyPath: environment
          .nonEmptyValue('KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH')
          .match(
            () => environment
                .nonEmptyValue('KONYAK_MACOS_WINE_STACK_PUBLIC_KEY_PATH')
                .match(() => null, (value) => value),
            (value) => value,
          ),
      publicKeyText: environment
          .nonEmptyValue('KONYAK_RUNTIME_STACK_PUBLIC_KEY')
          .match(
            () => environment
                .nonEmptyValue('KONYAK_MACOS_WINE_STACK_PUBLIC_KEY')
                .match(() => null, (value) => value),
            (value) => value,
          ),
    );
  }
}

String incompleteMacosWineStackSummary(RuntimeStack stack) {
  final missingComponents = stack.components
      .where((component) => component.isRequired && !component.isInstalled)
      .map((component) => component.id)
      .toList(growable: false);
  final missingPaths = stack.components
      .where((component) => component.isRequired)
      .expand((component) => component.missingPaths)
      .toList(growable: false);
  final details = <String>[
    if (missingComponents.isNotEmpty)
      'missing components: ${missingComponents.join(', ')}',
    if (missingPaths.isNotEmpty) 'missing paths: ${missingPaths.join(', ')}',
  ];

  if (details.isEmpty) {
    return 'required component state is incomplete';
  }

  return details.join('; ');
}

RuntimeComponentVersions preserveImportedGptkD3DMetalComponent({
  required Directory existingRuntimeRoot,
  required Directory stagingRuntimeRoot,
  required RuntimeComponentVersions componentVersions,
}) {
  final source = existingGptkD3DMetalSource(existingRuntimeRoot);
  if (source == null) {
    return componentVersions;
  }

  final detectedVersionResult = detectGptkD3DMetalPayloadVersion(source);
  return detectedVersionResult.match((_) => componentVersions, (
    detectedVersion,
  ) {
    final validation = validateGptkD3DMetalSource(
      source,
      detectedVersion: detectedVersion,
    );
    if (validation.isLeft()) {
      return componentVersions;
    }

    installGptkD3DMetalComponentPayload(
      source: source,
      runtimeRoot: stagingRuntimeRoot,
      detectedVersion: detectedVersion,
    );

    return componentVersions.add(
      RuntimeComponentId(gptkD3DMetalComponentId),
      RuntimeVersion(
        runtimeStackComponentVersionFromRoot(
              existingRuntimeRoot,
              gptkD3DMetalComponentId,
            ) ??
            'user-provided',
      ),
    );
  });
}

GptkD3DMetalSource? existingGptkD3DMetalSource(Directory runtimeRoot) {
  return resolveGptkD3DMetalSource(
    joinPath(runtimeRoot.path, gptkD3DMetalComponentRelativePath),
  );
}

String? runtimeStackComponentVersionFromRoot(
  Directory runtimeRoot,
  String componentId,
) {
  final manifest = File(
    joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return null;
  }

  try {
    return runtimeStackComponentVersion(
      jsonDecode(manifest.readAsStringSync()),
      componentId,
    );
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

MacosWineInstallResult macosWineSourceManifestInstallResult({
  required String sourceManifest,
  required MacosWineInstallResult result,
}) {
  return switch (result) {
    MacosWineInstallCompleted() => result,
    MacosWineInstallFailed(:final message) => MacosWineInstallFailed(
      'Runtime stack source manifest $sourceManifest failed: $message',
    ),
  };
}
