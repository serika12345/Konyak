import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/runtime/runtime_install_operation_models.dart';
import '../../domain/shared/domain_value_objects.dart';

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
         requestOperation: RuntimeInstallRequestOperation.fullInstall(
           archivePath: Option.fromNullable(
             archivePath,
           ).map(RuntimeArchivePath.new),
           archiveUrl: Option.fromNullable(
             archiveUrl,
           ).map(RuntimeArchiveUrl.new),
           archiveSha256: Option.fromNullable(
             archiveSha256,
           ).map(RuntimeArchiveChecksumValue.new),
           sourceManifest: Option.fromNullable(
             sourceManifest,
           ).map(RuntimeSourceManifestUrl.new),
           sourceManifestSignature: Option.fromNullable(
             sourceManifestSignature,
           ).map(RuntimeSourceManifestSignatureUrl.new),
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
         requestOperation: RuntimeInstallRequestOperation.repair(
           archivePath: Option.fromNullable(
             archivePath,
           ).map(RuntimeArchivePath.new),
           archiveUrl: Option.fromNullable(
             archiveUrl,
           ).map(RuntimeArchiveUrl.new),
           archiveSha256: Option.fromNullable(
             archiveSha256,
           ).map(RuntimeArchiveChecksumValue.new),
           sourceManifest: Option.fromNullable(
             sourceManifest,
           ).map(RuntimeSourceManifestUrl.new),
           sourceManifestSignature: Option.fromNullable(
             sourceManifestSignature,
           ).map(RuntimeSourceManifestSignatureUrl.new),
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
         requestOperation: RuntimeInstallRequestOperation.componentInstall(
           archivePath: Option.fromNullable(
             archivePath,
           ).map(RuntimeArchivePath.new),
           archiveUrl: Option.fromNullable(
             archiveUrl,
           ).map(RuntimeArchiveUrl.new),
           archiveSha256: Option.fromNullable(
             archiveSha256,
           ).map(RuntimeArchiveChecksumValue.new),
           componentArchivePaths: componentArchivePaths.map(
             RuntimeArchivePath.new,
           ),
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
         requestOperation: RuntimeInstallRequestOperation.updateInstall(
           archiveUrl: Option.fromNullable(
             archiveUrl,
           ).map(RuntimeArchiveUrl.new),
           archiveSha256: Option.fromNullable(
             archiveSha256,
           ).map(RuntimeArchiveChecksumValue.new),
           sourceManifest: Option.fromNullable(
             sourceManifest,
           ).map(RuntimeSourceManifestUrl.new),
           sourceManifestSignature: Option.fromNullable(
             sourceManifestSignature,
           ).map(RuntimeSourceManifestSignatureUrl.new),
           force: force,
         ),
         emitProgress: emitProgress,
       );

  MacosWineInstallRequest._({
    required this.requestOperation,
    required this.emitProgress,
  });

  final RuntimeInstallRequestOperation requestOperation;
  final bool emitProgress;

  RuntimeInstallOperation get operation => requestOperation.operation;

  Option<String> get archivePath =>
      requestOperation.archivePath.map((path) => path.value);

  Option<String> get archiveUrl =>
      requestOperation.archiveUrl.map((url) => url.value);

  Option<String> get archiveSha256 =>
      requestOperation.archiveSha256.map((checksum) => checksum.value);

  IList<String> get componentArchivePaths => requestOperation
      .componentArchivePaths
      .map((path) => path.value)
      .toIList();

  Option<String> get sourceManifest => requestOperation.sourceManifest.map(
    (sourceManifest) => sourceManifest.value,
  );

  Option<String> get sourceManifestSignature => requestOperation
      .sourceManifestSignature
      .map((signature) => signature.value);

  bool get force => requestOperation.force;
}
