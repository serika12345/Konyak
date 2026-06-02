part of '../konyak_cli.dart';

class LinuxWineInstallRequest with _RuntimeWineInstallRequestAccessors {
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

  @override
  final RuntimeInstallRequestOperation requestOperation;
  final bool emitProgress;
}
