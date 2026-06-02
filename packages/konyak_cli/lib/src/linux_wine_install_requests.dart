part of '../konyak_cli.dart';

class LinuxWineInstallRequest {
  LinuxWineInstallRequest.fullInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = false,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeFullInstallOperation(
           archivePath: archivePath,
           archiveUrl: archiveUrl,
           archiveSha256: archiveSha256,
           sourceManifest: sourceManifest,
           sourceManifestSignature: sourceManifestSignature,
           force: force,
         ),
         emitProgress: emitProgress,
       );

  LinuxWineInstallRequest.repair({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeRepairOperation(
           archivePath: archivePath,
           archiveUrl: archiveUrl,
           archiveSha256: archiveSha256,
           sourceManifest: sourceManifest,
           sourceManifestSignature: sourceManifestSignature,
           force: force,
         ),
         emitProgress: emitProgress,
       );

  LinuxWineInstallRequest.componentInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    bool force = false,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeComponentInstallOperation(
           archivePath: archivePath,
           archiveUrl: archiveUrl,
           archiveSha256: archiveSha256,
           componentArchivePaths: componentArchivePaths,
           force: force,
         ),
         emitProgress: emitProgress,
       );

  LinuxWineInstallRequest.updateInstall({
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeUpdateInstallOperation(
           archiveUrl: archiveUrl,
           archiveSha256: archiveSha256,
           sourceManifest: sourceManifest,
           sourceManifestSignature: sourceManifestSignature,
           force: force,
         ),
         emitProgress: emitProgress,
       );

  LinuxWineInstallRequest._({
    required RuntimeInstallRequestOperation requestOperation,
    required this.emitProgress,
  }) : _accessors = _RuntimeWineInstallRequestAccessors(requestOperation);

  final _RuntimeWineInstallRequestAccessors _accessors;
  final bool emitProgress;

  RuntimeInstallRequestOperation get requestOperation =>
      _accessors.requestOperation;

  RuntimeInstallOperation get operation => _accessors.operation;

  Option<String> get archivePath => _accessors.archivePath;

  Option<String> get archiveUrl => _accessors.archiveUrl;

  Option<String> get archiveSha256 => _accessors.archiveSha256;

  List<String> get componentArchivePaths => _accessors.componentArchivePaths;

  Option<String> get sourceManifest => _accessors.sourceManifest;

  Option<String> get sourceManifestSignature =>
      _accessors.sourceManifestSignature;

  bool get force => _accessors.force;
}
