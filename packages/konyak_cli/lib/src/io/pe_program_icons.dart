import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../shared/common_helpers.dart';
import 'external_payload_helpers.dart';
import 'pe_program_image.dart';
import 'pe_program_resources.dart';

Option<Uint8List> peIconBytes(PortableExecutableImage image) {
  final groupResources = peResourceLeaves(image, 14);
  if (groupResources.isEmpty) {
    return const Option.none();
  }

  final iconResources = <int, Uint8List>{};
  for (final resource in peResourceLeaves(image, 3)) {
    if (resource.ids.isEmpty) {
      continue;
    }
    iconResources.putIfAbsent(resource.ids.first, () => resource.data);
  }

  for (final group in groupResources) {
    final icon = icoFromGroupIconResource(
      group.data,
      iconResources: iconResources,
    );
    if (icon.isSome()) {
      return icon;
    }
  }

  return const Option.none();
}

String peIconCachePath({
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) {
  final cacheKey = sha256
      .convert(
        utf8.encode(
          '$programPath|${fileStat.size}|'
          '${fileStat.modified.millisecondsSinceEpoch}',
        ),
      )
      .toString()
      .substring(0, 24);
  return joinPath(bottle.path.value, ['cache', 'icons', '$cacheKey.ico']);
}

Option<Uint8List> icoFromGroupIconResource(
  Uint8List groupData, {
  required Map<int, Uint8List> iconResources,
}) {
  return readUint16Option(groupData, 4).flatMap((count) {
    if (count <= 0 || groupData.length < 6 + count * 14) {
      return const Option.none();
    }

    final entriesResult = icoImageEntries(
      groupData: groupData,
      iconResources: iconResources,
      count: count,
      index: 0,
    );
    return switch (entriesResult) {
      IcoImageEntriesInvalid() => const Option.none(),
      IcoImageEntriesResolved(:final entries) =>
        entries.isEmpty
            ? const Option.none()
            : Option.of(icoBytesFromEntries(entries)),
    };
  });
}

Uint8List icoBytesFromEntries(List<IcoImageEntry> entries) {
  final headerLength = 6 + entries.length * 16;
  final header = Uint8List.fromList(<int>[
    0,
    0,
    ...uint16LeBytes(1),
    ...uint16LeBytes(entries.length),
    for (final (index, entry) in entries.indexed) ...<int>[
      entry.width,
      entry.height,
      entry.colorCount,
      0,
      ...uint16LeBytes(entry.planes),
      ...uint16LeBytes(entry.bitCount),
      ...uint32LeBytes(entry.data.length),
      ...uint32LeBytes(
        icoImageDataOffset(
          entries: entries,
          entryIndex: index,
          headerLength: headerLength,
        ),
      ),
    ],
  ]);

  final output = BytesBuilder(copy: false)..add(header);
  for (final entry in entries) {
    output.add(entry.data);
  }

  return output.takeBytes();
}

IcoImageEntriesReadResult icoImageEntries({
  required Uint8List groupData,
  required Map<int, Uint8List> iconResources,
  required int count,
  required int index,
}) {
  if (index >= count) {
    return const IcoImageEntriesResolved(<IcoImageEntry>[]);
  }

  return switch (icoImageEntryAtIndex(
    groupData: groupData,
    iconResources: iconResources,
    index: index,
  )) {
    IcoImageEntryInvalid() => const IcoImageEntriesInvalid(),
    IcoImageEntryMissingIconResource() => icoImageEntries(
      groupData: groupData,
      iconResources: iconResources,
      count: count,
      index: index + 1,
    ),
    IcoImageEntryFound(:final entry) => (() {
      final remaining = icoImageEntries(
        groupData: groupData,
        iconResources: iconResources,
        count: count,
        index: index + 1,
      );
      return switch (remaining) {
        IcoImageEntriesInvalid() => const IcoImageEntriesInvalid(),
        IcoImageEntriesResolved(:final entries) => IcoImageEntriesResolved(
          <IcoImageEntry>[entry, ...entries],
        ),
      };
    })(),
  };
}

IcoImageEntryReadResult icoImageEntryAtIndex({
  required Uint8List groupData,
  required Map<int, Uint8List> iconResources,
  required int index,
}) {
  final offset = 6 + index * 14;
  return readUint32Option(groupData, offset + 8).match(
    () => const IcoImageEntryInvalid(),
    (_) => readUint16Option(groupData, offset + 12).match(
      () => const IcoImageEntryInvalid(),
      (iconId) => nullableOption(iconResources[iconId]).match(
        () => const IcoImageEntryMissingIconResource(),
        (iconData) => IcoImageEntryFound(
          IcoImageEntry(
            width: groupData[offset],
            height: groupData[offset + 1],
            colorCount: groupData[offset + 2],
            planes: readUint16Option(
              groupData,
              offset + 4,
            ).match(() => 0, (value) => value),
            bitCount: readUint16Option(
              groupData,
              offset + 6,
            ).match(() => 0, (value) => value),
            data: iconData,
          ),
        ),
      ),
    ),
  );
}

int icoImageDataOffset({
  required List<IcoImageEntry> entries,
  required int entryIndex,
  required int headerLength,
}) {
  return headerLength +
      entries
          .take(entryIndex)
          .fold(0, (offset, entry) => offset + entry.data.length);
}

List<int> uint16LeBytes(int value) {
  return <int>[value & 0xff, value >> 8 & 0xff];
}

List<int> uint32LeBytes(int value) {
  return <int>[
    value & 0xff,
    value >> 8 & 0xff,
    value >> 16 & 0xff,
    value >> 24 & 0xff,
  ];
}

sealed class IcoImageEntryReadResult {
  const IcoImageEntryReadResult();
}

sealed class IcoImageEntriesReadResult {
  const IcoImageEntriesReadResult();
}

final class IcoImageEntriesInvalid extends IcoImageEntriesReadResult {
  const IcoImageEntriesInvalid();
}

final class IcoImageEntriesResolved extends IcoImageEntriesReadResult {
  const IcoImageEntriesResolved(this.entries);

  final List<IcoImageEntry> entries;
}

final class IcoImageEntryInvalid extends IcoImageEntryReadResult {
  const IcoImageEntryInvalid();
}

final class IcoImageEntryMissingIconResource extends IcoImageEntryReadResult {
  const IcoImageEntryMissingIconResource();
}

final class IcoImageEntryFound extends IcoImageEntryReadResult {
  const IcoImageEntryFound(this.entry);

  final IcoImageEntry entry;
}

final class IcoImageEntry {
  const IcoImageEntry({
    required this.width,
    required this.height,
    required this.colorCount,
    required this.planes,
    required this.bitCount,
    required this.data,
  });

  final int width;
  final int height;
  final int colorCount;
  final int planes;
  final int bitCount;
  final Uint8List data;
}
