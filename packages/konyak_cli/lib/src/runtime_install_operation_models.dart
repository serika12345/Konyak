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

  Option<String> get archivePath => const Option.none();

  Option<String> get archiveUrl => const Option.none();

  Option<String> get archiveSha256 => const Option.none();

  List<String> get componentArchivePaths => const <String>[];

  Option<String> get sourceManifest => const Option.none();

  Option<String> get sourceManifestSignature => const Option.none();
}

final class RuntimeFullInstallOperation extends RuntimeInstallRequestOperation {
  RuntimeFullInstallOperation({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    this.force = false,
  }) : archivePath = _optionalRuntimeInstallSource(archivePath, 'archivePath'),
       archiveUrl = _optionalRuntimeInstallSource(archiveUrl, 'archiveUrl'),
       archiveSha256 = _optionalRuntimeInstallSource(
         archiveSha256,
         'archiveSha256',
       ),
       sourceManifest = _optionalRuntimeInstallSource(
         sourceManifest,
         'sourceManifest',
       ),
       sourceManifestSignature = _optionalRuntimeInstallSource(
         sourceManifestSignature,
         'sourceManifestSignature',
       );

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.fullInstall;

  @override
  final Option<String> archivePath;

  @override
  final Option<String> archiveUrl;

  @override
  final Option<String> archiveSha256;

  @override
  final Option<String> sourceManifest;

  @override
  final Option<String> sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeRepairOperation extends RuntimeInstallRequestOperation {
  RuntimeRepairOperation({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    this.force = true,
  }) : archivePath = _optionalRuntimeInstallSource(archivePath, 'archivePath'),
       archiveUrl = _optionalRuntimeInstallSource(archiveUrl, 'archiveUrl'),
       archiveSha256 = _optionalRuntimeInstallSource(
         archiveSha256,
         'archiveSha256',
       ),
       sourceManifest = _optionalRuntimeInstallSource(
         sourceManifest,
         'sourceManifest',
       ),
       sourceManifestSignature = _optionalRuntimeInstallSource(
         sourceManifestSignature,
         'sourceManifestSignature',
       );

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.repair;

  @override
  final Option<String> archivePath;

  @override
  final Option<String> archiveUrl;

  @override
  final Option<String> archiveSha256;

  @override
  final Option<String> sourceManifest;

  @override
  final Option<String> sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeComponentInstallOperation
    extends RuntimeInstallRequestOperation {
  RuntimeComponentInstallOperation({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Iterable<String> componentArchivePaths = const <String>[],
    this.force = false,
  }) : archivePath = _optionalRuntimeInstallSource(archivePath, 'archivePath'),
       archiveUrl = _optionalRuntimeInstallSource(archiveUrl, 'archiveUrl'),
       archiveSha256 = _optionalRuntimeInstallSource(
         archiveSha256,
         'archiveSha256',
       ),
       componentArchivePaths = List.unmodifiable(componentArchivePaths);

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.componentInstall;

  @override
  final Option<String> archivePath;

  @override
  final Option<String> archiveUrl;

  @override
  final Option<String> archiveSha256;

  @override
  final List<String> componentArchivePaths;

  @override
  final bool force;
}

final class RuntimeUpdateInstallOperation
    extends RuntimeInstallRequestOperation {
  RuntimeUpdateInstallOperation({
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    this.force = true,
  }) : archiveUrl = _optionalRuntimeInstallSource(archiveUrl, 'archiveUrl'),
       archiveSha256 = _optionalRuntimeInstallSource(
         archiveSha256,
         'archiveSha256',
       ),
       sourceManifest = _optionalRuntimeInstallSource(
         sourceManifest,
         'sourceManifest',
       ),
       sourceManifestSignature = _optionalRuntimeInstallSource(
         sourceManifestSignature,
         'sourceManifestSignature',
       );

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.updateInstall;

  @override
  final Option<String> archiveUrl;

  @override
  final Option<String> archiveSha256;

  @override
  final Option<String> sourceManifest;

  @override
  final Option<String> sourceManifestSignature;

  @override
  final bool force;
}

class _RuntimeWineInstallRequestAccessors {
  const _RuntimeWineInstallRequestAccessors(this.requestOperation);

  final RuntimeInstallRequestOperation requestOperation;

  RuntimeInstallOperation get operation => requestOperation.operation;

  Option<String> get archivePath => requestOperation.archivePath;

  Option<String> get archiveUrl => requestOperation.archiveUrl;

  Option<String> get archiveSha256 => requestOperation.archiveSha256;

  List<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  Option<String> get sourceManifest => requestOperation.sourceManifest;

  Option<String> get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

Option<String> _optionalRuntimeInstallSource(
  Option<String> value,
  String fieldName,
) {
  return value.map((item) => _requiredNonBlankDomainString(item, fieldName));
}
