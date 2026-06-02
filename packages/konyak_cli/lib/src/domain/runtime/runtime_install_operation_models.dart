part of '../../../konyak_cli.dart';

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

  RuntimeInstallSource get installSource;

  Option<String> get archivePath => switch (installSource) {
    RuntimeLocalArchiveSource(:final archivePath) => Option.of(archivePath),
    _ => const Option.none(),
  };

  Option<String> get archiveUrl => switch (installSource) {
    RuntimeRemoteArchiveSource(:final archiveUrl) => Option.of(archiveUrl),
    _ => const Option.none(),
  };

  Option<String> get archiveSha256 => switch (installSource) {
    RuntimeConfiguredArchiveSource(:final archiveChecksum) =>
      archiveChecksum.asOption,
    RuntimeLocalArchiveSource(:final archiveChecksum) =>
      archiveChecksum.asOption,
    RuntimeRemoteArchiveSource(:final archiveChecksum) =>
      archiveChecksum.asOption,
    RuntimeSourceManifestInstallSource() => const Option.none(),
  };

  IList<String> get componentArchivePaths => switch (installSource) {
    RuntimeConfiguredArchiveSource(:final componentArchivePaths) =>
      componentArchivePaths,
    RuntimeLocalArchiveSource(:final componentArchivePaths) =>
      componentArchivePaths,
    RuntimeRemoteArchiveSource(:final componentArchivePaths) =>
      componentArchivePaths,
    RuntimeSourceManifestInstallSource() => const IList<String>.empty(),
  };

  Option<String> get sourceManifest => switch (installSource) {
    RuntimeSourceManifestInstallSource(:final sourceManifest) => Option.of(
      sourceManifest,
    ),
    _ => const Option.none(),
  };

  Option<String> get sourceManifestSignature => switch (installSource) {
    RuntimeSourceManifestInstallSource(:final signature) => signature.asOption,
    _ => const Option.none(),
  };
}

sealed class RuntimeArchiveChecksum {
  const RuntimeArchiveChecksum();

  const factory RuntimeArchiveChecksum.absent() = RuntimeArchiveChecksumAbsent;

  factory RuntimeArchiveChecksum.sha256(String value) =
      RuntimeSha256ArchiveChecksum;

  Option<String> get asOption => switch (this) {
    RuntimeArchiveChecksumAbsent() => const Option.none(),
    RuntimeSha256ArchiveChecksum(:final value) => Option.of(value),
  };
}

final class RuntimeArchiveChecksumAbsent extends RuntimeArchiveChecksum {
  const RuntimeArchiveChecksumAbsent();
}

final class RuntimeSha256ArchiveChecksum extends RuntimeArchiveChecksum {
  RuntimeSha256ArchiveChecksum(String value)
    : value = _requiredNonBlankDomainString(value, 'archiveSha256');

  final String value;
}

sealed class RuntimeSourceManifestSignature {
  const RuntimeSourceManifestSignature();

  const factory RuntimeSourceManifestSignature.absent() =
      RuntimeSourceManifestSignatureAbsent;

  factory RuntimeSourceManifestSignature.signed(String value) =
      RuntimeSourceManifestSigned;

  Option<String> get asOption => switch (this) {
    RuntimeSourceManifestSignatureAbsent() => const Option.none(),
    RuntimeSourceManifestSigned(:final value) => Option.of(value),
  };
}

final class RuntimeSourceManifestSignatureAbsent
    extends RuntimeSourceManifestSignature {
  const RuntimeSourceManifestSignatureAbsent();
}

final class RuntimeSourceManifestSigned extends RuntimeSourceManifestSignature {
  RuntimeSourceManifestSigned(String value)
    : value = _requiredNonBlankDomainString(value, 'sourceManifestSignature');

  final String value;
}

sealed class RuntimeInstallSource {
  const RuntimeInstallSource();

  bool get hasExplicitInstallSource;

  static RuntimeInstallSource fromOptions({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Iterable<String> componentArchivePaths = const <String>[],
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
  }) {
    final checksum = _runtimeArchiveChecksum(archiveSha256);
    final signature = _runtimeSourceManifestSignature(sourceManifestSignature);
    final components = _runtimeComponentArchivePaths(componentArchivePaths);
    final manifest = sourceManifest.map(
      (value) => _requiredNonBlankDomainString(value, 'sourceManifest'),
    );
    final localArchive = archivePath.map(
      (value) => _requiredNonBlankDomainString(value, 'archivePath'),
    );
    final remoteArchive = archiveUrl.map(
      (value) => _requiredNonBlankDomainString(value, 'archiveUrl'),
    );

    if (manifest.isSome()) {
      if (localArchive.isSome() ||
          remoteArchive.isSome() ||
          checksum is RuntimeSha256ArchiveChecksum ||
          components.isNotEmpty) {
        throw ArgumentError(
          'sourceManifest cannot be combined with archive sources.',
        );
      }

      return RuntimeSourceManifestInstallSource(
        sourceManifest: manifest.getOrElse(
          () => throw StateError('Expected source manifest.'),
        ),
        signature: signature,
      );
    }

    if (localArchive.isSome() && remoteArchive.isSome()) {
      throw ArgumentError('archivePath and archiveUrl are mutually exclusive.');
    }

    return localArchive.match(
      () => remoteArchive.match(
        () => RuntimeConfiguredArchiveSource(
          archiveChecksum: checksum,
          componentArchivePaths: components,
        ),
        (value) => RuntimeRemoteArchiveSource(
          archiveUrl: value,
          archiveChecksum: checksum,
          componentArchivePaths: components,
        ),
      ),
      (value) => RuntimeLocalArchiveSource(
        archivePath: value,
        archiveChecksum: checksum,
        componentArchivePaths: components,
      ),
    );
  }
}

final class RuntimeConfiguredArchiveSource extends RuntimeInstallSource {
  RuntimeConfiguredArchiveSource({
    this.archiveChecksum = const RuntimeArchiveChecksum.absent(),
    Iterable<String> componentArchivePaths = const <String>[],
  }) : componentArchivePaths = _runtimeComponentArchivePaths(
         componentArchivePaths,
       );

  final RuntimeArchiveChecksum archiveChecksum;
  final IList<String> componentArchivePaths;

  @override
  bool get hasExplicitInstallSource => componentArchivePaths.isNotEmpty;
}

final class RuntimeLocalArchiveSource extends RuntimeInstallSource {
  RuntimeLocalArchiveSource({
    required String archivePath,
    this.archiveChecksum = const RuntimeArchiveChecksum.absent(),
    Iterable<String> componentArchivePaths = const <String>[],
  }) : archivePath = _requiredNonBlankDomainString(archivePath, 'archivePath'),
       componentArchivePaths = _runtimeComponentArchivePaths(
         componentArchivePaths,
       );

  final String archivePath;
  final RuntimeArchiveChecksum archiveChecksum;
  final IList<String> componentArchivePaths;

  @override
  bool get hasExplicitInstallSource => true;
}

final class RuntimeRemoteArchiveSource extends RuntimeInstallSource {
  RuntimeRemoteArchiveSource({
    required String archiveUrl,
    this.archiveChecksum = const RuntimeArchiveChecksum.absent(),
    Iterable<String> componentArchivePaths = const <String>[],
  }) : archiveUrl = _requiredNonBlankDomainString(archiveUrl, 'archiveUrl'),
       componentArchivePaths = _runtimeComponentArchivePaths(
         componentArchivePaths,
       );

  final String archiveUrl;
  final RuntimeArchiveChecksum archiveChecksum;
  final IList<String> componentArchivePaths;

  @override
  bool get hasExplicitInstallSource => true;
}

final class RuntimeSourceManifestInstallSource extends RuntimeInstallSource {
  RuntimeSourceManifestInstallSource({
    required String sourceManifest,
    this.signature = const RuntimeSourceManifestSignature.absent(),
  }) : sourceManifest = _requiredNonBlankDomainString(
         sourceManifest,
         'sourceManifest',
       );

  final String sourceManifest;
  final RuntimeSourceManifestSignature signature;

  @override
  bool get hasExplicitInstallSource => true;
}

final class RuntimeFullInstallOperation extends RuntimeInstallRequestOperation {
  RuntimeFullInstallOperation({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    this.force = false,
  }) : installSource = RuntimeInstallSource.fromOptions(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
       );

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.fullInstall;

  @override
  final RuntimeInstallSource installSource;

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
  }) : installSource = RuntimeInstallSource.fromOptions(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
       );

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.repair;

  @override
  final RuntimeInstallSource installSource;

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
  }) : installSource = RuntimeInstallSource.fromOptions(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         componentArchivePaths: componentArchivePaths,
       );

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.componentInstall;

  @override
  final RuntimeInstallSource installSource;

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
  }) : installSource = RuntimeInstallSource.fromOptions(
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
       );

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.updateInstall;

  @override
  final RuntimeInstallSource installSource;

  @override
  final bool force;
}

class _RuntimeWineInstallRequestAccessors {
  const _RuntimeWineInstallRequestAccessors(this.requestOperation);

  final RuntimeInstallRequestOperation requestOperation;

  RuntimeInstallOperation get operation => requestOperation.operation;

  RuntimeInstallSource get installSource => requestOperation.installSource;

  Option<String> get archivePath => requestOperation.archivePath;

  Option<String> get archiveUrl => requestOperation.archiveUrl;

  Option<String> get archiveSha256 => requestOperation.archiveSha256;

  IList<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  Option<String> get sourceManifest => requestOperation.sourceManifest;

  Option<String> get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

RuntimeArchiveChecksum _runtimeArchiveChecksum(Option<String> value) {
  return value.match(
    () => const RuntimeArchiveChecksum.absent(),
    RuntimeArchiveChecksum.sha256,
  );
}

RuntimeSourceManifestSignature _runtimeSourceManifestSignature(
  Option<String> value,
) {
  return value.match(
    () => const RuntimeSourceManifestSignature.absent(),
    RuntimeSourceManifestSignature.signed,
  );
}

IList<String> _runtimeComponentArchivePaths(Iterable<String> paths) {
  return paths
      .map(
        (path) => _requiredNonBlankDomainString(path, 'componentArchivePath'),
      )
      .toIList();
}
