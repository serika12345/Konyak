import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/host_environment.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../platform/platform_terminal_commands.dart';
import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';
import 'runtime_archive_install_support.dart';
import 'runtime_gptk_support.dart';
import 'runtime_stack_manifest_io.dart';

enum GptkWineImportVersion { auto, gptk3, gptk4 }

class GptkWineInstallRequest {
  const GptkWineInstallRequest({
    required this.sourcePath,
    this.requestedVersion = GptkWineImportVersion.auto,
  });

  final String sourcePath;
  final GptkWineImportVersion requestedVersion;
}

class GptkWineInstallRecord {
  const GptkWineInstallRecord({
    required this.componentId,
    required this.detectedVersion,
    required this.sourceDirectory,
    required this.runtimeRoot,
    required this.installedExecutablePath,
  });

  final String componentId;
  final GptkWineImportVersion detectedVersion;
  final String sourceDirectory;
  final String runtimeRoot;
  final String installedExecutablePath;
}

sealed class GptkWineInstallResult {
  const GptkWineInstallResult();
}

class GptkWineInstallCompleted extends GptkWineInstallResult {
  const GptkWineInstallCompleted(this.record);

  final GptkWineInstallRecord record;
}

class GptkWineInstallFailed extends GptkWineInstallResult {
  const GptkWineInstallFailed(
    this.message, {
    this.code = 'gptkWineInstallFailed',
    this.extra = const <String, Object?>{},
  });

  final String message;
  final String code;
  final Map<String, Object?> extra;
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

    final runtimeRoot = Directory(macosWineRuntimeRoot(environment));
    if (!File(macosWineExecutable(environment)).existsSync()) {
      return const GptkWineInstallFailed(
        'Install Konyak macOS Wine before importing GPTK/D3DMetal.',
      );
    }

    final sourceResolution = resolveGptkD3DMetalSourcePath(sourcePath);
    if (sourceResolution == null) {
      return const GptkWineInstallFailed(
        'Select an Apple Game Porting Toolkit DMG, app bundle, or extracted '
        'redist payload that contains D3DMetal.framework, libd3dshared.dylib, '
        'and the matching Wine D3DMetal DLL/SO files.',
      );
    }

    final backupRoot = Directory('${runtimeRoot.path}.backup');
    final lockFile = File(runtimeInstallLockPath(runtimeRoot));
    var lockCreated = false;
    var backupCreated = false;
    late GptkD3DMetalSource installedD3DMetal;
    late GptkWineImportVersion installedD3DMetalVersion;

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
      late final GptkWineImportVersion detectedVersion;
      switch (detectGptkD3DMetalPayloadVersion(bundledD3DMetal)) {
        case Left<String, GptkWineImportVersion>(:final value):
          return GptkWineInstallFailed(
            value,
            code: 'gptkWineVersionDetectionFailed',
          );
        case Right<String, GptkWineImportVersion>(:final value):
          detectedVersion = value;
      }
      final versionMismatchFailure = _gptkWineVersionMismatchFailureOption(
        requestedVersion: request.requestedVersion,
        detectedVersion: detectedVersion,
      );
      if (versionMismatchFailure != null) {
        return versionMismatchFailure;
      }
      switch (validateGptkD3DMetalSource(
        bundledD3DMetal,
        detectedVersion: detectedVersion,
      )) {
        case Left<String, Unit>(:final value):
          return GptkWineInstallFailed(value);
        case Right<String, Unit>():
          break;
      }
      installedD3DMetal = bundledD3DMetal;
      installedD3DMetalVersion = detectedVersion;

      runtimeRoot.parent.createSync(recursive: true);
      if (backupRoot.existsSync()) {
        backupRoot.deleteSync(recursive: true);
      }
      if (runtimeRoot.existsSync()) {
        runtimeRoot.renameSync(backupRoot.path);
        backupCreated = true;
        copyDirectoryContentsReplacing(
          source: backupRoot,
          destination: runtimeRoot,
        );
      }
      installGptkD3DMetalComponentPayload(
        source: bundledD3DMetal,
        runtimeRoot: runtimeRoot,
        detectedVersion: detectedVersion,
      );
      upsertRuntimeStackComponentVersion(
        runtimeRoot: runtimeRoot,
        componentId: gptkD3DMetalComponentId,
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
        componentId: gptkD3DMetalComponentId,
        detectedVersion: installedD3DMetalVersion,
        sourceDirectory: installedD3DMetal.payloadRoot.path,
        runtimeRoot: runtimeRoot.path,
        installedExecutablePath: macosWineExecutable(environment),
      ),
    );
  }
}

GptkWineInstallFailed? _gptkWineVersionMismatchFailureOption({
  required GptkWineImportVersion requestedVersion,
  required GptkWineImportVersion detectedVersion,
}) {
  if (requestedVersion == GptkWineImportVersion.auto ||
      requestedVersion == detectedVersion) {
    return null;
  }

  final requestedValue = gptkWineImportVersionCliValue(requestedVersion);
  final detectedValue = gptkWineImportVersionCliValue(detectedVersion);

  return GptkWineInstallFailed(
    'Requested GPTK $requestedValue, but selected GPTK/D3DMetal payload is '
    'GPTK $detectedValue.',
    code: 'gptkWineVersionMismatch',
    extra: <String, Object?>{
      'requestedVersion': requestedValue,
      'detectedVersion': detectedValue,
    },
  );
}

String gptkWineImportVersionCliValue(GptkWineImportVersion version) {
  return switch (version) {
    GptkWineImportVersion.auto => 'auto',
    GptkWineImportVersion.gptk3 => '3',
    GptkWineImportVersion.gptk4 => '4',
  };
}

void copyDirectoryReplacing({
  required Directory source,
  required Directory destination,
}) {
  if (destination.existsSync()) {
    destination.deleteSync(recursive: true);
  }
  copyDirectory(source: source, destination: destination);
}

void copyFileReplacing({required File source, required File destination}) {
  destination.parent.createSync(recursive: true);
  final destinationType = FileSystemEntity.typeSync(
    destination.path,
    followLinks: false,
  );
  if (destinationType != FileSystemEntityType.notFound) {
    deleteFileSystemEntitySync(destination.path, destinationType);
  }
  source.copySync(destination.path);
}

void copyFileSystemEntityReplacing({
  required String sourcePath,
  required String destinationPath,
}) {
  Directory(dirname(destinationPath)).createSync(recursive: true);
  final destinationType = FileSystemEntity.typeSync(
    destinationPath,
    followLinks: false,
  );
  if (destinationType != FileSystemEntityType.notFound) {
    deleteFileSystemEntitySync(destinationPath, destinationType);
  }

  final sourceType = FileSystemEntity.typeSync(sourcePath, followLinks: false);
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

class GptkD3DMetalSource {
  const GptkD3DMetalSource({
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

const gptkD3DMetalComponentId = 'gptk-d3dmetal';

const gptkD3DMetalComponentRelativePath = <String>[
  'components',
  gptkD3DMetalComponentId,
];

const gptkD3DMetalComponentLibRelativePath = <String>[
  ...gptkD3DMetalComponentRelativePath,
  'lib',
];

void installGptkD3DMetalComponentPayload({
  required GptkD3DMetalSource source,
  required Directory runtimeRoot,
  required GptkWineImportVersion detectedVersion,
}) {
  final componentRoot = Directory(
    joinPath(runtimeRoot.path, gptkD3DMetalComponentRelativePath),
  );
  if (componentRoot.existsSync()) {
    componentRoot.deleteSync(recursive: true);
  }

  final externalRoot = Directory(
    joinPath(componentRoot.path, const ['lib', 'external']),
  )..createSync(recursive: true);
  copyDirectoryReplacing(
    source: source.framework,
    destination: Directory(
      joinPath(externalRoot.path, const ['D3DMetal.framework']),
    ),
  );
  copyFileReplacing(
    source: source.dylib,
    destination: File(
      joinPath(externalRoot.path, const ['libd3dshared.dylib']),
    ),
  );

  final windowsDllRoot = Directory(
    joinPath(componentRoot.path, const ['lib', 'wine', 'x86_64-windows']),
  )..createSync(recursive: true);
  for (final fileName in requiredGptkD3DMetalWindowsFileNamesForVersion(
    detectedVersion,
  )) {
    final sourcePath = gptkD3DMetalWindowsPayloadPath(
      source.windowsDllRoot,
      fileName,
    );
    if (sourcePath == null) {
      throw FileSystemException(
        'GPTK/D3DMetal Windows DLL was not found.',
        joinPath(source.windowsDllRoot.path, [fileName]),
      );
    }
    copyFileReplacing(
      source: File(sourcePath),
      destination: File(joinPath(windowsDllRoot.path, [fileName])),
    );
  }

  final unixLibraryRoot = Directory(
    joinPath(componentRoot.path, const ['lib', 'wine', 'x86_64-unix']),
  )..createSync(recursive: true);
  for (final fileName in requiredGptkD3DMetalUnixFileNamesForVersion(
    detectedVersion,
  )) {
    final sourcePath = gptkD3DMetalUnixPayloadPath(
      source.unixLibraryRoot,
      fileName,
    );
    if (sourcePath == null) {
      throw FileSystemException(
        'GPTK/D3DMetal Unix library was not found.',
        joinPath(source.unixLibraryRoot.path, [fileName]),
      );
    }
    copyFileSystemEntityReplacing(
      sourcePath: sourcePath,
      destinationPath: joinPath(unixLibraryRoot.path, [fileName]),
    );
  }
}
