import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';

part 'runtime_install_operation_models.freezed.dart';

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

  Option<RuntimeArchivePath> get archivePath => switch (installSource) {
    RuntimeLocalArchiveSource(:final archivePath) => Option.of(archivePath),
    _ => const Option.none(),
  };

  Option<RuntimeArchiveUrl> get archiveUrl => switch (installSource) {
    RuntimeRemoteArchiveSource(:final archiveUrl) => Option.of(archiveUrl),
    _ => const Option.none(),
  };

  Option<RuntimeArchiveChecksumValue> get archiveSha256 =>
      switch (installSource) {
        RuntimeConfiguredArchiveSource(:final archiveChecksum) =>
          archiveChecksum.asOption,
        RuntimeLocalArchiveSource(:final archiveChecksum) =>
          archiveChecksum.asOption,
        RuntimeRemoteArchiveSource(:final archiveChecksum) =>
          archiveChecksum.asOption,
        RuntimeSourceManifestInstallSource() => const Option.none(),
      };

  IList<RuntimeArchivePath> get componentArchivePaths =>
      switch (installSource) {
        RuntimeConfiguredArchiveSource(:final componentArchivePaths) =>
          componentArchivePaths,
        RuntimeLocalArchiveSource(:final componentArchivePaths) =>
          componentArchivePaths,
        RuntimeRemoteArchiveSource(:final componentArchivePaths) =>
          componentArchivePaths,
        RuntimeSourceManifestInstallSource() =>
          const IList<RuntimeArchivePath>.empty(),
      };

  Option<RuntimeSourceManifestUrl> get sourceManifest =>
      switch (installSource) {
        RuntimeSourceManifestInstallSource(:final sourceManifest) => Option.of(
          sourceManifest,
        ),
        _ => const Option.none(),
      };

  Option<RuntimeSourceManifestSignatureUrl> get sourceManifestSignature =>
      switch (installSource) {
        RuntimeSourceManifestInstallSource(:final signature) =>
          signature.asOption,
        _ => const Option.none(),
      };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeArchiveChecksum with _$RuntimeArchiveChecksum {
  const RuntimeArchiveChecksum._();

  const factory RuntimeArchiveChecksum.absent() = RuntimeArchiveChecksumAbsent;

  factory RuntimeArchiveChecksum.sha256(String value) {
    return RuntimeArchiveChecksum._sha256(RuntimeArchiveChecksumValue(value));
  }

  const factory RuntimeArchiveChecksum._sha256(
    RuntimeArchiveChecksumValue value,
  ) = RuntimeSha256ArchiveChecksum;

  Option<RuntimeArchiveChecksumValue> get asOption => switch (this) {
    RuntimeArchiveChecksumAbsent() => const Option.none(),
    RuntimeSha256ArchiveChecksum(:final value) => Option.of(value),
  };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeSourceManifestSignature
    with _$RuntimeSourceManifestSignature {
  const RuntimeSourceManifestSignature._();

  const factory RuntimeSourceManifestSignature.absent() =
      RuntimeSourceManifestSignatureAbsent;

  factory RuntimeSourceManifestSignature.signed(String value) {
    return RuntimeSourceManifestSignature._signed(
      RuntimeSourceManifestSignatureUrl(value),
    );
  }

  const factory RuntimeSourceManifestSignature._signed(
    RuntimeSourceManifestSignatureUrl value,
  ) = RuntimeSourceManifestSigned;

  Option<RuntimeSourceManifestSignatureUrl> get asOption => switch (this) {
    RuntimeSourceManifestSignatureAbsent() => const Option.none(),
    RuntimeSourceManifestSigned(:final value) => Option.of(value),
  };
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
    final signature = runtimeSourceManifestSignature(sourceManifestSignature);
    final components = _runtimeComponentArchivePaths(componentArchivePaths);
    final manifest = sourceManifest.map(RuntimeSourceManifestUrl.new);

    return manifest.match(
      () => _runtimeArchiveInstallSourceFromOptions(
        archivePath: archivePath,
        archiveUrl: archiveUrl,
        checksum: checksum,
        components: components,
      ),
      (sourceManifest) {
        final localArchive = archivePath.map(RuntimeArchivePath.new);
        final remoteArchive = archiveUrl.map(RuntimeArchiveUrl.new);
        if (localArchive.isSome() ||
            remoteArchive.isSome() ||
            checksum is RuntimeSha256ArchiveChecksum ||
            components.isNotEmpty) {
          throw ArgumentError(
            'sourceManifest cannot be combined with archive sources.',
          );
        }

        return RuntimeSourceManifestInstallSource(
          sourceManifest: sourceManifest.value,
          signature: signature,
        );
      },
    );
  }
}

RuntimeInstallSource _runtimeArchiveInstallSourceFromOptions({
  required Option<String> archivePath,
  required Option<String> archiveUrl,
  required RuntimeArchiveChecksum checksum,
  required IList<RuntimeArchivePath> components,
}) {
  final localArchive = archivePath.map(RuntimeArchivePath.new);
  final remoteArchive = archiveUrl.map(RuntimeArchiveUrl.new);

  if (localArchive.isSome() && remoteArchive.isSome()) {
    throw ArgumentError('archivePath and archiveUrl are mutually exclusive.');
  }

  return localArchive.match(
    () => remoteArchive.match(
      () => RuntimeConfiguredArchiveSource(
        archiveChecksum: checksum,
        componentArchivePaths: components.map((value) => value.value),
      ),
      (value) => RuntimeRemoteArchiveSource(
        archiveUrl: value.value,
        archiveChecksum: checksum,
        componentArchivePaths: components.map((value) => value.value),
      ),
    ),
    (value) => RuntimeLocalArchiveSource(
      archivePath: value.value,
      archiveChecksum: checksum,
      componentArchivePaths: components.map((value) => value.value),
    ),
  );
}

final class RuntimeConfiguredArchiveSource extends RuntimeInstallSource {
  RuntimeConfiguredArchiveSource({
    this.archiveChecksum = const RuntimeArchiveChecksum.absent(),
    Iterable<String> componentArchivePaths = const <String>[],
  }) : componentArchivePaths = _runtimeComponentArchivePaths(
         componentArchivePaths,
       );

  final RuntimeArchiveChecksum archiveChecksum;
  final IList<RuntimeArchivePath> componentArchivePaths;

  @override
  bool get hasExplicitInstallSource => componentArchivePaths.isNotEmpty;
}

final class RuntimeLocalArchiveSource extends RuntimeInstallSource {
  RuntimeLocalArchiveSource({
    required String archivePath,
    this.archiveChecksum = const RuntimeArchiveChecksum.absent(),
    Iterable<String> componentArchivePaths = const <String>[],
  }) : archivePath = RuntimeArchivePath(archivePath),
       componentArchivePaths = _runtimeComponentArchivePaths(
         componentArchivePaths,
       );

  final RuntimeArchivePath archivePath;
  final RuntimeArchiveChecksum archiveChecksum;
  final IList<RuntimeArchivePath> componentArchivePaths;

  @override
  bool get hasExplicitInstallSource => true;
}

final class RuntimeRemoteArchiveSource extends RuntimeInstallSource {
  RuntimeRemoteArchiveSource({
    required String archiveUrl,
    this.archiveChecksum = const RuntimeArchiveChecksum.absent(),
    Iterable<String> componentArchivePaths = const <String>[],
  }) : archiveUrl = RuntimeArchiveUrl(archiveUrl),
       componentArchivePaths = _runtimeComponentArchivePaths(
         componentArchivePaths,
       );

  final RuntimeArchiveUrl archiveUrl;
  final RuntimeArchiveChecksum archiveChecksum;
  final IList<RuntimeArchivePath> componentArchivePaths;

  @override
  bool get hasExplicitInstallSource => true;
}

final class RuntimeSourceManifestInstallSource extends RuntimeInstallSource {
  RuntimeSourceManifestInstallSource({
    required String sourceManifest,
    this.signature = const RuntimeSourceManifestSignature.absent(),
  }) : sourceManifest = RuntimeSourceManifestUrl(sourceManifest);

  final RuntimeSourceManifestUrl sourceManifest;
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

class RuntimeWineInstallRequestAccessors {
  const RuntimeWineInstallRequestAccessors(this.requestOperation);

  final RuntimeInstallRequestOperation requestOperation;

  RuntimeInstallOperation get operation => requestOperation.operation;

  RuntimeInstallSource get installSource => requestOperation.installSource;

  Option<RuntimeArchivePath> get archivePath => requestOperation.archivePath;

  Option<RuntimeArchiveUrl> get archiveUrl => requestOperation.archiveUrl;

  Option<RuntimeArchiveChecksumValue> get archiveSha256 =>
      requestOperation.archiveSha256;

  IList<RuntimeArchivePath> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  Option<RuntimeSourceManifestUrl> get sourceManifest =>
      requestOperation.sourceManifest;

  Option<RuntimeSourceManifestSignatureUrl> get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

RuntimeArchiveChecksum _runtimeArchiveChecksum(Option<String> value) {
  return value.match(
    () => const RuntimeArchiveChecksum.absent(),
    RuntimeArchiveChecksum.sha256,
  );
}

RuntimeSourceManifestSignature runtimeSourceManifestSignature(
  Option<String> value,
) {
  return value.match(
    () => const RuntimeSourceManifestSignature.absent(),
    RuntimeSourceManifestSignature.signed,
  );
}

IList<RuntimeArchivePath> _runtimeComponentArchivePaths(
  Iterable<String> paths,
) {
  return paths.map(RuntimeArchivePath.new).toIList();
}
