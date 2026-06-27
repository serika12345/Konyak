part of '../../konyak_cli.dart';

List<_PeResourceLeaf> _peResourceLeaves(
  _PortableExecutableImage image,
  int typeId,
) {
  return image.resourceRootOffset.match(() => const <_PeResourceLeaf>[], (
    resourceRootOffset,
  ) {
    final rootEntries = _peResourceDirectoryEntries(
      image.bytes,
      resourceRootOffset,
    );
    for (final entry in rootEntries) {
      if (entry.id != typeId || !entry.isDirectory) {
        continue;
      }

      return _peResourceLeavesFromDirectory(
        image: image,
        directoryOffset: resourceRootOffset + entry.targetOffset,
        ids: const <int>[],
      );
    }

    return const <_PeResourceLeaf>[];
  });
}

List<_PeResourceLeaf> _peResourceLeavesFromDirectory({
  required _PortableExecutableImage image,
  required int directoryOffset,
  required List<int> ids,
}) {
  return image.resourceRootOffset.match(() => const <_PeResourceLeaf>[], (
    resourceRootOffset,
  ) {
    final leaves = <_PeResourceLeaf>[];
    for (final entry in _peResourceDirectoryEntries(
      image.bytes,
      directoryOffset,
    )) {
      final nextIds = entry.id == null ? ids : <int>[...ids, entry.id!];
      if (entry.isDirectory) {
        leaves.addAll(
          _peResourceLeavesFromDirectory(
            image: image,
            directoryOffset: resourceRootOffset + entry.targetOffset,
            ids: nextIds,
          ),
        );
        continue;
      }

      final dataEntryOffset = resourceRootOffset + entry.targetOffset;
      final dataRva = _readUint32(image.bytes, dataEntryOffset);
      final size = _readUint32(image.bytes, dataEntryOffset + 4);
      if (dataRva == null || size == null) {
        continue;
      }
      image.rawOffsetForRva(dataRva).match(() {}, (dataOffset) {
        if (dataOffset + size > image.bytes.length) {
          return;
        }

        leaves.add(
          _PeResourceLeaf(
            ids: nextIds,
            data: Uint8List.sublistView(
              image.bytes,
              dataOffset,
              dataOffset + size,
            ),
          ),
        );
      });
    }

    return List.unmodifiable(leaves);
  });
}

List<_PeResourceDirectoryEntry> _peResourceDirectoryEntries(
  Uint8List bytes,
  int directoryOffset,
) {
  final namedEntryCount = _readUint16(bytes, directoryOffset + 12);
  final idEntryCount = _readUint16(bytes, directoryOffset + 14);
  if (namedEntryCount == null || idEntryCount == null) {
    return const <_PeResourceDirectoryEntry>[];
  }

  final entries = <_PeResourceDirectoryEntry>[];
  final entryCount = namedEntryCount + idEntryCount;
  final maximumEntryCount = (bytes.length - (directoryOffset + 16)) ~/ 8;
  if (entryCount < 0 || entryCount > maximumEntryCount) {
    return const <_PeResourceDirectoryEntry>[];
  }
  for (var index = 0; index < entryCount; index += 1) {
    final offset = directoryOffset + 16 + index * 8;
    final nameOrId = _readUint32(bytes, offset);
    final offsetToData = _readUint32(bytes, offset + 4);
    if (nameOrId == null || offsetToData == null) {
      continue;
    }

    entries.add(
      _PeResourceDirectoryEntry(
        id: nameOrId & 0x80000000 == 0 ? nameOrId & 0xffff : null,
        isDirectory: offsetToData & 0x80000000 != 0,
        targetOffset: offsetToData & 0x7fffffff,
      ),
    );
  }

  return List.unmodifiable(entries);
}

final class _PeResourceDirectoryEntry {
  const _PeResourceDirectoryEntry({
    required this.id,
    required this.isDirectory,
    required this.targetOffset,
  });

  final int? id;
  final bool isDirectory;
  final int targetOffset;
}

final class _PeResourceLeaf {
  const _PeResourceLeaf({required this.ids, required this.data});

  final List<int> ids;
  final Uint8List data;
}
