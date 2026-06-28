import 'dart:typed_data';

import 'external_payload_helpers.dart';
import 'pe_program_image.dart';

List<PeResourceLeaf> peResourceLeaves(
  PortableExecutableImage image,
  int typeId,
) {
  return image.resourceRootOffset.match(() => const <PeResourceLeaf>[], (
    resourceRootOffset,
  ) {
    final rootEntries = peResourceDirectoryEntries(
      image.bytes,
      resourceRootOffset,
    );
    for (final entry in rootEntries) {
      if (entry.id != typeId || !entry.isDirectory) {
        continue;
      }

      return peResourceLeavesFromDirectory(
        image: image,
        directoryOffset: resourceRootOffset + entry.targetOffset,
        ids: const <int>[],
      );
    }

    return const <PeResourceLeaf>[];
  });
}

List<PeResourceLeaf> peResourceLeavesFromDirectory({
  required PortableExecutableImage image,
  required int directoryOffset,
  required List<int> ids,
}) {
  return image.resourceRootOffset.match(() => const <PeResourceLeaf>[], (
    resourceRootOffset,
  ) {
    final leaves = <PeResourceLeaf>[];
    for (final entry in peResourceDirectoryEntries(
      image.bytes,
      directoryOffset,
    )) {
      final nextIds = entry.id == null ? ids : <int>[...ids, entry.id!];
      if (entry.isDirectory) {
        leaves.addAll(
          peResourceLeavesFromDirectory(
            image: image,
            directoryOffset: resourceRootOffset + entry.targetOffset,
            ids: nextIds,
          ),
        );
        continue;
      }

      final dataEntryOffset = resourceRootOffset + entry.targetOffset;
      final dataRva = readUint32(image.bytes, dataEntryOffset);
      final size = readUint32(image.bytes, dataEntryOffset + 4);
      if (dataRva == null || size == null) {
        continue;
      }
      image.rawOffsetForRva(dataRva).match(() {}, (dataOffset) {
        if (dataOffset + size > image.bytes.length) {
          return;
        }

        leaves.add(
          PeResourceLeaf(
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

List<PeResourceDirectoryEntry> peResourceDirectoryEntries(
  Uint8List bytes,
  int directoryOffset,
) {
  final namedEntryCount = readUint16(bytes, directoryOffset + 12);
  final idEntryCount = readUint16(bytes, directoryOffset + 14);
  if (namedEntryCount == null || idEntryCount == null) {
    return const <PeResourceDirectoryEntry>[];
  }

  final entries = <PeResourceDirectoryEntry>[];
  final entryCount = namedEntryCount + idEntryCount;
  final maximumEntryCount = (bytes.length - (directoryOffset + 16)) ~/ 8;
  if (entryCount < 0 || entryCount > maximumEntryCount) {
    return const <PeResourceDirectoryEntry>[];
  }
  for (var index = 0; index < entryCount; index += 1) {
    final offset = directoryOffset + 16 + index * 8;
    final nameOrId = readUint32(bytes, offset);
    final offsetToData = readUint32(bytes, offset + 4);
    if (nameOrId == null || offsetToData == null) {
      continue;
    }

    entries.add(
      PeResourceDirectoryEntry(
        id: nameOrId & 0x80000000 == 0 ? nameOrId & 0xffff : null,
        isDirectory: offsetToData & 0x80000000 != 0,
        targetOffset: offsetToData & 0x7fffffff,
      ),
    );
  }

  return List.unmodifiable(entries);
}

final class PeResourceDirectoryEntry {
  const PeResourceDirectoryEntry({
    required this.id,
    required this.isDirectory,
    required this.targetOffset,
  });

  final int? id;
  final bool isDirectory;
  final int targetOffset;
}

final class PeResourceLeaf {
  const PeResourceLeaf({required this.ids, required this.data});

  final List<int> ids;
  final Uint8List data;
}
