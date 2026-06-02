part of '../konyak_cli.dart';

class MacosWineInstallRequest {
  MacosWineInstallRequest.fullInstall({
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

  MacosWineInstallRequest.repair({
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

  MacosWineInstallRequest.componentInstall({
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

  MacosWineInstallRequest.updateInstall({
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

  MacosWineInstallRequest._({
    required RuntimeInstallRequestOperation requestOperation,
    required this.emitProgress,
  }) : _accessors = _RuntimeWineInstallRequestAccessors(requestOperation);

  final _RuntimeWineInstallRequestAccessors _accessors;
  final bool emitProgress;

  RuntimeInstallRequestOperation get requestOperation =>
      _accessors.requestOperation;

  RuntimeInstallOperation get operation => _accessors.operation;

  String? get archivePath => _accessors.archivePath;

  String? get archiveUrl => _accessors.archiveUrl;

  String? get archiveSha256 => _accessors.archiveSha256;

  List<String> get componentArchivePaths => _accessors.componentArchivePaths;

  String? get sourceManifest => _accessors.sourceManifest;

  String? get sourceManifestSignature => _accessors.sourceManifestSignature;

  bool get force => _accessors.force;
}
