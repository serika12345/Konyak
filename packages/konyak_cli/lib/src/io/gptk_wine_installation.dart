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
    return DartIoGptkWineInstaller(
      environment: HostEnvironment(Platform.environment),
    );
  }

  final HostEnvironment environment;

  @override
  GptkWineInstallResult install(GptkWineInstallRequest request) {
    final sourcePath = request.sourcePath.trim();
    if (sourcePath.isEmpty) {
      return const GptkWineInstallFailed('GPTK Wine source path is empty.');
    }

    final runtimeRoot = Directory(_macosWineRuntimeRoot(environment));
    if (!File(_macosWineExecutable(environment)).existsSync()) {
      return const GptkWineInstallFailed(
        'Install Konyak macOS Wine before importing GPTK/D3DMetal.',
      );
    }

    final sourceResolution = _resolveGptkD3DMetalSourcePath(sourcePath);
    if (sourceResolution == null) {
      return const GptkWineInstallFailed(
        'Select an Apple Game Porting Toolkit DMG, app bundle, or extracted '
        'redist payload that contains D3DMetal.framework, libd3dshared.dylib, '
        'and the matching Wine D3DMetal DLL/SO files.',
      );
    }

    final backupRoot = Directory('${runtimeRoot.path}.backup');
    final lockFile = File(_runtimeInstallLockPath(runtimeRoot));
    var lockCreated = false;
    var backupCreated = false;
    late _GptkD3DMetalSource installedD3DMetal;

    try {
      try {
        lockFile.createSync(exclusive: true);
        lockCreated = true;
      } on FileSystemException {
        return const GptkWineInstallFailed(
          'Konyak macOS Wine installation is already running.',
        );
      }

      final bundledD3DMetal = sourceResolution.source;
      final d3dMetalValidationFailure = _validateGptkD3DMetalSource(
        bundledD3DMetal,
      );
      if (d3dMetalValidationFailure != null) {
        return GptkWineInstallFailed(d3dMetalValidationFailure);
      }
      installedD3DMetal = bundledD3DMetal;

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
      _installGptkD3DMetalComponent(
        source: bundledD3DMetal,
        runtimeRoot: runtimeRoot,
      );
      _upsertRuntimeStackComponentVersion(
        runtimeRoot: runtimeRoot,
        componentId: _gptkD3DMetalComponentId,
        version: 'user-provided',
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
      sourceResolution.dispose();
      if (backupRoot.existsSync()) {
        backupRoot.deleteSync(recursive: true);
      }
      if (lockCreated && lockFile.existsSync()) {
        lockFile.deleteSync();
      }
    }

    return GptkWineInstallCompleted(
      GptkWineInstallRecord(
        componentId: _gptkD3DMetalComponentId,
        sourceDirectory: installedD3DMetal.payloadRoot.path,
        runtimeRoot: runtimeRoot.path,
        installedExecutablePath: _macosWineExecutable(environment),
      ),
    );
  }

  void _installGptkD3DMetalComponent({
    required _GptkD3DMetalSource source,
    required Directory runtimeRoot,
  }) {
    final externalRoot = Directory(
      _joinPath(runtimeRoot.path, const ['lib', 'external']),
    )..createSync(recursive: true);
    _copyDirectoryReplacing(
      source: source.framework,
      destination: Directory(
        _joinPath(externalRoot.path, const ['D3DMetal.framework']),
      ),
    );
    _copyFileReplacing(
      source: source.dylib,
      destination: File(
        _joinPath(externalRoot.path, const ['libd3dshared.dylib']),
      ),
    );

    final windowsDllRoot = Directory(
      _joinPath(runtimeRoot.path, const ['lib', 'wine', 'x86_64-windows']),
    )..createSync(recursive: true);
    for (final fileName in _requiredGptkD3DMetalWindowsFileNames) {
      final sourcePath = _gptkD3DMetalWindowsPayloadPath(
        source.windowsDllRoot,
        fileName,
      );
      if (sourcePath == null) {
        throw FileSystemException(
          'GPTK/D3DMetal Windows DLL was not found.',
          _joinPath(source.windowsDllRoot.path, [fileName]),
        );
      }
      _copyFileReplacing(
        source: File(sourcePath),
        destination: File(_joinPath(windowsDllRoot.path, [fileName])),
      );
    }

    final unixLibraryRoot = Directory(
      _joinPath(runtimeRoot.path, const ['lib', 'wine', 'x86_64-unix']),
    )..createSync(recursive: true);
    for (final fileName in _requiredGptkD3DMetalUnixFileNames) {
      final sourcePath = _gptkD3DMetalUnixPayloadPath(
        source.unixLibraryRoot,
        fileName,
      );
      if (sourcePath == null) {
        throw FileSystemException(
          'GPTK/D3DMetal Unix library was not found.',
          _joinPath(source.unixLibraryRoot.path, [fileName]),
        );
      }
      _copyFileSystemEntityReplacing(
        sourcePath: sourcePath,
        destinationPath: _joinPath(unixLibraryRoot.path, [fileName]),
      );
    }
  }

  void _copyDirectoryReplacing({
    required Directory source,
    required Directory destination,
  }) {
    if (destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
    _copyDirectory(source: source, destination: destination);
  }

  void _copyFileReplacing({required File source, required File destination}) {
    destination.parent.createSync(recursive: true);
    final destinationType = FileSystemEntity.typeSync(
      destination.path,
      followLinks: false,
    );
    if (destinationType != FileSystemEntityType.notFound) {
      _deleteFileSystemEntitySync(destination.path, destinationType);
    }
    source.copySync(destination.path);
  }

  void _copyFileSystemEntityReplacing({
    required String sourcePath,
    required String destinationPath,
  }) {
    Directory(_dirname(destinationPath)).createSync(recursive: true);
    final destinationType = FileSystemEntity.typeSync(
      destinationPath,
      followLinks: false,
    );
    if (destinationType != FileSystemEntityType.notFound) {
      _deleteFileSystemEntitySync(destinationPath, destinationType);
    }

    final sourceType = FileSystemEntity.typeSync(
      sourcePath,
      followLinks: false,
    );
    switch (sourceType) {
      case FileSystemEntityType.file:
        File(sourcePath).copySync(destinationPath);
      case FileSystemEntityType.link:
        Link(destinationPath).createSync(Link(sourcePath).targetSync());
      case FileSystemEntityType.directory:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
      case FileSystemEntityType.notFound:
        throw FileSystemException(
          'Unsupported GPTK/D3DMetal payload path.',
          sourcePath,
        );
    }
  }
}

class _GptkD3DMetalSource {
  const _GptkD3DMetalSource({
    required this.payloadRoot,
    required this.externalRoot,
    required this.windowsDllRoot,
    required this.unixLibraryRoot,
    required this.framework,
    required this.dylib,
    required this.d3d11Dll,
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final Directory payloadRoot;
  final Directory externalRoot;
  final Directory windowsDllRoot;
  final Directory unixLibraryRoot;
  final Directory framework;
  final File dylib;
  final File d3d11Dll;
  final File d3d12Dll;
  final File dxgiDll;
}

const _gptkD3DMetalComponentId = 'gptk-d3dmetal';
