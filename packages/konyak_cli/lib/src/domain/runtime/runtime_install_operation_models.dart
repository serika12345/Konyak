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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeInstallRequestOperation
    with _$RuntimeInstallRequestOperation {
  const RuntimeInstallRequestOperation._();

  factory RuntimeInstallRequestOperation.fullInstall({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    bool force = false,
  }) {
    return RuntimeInstallRequestOperation._fullInstall(
      installSource: RuntimeInstallSource.fromOptions(
        archivePath: archivePath,
        archiveUrl: archiveUrl,
        archiveSha256: archiveSha256,
        sourceManifest: sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
      ),
      force: force,
    );
  }

  const factory RuntimeInstallRequestOperation._fullInstall({
    required RuntimeInstallSource installSource,
    required bool force,
  }) = RuntimeFullInstallOperation;

  factory RuntimeInstallRequestOperation.repair({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    bool force = true,
  }) {
    return RuntimeInstallRequestOperation._repair(
      installSource: RuntimeInstallSource.fromOptions(
        archivePath: archivePath,
        archiveUrl: archiveUrl,
        archiveSha256: archiveSha256,
        sourceManifest: sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
      ),
      force: force,
    );
  }

  const factory RuntimeInstallRequestOperation._repair({
    required RuntimeInstallSource installSource,
    required bool force,
  }) = RuntimeRepairOperation;

  factory RuntimeInstallRequestOperation.componentInstall({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Iterable<String> componentArchivePaths = const <String>[],
    bool force = false,
  }) {
    return RuntimeInstallRequestOperation._componentInstall(
      installSource: RuntimeInstallSource.fromOptions(
        archivePath: archivePath,
        archiveUrl: archiveUrl,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
      ),
      force: force,
    );
  }

  const factory RuntimeInstallRequestOperation._componentInstall({
    required RuntimeInstallSource installSource,
    required bool force,
  }) = RuntimeComponentInstallOperation;

  factory RuntimeInstallRequestOperation.updateInstall({
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
    bool force = true,
  }) {
    return RuntimeInstallRequestOperation._updateInstall(
      installSource: RuntimeInstallSource.fromOptions(
        archiveUrl: archiveUrl,
        archiveSha256: archiveSha256,
        sourceManifest: sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
      ),
      force: force,
    );
  }

  const factory RuntimeInstallRequestOperation._updateInstall({
    required RuntimeInstallSource installSource,
    required bool force,
  }) = RuntimeUpdateInstallOperation;

  RuntimeInstallOperation get operation => switch (this) {
    RuntimeFullInstallOperation() => RuntimeInstallOperation.fullInstall,
    RuntimeRepairOperation() => RuntimeInstallOperation.repair,
    RuntimeComponentInstallOperation() =>
      RuntimeInstallOperation.componentInstall,
    RuntimeUpdateInstallOperation() => RuntimeInstallOperation.updateInstall,
  };

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

  factory RuntimeSourceManifestSignature.signed(
    RuntimeSourceManifestSignatureUrl value,
  ) {
    return RuntimeSourceManifestSignature._signed(value);
  }

  const factory RuntimeSourceManifestSignature._signed(
    RuntimeSourceManifestSignatureUrl value,
  ) = RuntimeSourceManifestSigned;

  Option<RuntimeSourceManifestSignatureUrl> get asOption => switch (this) {
    RuntimeSourceManifestSignatureAbsent() => const Option.none(),
    RuntimeSourceManifestSigned(:final value) => Option.of(value),
  };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeInstallSource with _$RuntimeInstallSource {
  const RuntimeInstallSource._();

  bool get hasExplicitInstallSource => switch (this) {
    RuntimeConfiguredArchiveSource(:final componentArchivePaths) =>
      componentArchivePaths.isNotEmpty,
    RuntimeLocalArchiveSource() => true,
    RuntimeRemoteArchiveSource() => true,
    RuntimeSourceManifestInstallSource() => true,
  };

  static RuntimeInstallSource fromOptions({
    Option<String> archivePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Iterable<String> componentArchivePaths = const <String>[],
    Option<String> sourceManifest = const Option.none(),
    Option<String> sourceManifestSignature = const Option.none(),
  }) {
    final checksum = _runtimeArchiveChecksum(archiveSha256);
    final signature = runtimeSourceManifestSignature(
      sourceManifestSignature.map(RuntimeSourceManifestSignatureUrl.new),
    );
    final components = _runtimeComponentArchivePaths(
      componentArchivePaths.map(RuntimeArchivePath.new),
    );
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

        return RuntimeInstallSource._sourceManifest(
          sourceManifest: sourceManifest,
          signature: signature,
        );
      },
    );
  }

  factory RuntimeInstallSource.configuredArchive({
    RuntimeArchiveChecksum archiveChecksum =
        const RuntimeArchiveChecksum.absent(),
    Iterable<RuntimeArchivePath> componentArchivePaths =
        const <RuntimeArchivePath>[],
  }) {
    return RuntimeInstallSource._configuredArchive(
      archiveChecksum: archiveChecksum,
      componentArchivePaths: _runtimeComponentArchivePaths(
        componentArchivePaths,
      ),
    );
  }

  const factory RuntimeInstallSource._configuredArchive({
    required RuntimeArchiveChecksum archiveChecksum,
    required IList<RuntimeArchivePath> componentArchivePaths,
  }) = RuntimeConfiguredArchiveSource;

  factory RuntimeInstallSource.localArchive({
    required RuntimeArchivePath archivePath,
    RuntimeArchiveChecksum archiveChecksum =
        const RuntimeArchiveChecksum.absent(),
    Iterable<RuntimeArchivePath> componentArchivePaths =
        const <RuntimeArchivePath>[],
  }) {
    return RuntimeInstallSource._localArchive(
      archivePath: archivePath,
      archiveChecksum: archiveChecksum,
      componentArchivePaths: _runtimeComponentArchivePaths(
        componentArchivePaths,
      ),
    );
  }

  const factory RuntimeInstallSource._localArchive({
    required RuntimeArchivePath archivePath,
    required RuntimeArchiveChecksum archiveChecksum,
    required IList<RuntimeArchivePath> componentArchivePaths,
  }) = RuntimeLocalArchiveSource;

  factory RuntimeInstallSource.remoteArchive({
    required RuntimeArchiveUrl archiveUrl,
    RuntimeArchiveChecksum archiveChecksum =
        const RuntimeArchiveChecksum.absent(),
    Iterable<RuntimeArchivePath> componentArchivePaths =
        const <RuntimeArchivePath>[],
  }) {
    return RuntimeInstallSource._remoteArchive(
      archiveUrl: archiveUrl,
      archiveChecksum: archiveChecksum,
      componentArchivePaths: _runtimeComponentArchivePaths(
        componentArchivePaths,
      ),
    );
  }

  const factory RuntimeInstallSource._remoteArchive({
    required RuntimeArchiveUrl archiveUrl,
    required RuntimeArchiveChecksum archiveChecksum,
    required IList<RuntimeArchivePath> componentArchivePaths,
  }) = RuntimeRemoteArchiveSource;

  factory RuntimeInstallSource.sourceManifest({
    required RuntimeSourceManifestUrl sourceManifest,
    RuntimeSourceManifestSignature signature =
        const RuntimeSourceManifestSignature.absent(),
  }) {
    return RuntimeInstallSource._sourceManifest(
      sourceManifest: sourceManifest,
      signature: signature,
    );
  }

  const factory RuntimeInstallSource._sourceManifest({
    required RuntimeSourceManifestUrl sourceManifest,
    required RuntimeSourceManifestSignature signature,
  }) = RuntimeSourceManifestInstallSource;
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
      () => RuntimeInstallSource._configuredArchive(
        archiveChecksum: checksum,
        componentArchivePaths: components,
      ),
      (value) => RuntimeInstallSource._remoteArchive(
        archiveUrl: value,
        archiveChecksum: checksum,
        componentArchivePaths: components,
      ),
    ),
    (value) => RuntimeInstallSource._localArchive(
      archivePath: value,
      archiveChecksum: checksum,
      componentArchivePaths: components,
    ),
  );
}

RuntimeArchiveChecksum _runtimeArchiveChecksum(Option<String> value) {
  return value.match(
    () => const RuntimeArchiveChecksum.absent(),
    RuntimeArchiveChecksum.sha256,
  );
}

RuntimeSourceManifestSignature runtimeSourceManifestSignature(
  Option<RuntimeSourceManifestSignatureUrl> value,
) {
  return value.match(
    () => const RuntimeSourceManifestSignature.absent(),
    RuntimeSourceManifestSignature.signed,
  );
}

IList<RuntimeArchivePath> _runtimeComponentArchivePaths(
  Iterable<RuntimeArchivePath> paths,
) {
  return paths.toIList();
}
