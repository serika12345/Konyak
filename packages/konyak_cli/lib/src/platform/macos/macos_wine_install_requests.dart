import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/runtime/runtime_install_operation_models.dart';

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
  }) : accessors = RuntimeWineInstallRequestAccessors(requestOperation);

  final RuntimeWineInstallRequestAccessors accessors;
  final bool emitProgress;

  RuntimeInstallRequestOperation get requestOperation =>
      accessors.requestOperation;

  RuntimeInstallOperation get operation => accessors.operation;

  Option<String> get archivePath =>
      accessors.archivePath.map((path) => path.value);

  Option<String> get archiveUrl => accessors.archiveUrl.map((url) => url.value);

  Option<String> get archiveSha256 =>
      accessors.archiveSha256.map((checksum) => checksum.value);

  IList<String> get componentArchivePaths =>
      accessors.componentArchivePaths.map((path) => path.value).toIList();

  Option<String> get sourceManifest =>
      accessors.sourceManifest.map((sourceManifest) => sourceManifest.value);

  Option<String> get sourceManifestSignature =>
      accessors.sourceManifestSignature.map((signature) => signature.value);

  bool get force => accessors.force;
}
