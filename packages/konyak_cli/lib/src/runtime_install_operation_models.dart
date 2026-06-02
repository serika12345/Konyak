part of '../konyak_cli.dart';

enum RuntimeInstallOperation {
  fullInstall,
  repair,
  componentInstall,
  updateInstall,
}

sealed class RuntimeInstallRequestOperation {
  const RuntimeInstallRequestOperation();

  RuntimeInstallOperation get operation;

  bool get force;

  String? get archivePath => null;

  String? get archiveUrl => null;

  String? get archiveSha256 => null;

  List<String> get componentArchivePaths => const <String>[];

  String? get sourceManifest => null;

  String? get sourceManifestSignature => null;
}

final class RuntimeFullInstallOperation extends RuntimeInstallRequestOperation {
  const RuntimeFullInstallOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = false,
  });

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.fullInstall;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeRepairOperation extends RuntimeInstallRequestOperation {
  const RuntimeRepairOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = true,
  });

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.repair;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeComponentInstallOperation
    extends RuntimeInstallRequestOperation {
  RuntimeComponentInstallOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    this.force = false,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths);

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.componentInstall;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final List<String> componentArchivePaths;

  @override
  final bool force;
}

final class RuntimeUpdateInstallOperation
    extends RuntimeInstallRequestOperation {
  const RuntimeUpdateInstallOperation({
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = true,
  });

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.updateInstall;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

mixin _RuntimeWineInstallRequestAccessors {
  RuntimeInstallRequestOperation get requestOperation;

  RuntimeInstallOperation get operation => requestOperation.operation;

  String? get archivePath => requestOperation.archivePath;

  String? get archiveUrl => requestOperation.archiveUrl;

  String? get archiveSha256 => requestOperation.archiveSha256;

  List<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  String? get sourceManifest => requestOperation.sourceManifest;

  String? get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}
