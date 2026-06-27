part of '../../../konyak_cli.dart';

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
           archivePath: Option.fromNullable(archivePath),
           archiveUrl: Option.fromNullable(archiveUrl),
           archiveSha256: Option.fromNullable(archiveSha256),
           sourceManifest: Option.fromNullable(sourceManifest),
           sourceManifestSignature: Option.fromNullable(
             sourceManifestSignature,
           ),
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
           archivePath: Option.fromNullable(archivePath),
           archiveUrl: Option.fromNullable(archiveUrl),
           archiveSha256: Option.fromNullable(archiveSha256),
           sourceManifest: Option.fromNullable(sourceManifest),
           sourceManifestSignature: Option.fromNullable(
             sourceManifestSignature,
           ),
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
           archivePath: Option.fromNullable(archivePath),
           archiveUrl: Option.fromNullable(archiveUrl),
           archiveSha256: Option.fromNullable(archiveSha256),
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
           archiveUrl: Option.fromNullable(archiveUrl),
           archiveSha256: Option.fromNullable(archiveSha256),
           sourceManifest: Option.fromNullable(sourceManifest),
           sourceManifestSignature: Option.fromNullable(
             sourceManifestSignature,
           ),
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

  Option<String> get archivePath =>
      _accessors.archivePath.map((path) => path.value);

  Option<String> get archiveUrl =>
      _accessors.archiveUrl.map((url) => url.value);

  Option<String> get archiveSha256 =>
      _accessors.archiveSha256.map((checksum) => checksum.value);

  IList<String> get componentArchivePaths =>
      _accessors.componentArchivePaths.map((path) => path.value).toIList();

  Option<String> get sourceManifest =>
      _accessors.sourceManifest.map((sourceManifest) => sourceManifest.value);

  Option<String> get sourceManifestSignature =>
      _accessors.sourceManifestSignature.map((signature) => signature.value);

  bool get force => _accessors.force;
}
