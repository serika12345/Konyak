part of '../../konyak_cli.dart';

extension _MacosWineArchiveInstallation on DartIoMacosWineInstaller {
  MacosWineInstallResult _installMacosWineArchive({
    required String archivePath,
    required Option<String> archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    RuntimeComponentVersions componentVersions =
        const RuntimeComponentVersions.empty(),
    bool preserveExistingRuntimeFiles = false,
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = _runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'macOS Wine',
        archivePath: archivePath,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory(_macosWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            _macosKonyakRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: _macosWineExecutable(environment),
        preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
        preserveExistingRuntimeSkipRelativePaths:
            _legacyGptkD3DMetalRuntimeRelativePaths,
        preserveExistingRuntimeComponents:
            _preserveImportedGptkD3DMetalComponent,
        normalizeStagingRoot:
            _macosKonyakRuntimePlatformSpec.layoutNormalization ==
                _RuntimeLayoutNormalization.macosWineBundle
            ? _normalizeMacosWineRuntimeLayout
            : null,
        afterManifestWrite:
            _macosKonyakRuntimePlatformSpec.layoutNormalization ==
                _RuntimeLayoutNormalization.macosWineBundle
            ? _ensureMacosWine64Alias
            : null,
        progressSink: progressSink,
      ),
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return MacosWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );

    if (runtime.isInstalled.toNullable() != true) {
      return MacosWineInstallFailed(
        'macOS Wine archive did not install '
        '`${runtime.executablePath.toNullable()}`.',
      );
    }
    final stack = runtime.stack.toNullable();
    if (stack == null || !stack.isComplete) {
      return MacosWineInstallFailed(
        'macOS Wine archive installed but runtime stack is incomplete: '
        '${_incompleteMacosWineStackSummary(stack)}.',
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak macOS Wine.',
      fraction: 1,
    );

    return MacosWineInstallCompleted(runtime: runtime);
  }

  MacosWineInstallResult _installMacosWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest.isNone()) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest.getOrElse(
          () => throw StateError('Expected runtime stack source manifest.'),
        ),
        platformSpec: _macosKonyakRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          _macosWineSourceManifestInstallResult(
            sourceManifest: sourceManifest,
            result: MacosWineInstallFailed(message),
          ),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _macosWineSourceManifestInstallResult(
            sourceManifest: sourceManifest,
            result: _installMacosWineArchive(
              archivePath: bundle.wineArchivePath,
              archiveSha256: const Option.none(),
              componentArchivePaths: bundle.componentArchivePaths,
              componentVersions: bundle.componentVersions,
              preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
              progressSink: progressSink,
            ),
          ),
      };
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
      _deleteDirectoryIfPresent(tempDirectory);
    }
  }

  Future<MacosWineInstallResult>
  _installMacosWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest.isNone()) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest.getOrElse(
              () => throw StateError('Expected runtime stack source manifest.'),
            ),
            platformSpec: _macosKonyakRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          _macosWineSourceManifestInstallResult(
            sourceManifest: sourceManifest,
            result: MacosWineInstallFailed(message),
          ),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _macosWineSourceManifestInstallResult(
            sourceManifest: sourceManifest,
            result: _installMacosWineArchive(
              archivePath: bundle.wineArchivePath,
              archiveSha256: const Option.none(),
              componentArchivePaths: bundle.componentArchivePaths,
              componentVersions: bundle.componentVersions,
              preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
              progressSink: progressSink,
            ),
          ),
      };
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
      _deleteDirectoryIfPresent(tempDirectory);
    }
  }

  String _readRuntimeStackSourceText(
    String source, {
    required String? signatureSource,
  }) {
    return _readAndVerifyRuntimeStackSourceText(
      source: source,
      signatureSource: signatureSource,
      publicKeyPath:
          environment.nonEmptyValue('KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH') ??
          environment.nonEmptyValue('KONYAK_MACOS_WINE_STACK_PUBLIC_KEY_PATH'),
      publicKeyText:
          environment.nonEmptyValue('KONYAK_RUNTIME_STACK_PUBLIC_KEY') ??
          environment.nonEmptyValue('KONYAK_MACOS_WINE_STACK_PUBLIC_KEY'),
    );
  }
}

String _incompleteMacosWineStackSummary(RuntimeStack? stack) {
  if (stack == null) {
    return 'runtime stack metadata is missing';
  }

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

void _preserveImportedGptkD3DMetalComponent({
  required Directory existingRuntimeRoot,
  required Directory stagingRuntimeRoot,
  required Map<String, String> componentVersions,
}) {
  final source = _existingGptkD3DMetalSource(existingRuntimeRoot);
  if (source == null || _validateGptkD3DMetalSource(source) != null) {
    return;
  }

  _installGptkD3DMetalComponentPayload(
    source: source,
    runtimeRoot: stagingRuntimeRoot,
  );

  componentVersions[_gptkD3DMetalComponentId] =
      _runtimeStackComponentVersionFromRoot(
        existingRuntimeRoot,
        _gptkD3DMetalComponentId,
      ) ??
      'user-provided';
}

_GptkD3DMetalSource? _existingGptkD3DMetalSource(Directory runtimeRoot) {
  final componentSource = _resolveGptkD3DMetalSource(
    _joinPath(runtimeRoot.path, _gptkD3DMetalComponentRelativePath),
  );
  if (componentSource != null) {
    return componentSource;
  }

  return _resolveGptkD3DMetalSource(runtimeRoot.path);
}

String? _runtimeStackComponentVersionFromRoot(
  Directory runtimeRoot,
  String componentId,
) {
  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return null;
  }

  try {
    return _runtimeStackComponentVersion(
      jsonDecode(manifest.readAsStringSync()),
      componentId,
    );
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

MacosWineInstallResult _macosWineSourceManifestInstallResult({
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
