import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/runtime/runtime_install_operation_models.dart';
import '../../domain/shared/domain_value_objects.dart';

class MacosWineInstallRequest {
  MacosWineInstallRequest.fullInstall({
    Option<RuntimeArchivePath> archivePath = const Option.none(),
    Option<RuntimeArchiveUrl> archiveUrl = const Option.none(),
    Option<RuntimeArchiveChecksumValue> archiveSha256 = const Option.none(),
    Option<RuntimeSourceManifestUrl> sourceManifest = const Option.none(),
    Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignature =
        const Option.none(),
    bool force = false,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeInstallRequestOperation.fullInstall(
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
    Option<RuntimeArchivePath> archivePath = const Option.none(),
    Option<RuntimeArchiveUrl> archiveUrl = const Option.none(),
    Option<RuntimeArchiveChecksumValue> archiveSha256 = const Option.none(),
    Option<RuntimeSourceManifestUrl> sourceManifest = const Option.none(),
    Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignature =
        const Option.none(),
    bool force = true,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeInstallRequestOperation.repair(
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
    Option<RuntimeArchivePath> archivePath = const Option.none(),
    Option<RuntimeArchiveUrl> archiveUrl = const Option.none(),
    Option<RuntimeArchiveChecksumValue> archiveSha256 = const Option.none(),
    Iterable<RuntimeArchivePath> componentArchivePaths =
        const <RuntimeArchivePath>[],
    bool force = false,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeInstallRequestOperation.componentInstall(
           archivePath: archivePath,
           archiveUrl: archiveUrl,
           archiveSha256: archiveSha256,
           componentArchivePaths: componentArchivePaths,
           force: force,
         ),
         emitProgress: emitProgress,
       );

  MacosWineInstallRequest.updateInstall({
    Option<RuntimeArchiveUrl> archiveUrl = const Option.none(),
    Option<RuntimeArchiveChecksumValue> archiveSha256 = const Option.none(),
    Option<RuntimeSourceManifestUrl> sourceManifest = const Option.none(),
    Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignature =
        const Option.none(),
    bool force = true,
    bool emitProgress = false,
  }) : this._(
         requestOperation: RuntimeInstallRequestOperation.updateInstall(
           archiveUrl: archiveUrl,
           archiveSha256: archiveSha256,
           sourceManifest: sourceManifest,
           sourceManifestSignature: sourceManifestSignature,
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
