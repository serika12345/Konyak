part of '../../konyak_cli.dart';

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

    final hostEnvironment = HostEnvironment(environment);
    final runtimeRoot = Directory(_macosWineRuntimeRoot(hostEnvironment));
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
        installedExecutablePath: _macosWineExecutable(hostEnvironment),
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
