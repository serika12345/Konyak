part of '../konyak_cli.dart';

enum RuntimeInstallOperation {
  fullInstall,
  repair,
  componentInstall,
  updateInstall,
}

sealed class RuntimeInstallRequestOperation {
  const RuntimeInstallRequestOperation();

  RuntimeInstallOperation get operation;

  bool get force;

  String? get archivePath => null;

  String? get archiveUrl => null;

  String? get archiveSha256 => null;

  List<String> get componentArchivePaths => const <String>[];

  String? get sourceManifest => null;

  String? get sourceManifestSignature => null;
}

final class RuntimeFullInstallOperation extends RuntimeInstallRequestOperation {
  const RuntimeFullInstallOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = false,
  });

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.fullInstall;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeRepairOperation extends RuntimeInstallRequestOperation {
  const RuntimeRepairOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = true,
  });

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.repair;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeComponentInstallOperation
    extends RuntimeInstallRequestOperation {
  RuntimeComponentInstallOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    this.force = false,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths);

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.componentInstall;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final List<String> componentArchivePaths;

  @override
  final bool force;
}

final class RuntimeUpdateInstallOperation
    extends RuntimeInstallRequestOperation {
  const RuntimeUpdateInstallOperation({
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = true,
  });

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.updateInstall;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

class MacosWineInstallRequest {
  MacosWineInstallRequest.fullInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeFullInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  MacosWineInstallRequest.repair({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeRepairOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  MacosWineInstallRequest.componentInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeComponentInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         componentArchivePaths: componentArchivePaths,
         force: force,
       );

  MacosWineInstallRequest.updateInstall({
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeUpdateInstallOperation(
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  final RuntimeInstallRequestOperation requestOperation;
  final bool emitProgress;

  RuntimeInstallOperation get operation => requestOperation.operation;

  String? get archivePath => requestOperation.archivePath;

  String? get archiveUrl => requestOperation.archiveUrl;

  String? get archiveSha256 => requestOperation.archiveSha256;

  List<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  String? get sourceManifest => requestOperation.sourceManifest;

  String? get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

class LinuxWineInstallRequest {
  LinuxWineInstallRequest.fullInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeFullInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  LinuxWineInstallRequest.repair({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeRepairOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  LinuxWineInstallRequest.componentInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeComponentInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         componentArchivePaths: componentArchivePaths,
         force: force,
       );

  LinuxWineInstallRequest.updateInstall({
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeUpdateInstallOperation(
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  final RuntimeInstallRequestOperation requestOperation;
  final bool emitProgress;

  RuntimeInstallOperation get operation => requestOperation.operation;

  String? get archivePath => requestOperation.archivePath;

  String? get archiveUrl => requestOperation.archiveUrl;

  String? get archiveSha256 => requestOperation.archiveSha256;

  List<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  String? get sourceManifest => requestOperation.sourceManifest;

  String? get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

class RuntimePackageInstallRequest {
  const RuntimePackageInstallRequest({
    required this.runtimeLabel,
    required this.archivePath,
    required this.archiveSha256,
    required this.componentArchivePaths,
    required this.componentVersions,
    required this.runtimeRoot,
    required this.requiredExecutableRelativePath,
    required this.expectedExecutablePath,
    this.preserveExistingRuntimeFiles = false,
    this.normalizeStagingRoot,
    this.afterManifestWrite,
    this.progressSink,
  });

  final String runtimeLabel;
  final String archivePath;
  final String? archiveSha256;
  final List<String> componentArchivePaths;
  final Map<String, String> componentVersions;
  final Directory runtimeRoot;
  final List<String> requiredExecutableRelativePath;
  final String expectedExecutablePath;
  final bool preserveExistingRuntimeFiles;
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
      archiveSha256: request.archiveSha256,
      componentArchivePaths: request.componentArchivePaths,
      componentVersions: request.componentVersions,
      runtimeRoot: request.runtimeRoot,
      requiredExecutableRelativePath: request.requiredExecutableRelativePath,
      expectedExecutablePath: request.expectedExecutablePath,
      preserveExistingRuntimeFiles: request.preserveExistingRuntimeFiles,
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

sealed class MacosWineInstallResult {
  const MacosWineInstallResult();
}

class MacosWineInstallCompleted extends MacosWineInstallResult {
  const MacosWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class MacosWineInstallFailed extends MacosWineInstallResult {
  const MacosWineInstallFailed(this.message);

  final String message;
}

abstract interface class MacosWineInstaller {
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}

class GptkWineInstallRequest {
  const GptkWineInstallRequest({required this.sourcePath});

  final String sourcePath;
}

class GptkWineInstallRecord {
  const GptkWineInstallRecord({
    required this.componentId,
    required this.sourceDirectory,
    required this.runtimeRoot,
    required this.installedExecutablePath,
  });

  final String componentId;
  final String sourceDirectory;
  final String runtimeRoot;
  final String installedExecutablePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'componentId': componentId,
      'sourceDirectory': sourceDirectory,
      'runtimeRoot': runtimeRoot,
      'installedExecutablePath': installedExecutablePath,
    };
  }
}

sealed class GptkWineInstallResult {
  const GptkWineInstallResult();
}

class GptkWineInstallCompleted extends GptkWineInstallResult {
  const GptkWineInstallCompleted(this.record);

  final GptkWineInstallRecord record;
}

class GptkWineInstallFailed extends GptkWineInstallResult {
  const GptkWineInstallFailed(this.message);

  final String message;
}

abstract interface class GptkWineInstaller {
  GptkWineInstallResult install(GptkWineInstallRequest request);
}

sealed class LinuxWineInstallResult {
  const LinuxWineInstallResult();
}

class LinuxWineInstallCompleted extends LinuxWineInstallResult {
  const LinuxWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class LinuxWineInstallFailed extends LinuxWineInstallResult {
  const LinuxWineInstallFailed(this.message);

  final String message;
}

abstract interface class LinuxWineInstaller {
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}

class DartIoGptkWineInstaller implements GptkWineInstaller {
  const DartIoGptkWineInstaller({required this.environment});

  factory DartIoGptkWineInstaller.current() {
    return DartIoGptkWineInstaller(environment: Platform.environment);
  }

  static const componentId = 'wine';
  static const componentVersion = 'user-provided-gptk-wine';

  final Map<String, String> environment;

  @override
  GptkWineInstallResult install(GptkWineInstallRequest request) {
    final sourcePath = request.sourcePath.trim();
    if (sourcePath.isEmpty) {
      return const GptkWineInstallFailed('GPTK Wine source path is empty.');
    }

    final sourceRoot = _resolveGptkWineRoot(sourcePath);
    if (sourceRoot == null) {
      return const GptkWineInstallFailed(
        'Select a Game Porting Toolkit.app bundle that contains '
        'Contents/Resources/wine.',
      );
    }

    final validationFailure = _validateGptkWineRoot(sourceRoot);
    if (validationFailure != null) {
      return GptkWineInstallFailed(validationFailure);
    }

    final runtimeRoot = Directory(_macosWineRuntimeRoot(environment));
    final backupRoot = Directory('${runtimeRoot.path}.backup');
    final lockFile = File(_runtimeInstallLockPath(runtimeRoot));
    var lockCreated = false;
    var backupCreated = false;

    try {
      try {
        lockFile.createSync(exclusive: true);
        lockCreated = true;
      } on FileSystemException {
        return const GptkWineInstallFailed(
          'Konyak macOS Wine installation is already running.',
        );
      }

      final bundledD3DMetal = _resolveGptkD3DMetalSource(sourceRoot.path);
      if (bundledD3DMetal == null) {
        return const GptkWineInstallFailed(
          'Selected GPTK app does not contain D3DMetal.framework, '
          'libd3dshared.dylib, d3d12.dll, and dxgi.dll.',
        );
      }
      final d3dMetalValidationFailure = _validateGptkD3DMetalSource(
        bundledD3DMetal,
      );
      if (d3dMetalValidationFailure != null) {
        return GptkWineInstallFailed(d3dMetalValidationFailure);
      }

      runtimeRoot.parent.createSync(recursive: true);
      if (backupRoot.existsSync()) {
        backupRoot.deleteSync(recursive: true);
      }
      if (runtimeRoot.existsSync()) {
        runtimeRoot.renameSync(backupRoot.path);
        backupCreated = true;
        _copyDirectoryContentsReplacing(
          source: backupRoot,
          destination: runtimeRoot,
        );
      }
      _copyDirectoryContentsReplacing(
        source: sourceRoot,
        destination: runtimeRoot,
        skipRelativePaths: const <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      );
      _upsertRuntimeStackComponentVersion(
        runtimeRoot: runtimeRoot,
        componentId: _gptkD3DMetalComponentId,
        version: 'user-provided',
      );
      _upsertRuntimeStackComponentVersion(
        runtimeRoot: runtimeRoot,
        componentId: componentId,
        version: componentVersion,
      );
    } on FileSystemException catch (error) {
      if (backupCreated) {
        if (runtimeRoot.existsSync()) {
          runtimeRoot.deleteSync(recursive: true);
        }
        if (backupRoot.existsSync()) {
          backupRoot.renameSync(runtimeRoot.path);
        }
      }
      return GptkWineInstallFailed(error.message);
    } finally {
      if (backupRoot.existsSync()) {
        backupRoot.deleteSync(recursive: true);
      }
      if (lockCreated && lockFile.existsSync()) {
        lockFile.deleteSync();
      }
    }

    return GptkWineInstallCompleted(
      GptkWineInstallRecord(
        componentId: componentId,
        sourceDirectory: sourceRoot.path,
        runtimeRoot: runtimeRoot.path,
        installedExecutablePath: _macosWineExecutable(environment),
      ),
    );
  }
}

class _GptkD3DMetalSource {
  const _GptkD3DMetalSource({
    required this.directory,
    required this.framework,
    required this.dylib,
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final Directory directory;
  final Directory framework;
  final File dylib;
  final File d3d12Dll;
  final File dxgiDll;
}

const _gptkD3DMetalComponentId = 'gptk-d3dmetal';

class DartIoMacosWineInstaller implements MacosWineInstaller {
  DartIoMacosWineInstaller({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller runtimePackageInstaller =
        const DartIoRuntimePackageInstaller(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller = runtimePackageInstaller;

  factory DartIoMacosWineInstaller.current() {
    return DartIoMacosWineInstaller(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;
  final RuntimePackageInstaller _runtimePackageInstaller;

  @override
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.macos) {
      return const MacosWineInstallFailed(
        'macOS Wine installation is supported on macOS only.',
      );
    }

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final hasExplicitInstallSource =
        request.archivePath != null ||
        request.archiveUrl != null ||
        componentArchivePaths.isNotEmpty ||
        request.sourceManifest != null;
    final shouldPreserveExistingRuntimeFiles =
        !request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource;
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak macOS Wine is already installed.',
        fraction: 1,
      );
      return MacosWineInstallCompleted(runtime: currentRuntime);
    }
    if (!request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource &&
        sourceManifest == null) {
      return const MacosWineInstallFailed(
        'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
        'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
        'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
        '--component-archive to repair it.',
      );
    }

    if (sourceManifest != null) {
      return _installMacosWineStackFromSourceManifest(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final archive = request.archivePath;
    if (archive != null) {
      return _installMacosWineArchive(
        archivePath: archive,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-',
    );
    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        )!;
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = _downloadRuntimeStackSourceArchive(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak macOS Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return MacosWineInstallFailed(downloadFailure);
      }

      return _installMacosWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<MacosWineInstallResult> installStreaming(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.macos) {
      return const MacosWineInstallFailed(
        'macOS Wine installation is supported on macOS only.',
      );
    }

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final hasExplicitInstallSource =
        request.archivePath != null ||
        request.archiveUrl != null ||
        componentArchivePaths.isNotEmpty ||
        request.sourceManifest != null;
    final shouldPreserveExistingRuntimeFiles =
        !request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource;
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak macOS Wine is already installed.',
        fraction: 1,
      );
      return MacosWineInstallCompleted(runtime: currentRuntime);
    }
    if (!request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource &&
        sourceManifest == null) {
      return const MacosWineInstallFailed(
        'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
        'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
        'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
        '--component-archive to repair it.',
      );
    }

    if (sourceManifest != null) {
      return _installMacosWineStackFromSourceManifestStreaming(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final archive = request.archivePath;
    if (archive != null) {
      return _installMacosWineArchive(
        archivePath: archive,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-',
    );
    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        )!;
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak macOS Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return MacosWineInstallFailed(downloadFailure);
      }

      return _installMacosWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  MacosWineInstallResult _installMacosWineArchive({
    required String archivePath,
    required String? archiveSha256,
    List<String> componentArchivePaths = const <String>[],
    Map<String, String> componentVersions = const <String, String>{},
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

    if (runtime.isInstalled != true) {
      return MacosWineInstallFailed(
        'macOS Wine archive did not install `${runtime.executablePath}`.',
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
      if (manifest == null) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest,
        platformSpec: _macosKonyakRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          MacosWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installMacosWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
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
      if (manifest == null) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest,
            platformSpec: _macosKonyakRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          MacosWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installMacosWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
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
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_MACOS_WINE_STACK_PUBLIC_KEY_PATH',
          ),
      publicKeyText:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_MACOS_WINE_STACK_PUBLIC_KEY',
          ),
    );
  }

  void _normalizeMacosWineRuntimeLayout(Directory runtimeRoot) {
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(_joinPath(runtimeRoot.path, const ['Wine'])),
    );
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(
        _joinPath(runtimeRoot.path, const ['Contents', 'Resources', 'wine']),
      ),
    );
    for (final entry in runtimeRoot.listSync()) {
      if (entry is! Directory || !_basename(entry.path).endsWith('.app')) {
        continue;
      }
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(
          _joinPath(entry.path, const ['Contents', 'Resources', 'wine']),
        ),
      );
      if (entry.existsSync()) {
        entry.deleteSync(recursive: true);
      }
    }
    _normalizeMacosRuntimeComponents(runtimeRoot);
  }

  void _normalizeMacosRuntimeComponents(Directory runtimeRoot) {
    final componentsRoot = Directory(
      _joinPath(runtimeRoot.path, const ['Components']),
    );
    if (!componentsRoot.existsSync()) {
      return;
    }

    for (final componentId in const <String>[
      'DXVK-macOS',
      'DXVK',
      'MoltenVK',
      'GStreamer',
      'wine-mono',
      'winetricks',
      'GPTK-D3DMetal',
      'gptk-d3dmetal',
      'D3DMetal',
    ]) {
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(_joinPath(componentsRoot.path, [componentId])),
      );
    }

    if (componentsRoot.existsSync() && componentsRoot.listSync().isEmpty) {
      componentsRoot.deleteSync(recursive: true);
    }
  }

  void _moveRuntimeLayoutChildrenToRoot({
    required Directory runtimeRoot,
    required Directory sourceRoot,
  }) {
    if (!sourceRoot.existsSync()) {
      return;
    }

    for (final entry in sourceRoot.listSync()) {
      final targetPath = _joinPath(runtimeRoot.path, [_basename(entry.path)]);
      _moveFileSystemEntity(entry, targetPath);
    }

    sourceRoot.deleteSync(recursive: true);
  }

  void _moveFileSystemEntity(FileSystemEntity entry, String targetPath) {
    final sourceType = FileSystemEntity.typeSync(entry.path);
    final targetType = FileSystemEntity.typeSync(targetPath);
    if (sourceType == FileSystemEntityType.directory &&
        targetType == FileSystemEntityType.directory) {
      for (final child in Directory(entry.path).listSync()) {
        _moveFileSystemEntity(
          child,
          _joinPath(targetPath, [_basename(child.path)]),
        );
      }
      Directory(entry.path).deleteSync();
      return;
    }

    if (targetType != FileSystemEntityType.notFound) {
      _deleteFileSystemEntity(targetPath, targetType);
    }
    entry.renameSync(targetPath);
  }

  void _ensureMacosWine64Alias(Directory runtimeRoot) {
    final binPath = _joinPath(runtimeRoot.path, const ['bin']);
    final winePath = _joinPath(binPath, const ['wine']);
    final wine64Path = _joinPath(binPath, const ['wine64']);

    if (FileSystemEntity.typeSync(wine64Path) !=
        FileSystemEntityType.notFound) {
      return;
    }
    if (FileSystemEntity.typeSync(winePath) == FileSystemEntityType.notFound) {
      return;
    }

    Link(wine64Path).createSync('wine');
  }

  void _deleteFileSystemEntity(String path, FileSystemEntityType type) {
    switch (type) {
      case FileSystemEntityType.directory:
        Directory(path).deleteSync(recursive: true);
      case FileSystemEntityType.file:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        File(path).deleteSync();
      case FileSystemEntityType.notFound:
        break;
    }
  }
}

class DartIoLinuxWineInstaller implements LinuxWineInstaller {
  DartIoLinuxWineInstaller({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller runtimePackageInstaller =
        const DartIoRuntimePackageInstaller(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller = runtimePackageInstaller;

  factory DartIoLinuxWineInstaller.current() {
    return DartIoLinuxWineInstaller(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;
  final RuntimePackageInstaller _runtimePackageInstaller;

  @override
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.linux) {
      return const LinuxWineInstallFailed(
        'Linux Wine installation is supported on Linux only.',
      );
    }

    final currentRuntime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak Linux Wine is already installed.',
        fraction: 1,
      );
      return LinuxWineInstallCompleted(runtime: currentRuntime);
    }

    if (sourceManifest != null) {
      return _installLinuxWineStackFromSourceManifest(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        progressSink: progress,
      );
    }

    final archivePath = request.archivePath;
    if (archivePath != null) {
      return _installLinuxWineArchive(
        archivePath: archivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    }

    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (archiveUrl == null) {
      return const LinuxWineInstallFailed(
        'Linux Wine archive is not configured.',
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-',
    );
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = _downloadRuntimeStackSourceArchive(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak Linux Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return LinuxWineInstallFailed(downloadFailure);
      }

      return _installLinuxWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<LinuxWineInstallResult> installStreaming(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.linux) {
      return const LinuxWineInstallFailed(
        'Linux Wine installation is supported on Linux only.',
      );
    }

    final currentRuntime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak Linux Wine is already installed.',
        fraction: 1,
      );
      return LinuxWineInstallCompleted(runtime: currentRuntime);
    }

    if (sourceManifest != null) {
      return _installLinuxWineStackFromSourceManifestStreaming(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        progressSink: progress,
      );
    }

    final archivePath = request.archivePath;
    if (archivePath != null) {
      return _installLinuxWineArchive(
        archivePath: archivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    }

    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (archiveUrl == null) {
      return const LinuxWineInstallFailed(
        'Linux Wine archive is not configured.',
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-',
    );
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak Linux Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return LinuxWineInstallFailed(downloadFailure);
      }

      return _installLinuxWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  LinuxWineInstallResult _installLinuxWineArchive({
    required String archivePath,
    required String? archiveSha256,
    List<String> componentArchivePaths = const <String>[],
    Map<String, String> componentVersions = const <String, String>{},
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = _runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'Linux Wine',
        archivePath: archivePath,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory(_linuxWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            _linuxWineRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: _linuxWineExecutable(environment),
        progressSink: progressSink,
      ),
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    if (runtime.isInstalled != true) {
      return LinuxWineInstallFailed(
        'Linux Wine archive did not install `${runtime.executablePath}`.',
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak Linux Wine.',
      fraction: 1,
    );

    return LinuxWineInstallCompleted(runtime: runtime);
  }

  LinuxWineInstallResult _installLinuxWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest,
        platformSpec: _linuxWineRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          LinuxWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installLinuxWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<LinuxWineInstallResult>
  _installLinuxWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest,
            platformSpec: _linuxWineRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          LinuxWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installLinuxWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
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
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH',
          ),
      publicKeyText:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_LINUX_WINE_STACK_PUBLIC_KEY',
          ),
    );
  }
}
