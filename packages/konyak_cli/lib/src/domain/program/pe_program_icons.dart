part of '../../../konyak_cli.dart';

Option<Uint8List> _peIconBytes(_PortableExecutableImage image) {
  final groupResources = _peResourceLeaves(image, 14);
  if (groupResources.isEmpty) {
    return const Option.none();
  }

  final iconResources = <int, Uint8List>{};
  for (final resource in _peResourceLeaves(image, 3)) {
    if (resource.ids.isEmpty) {
      continue;
    }
    iconResources.putIfAbsent(resource.ids.first, () => resource.data);
  }

  for (final group in groupResources) {
    final icon = _icoFromGroupIconResource(
      group.data,
      iconResources: iconResources,
    );
    if (icon.isSome()) {
      return icon;
    }
  }

  return const Option.none();
}

String _peIconCachePath({
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
  return _joinPath(bottle.path.value, ['cache', 'icons', '$cacheKey.ico']);
}

Option<Uint8List> _icoFromGroupIconResource(
  Uint8List groupData, {
  required Map<int, Uint8List> iconResources,
}) {
  return _readUint16Option(groupData, 4).flatMap((count) {
    if (count <= 0 || groupData.length < 6 + count * 14) {
      return const Option.none();
    }

    final entriesResult = _icoImageEntries(
      groupData: groupData,
      iconResources: iconResources,
      count: count,
      index: 0,
    );
    return switch (entriesResult) {
      _IcoImageEntriesInvalid() => const Option.none(),
      _IcoImageEntriesResolved(:final entries) =>
        entries.isEmpty
            ? const Option.none()
            : Option.of(_icoBytesFromEntries(entries)),
    };
  });
}

Uint8List _icoBytesFromEntries(List<_IcoImageEntry> entries) {
  final headerLength = 6 + entries.length * 16;
  final header = Uint8List.fromList(<int>[
    0,
    0,
    ..._uint16LeBytes(1),
    ..._uint16LeBytes(entries.length),
    for (final (index, entry) in entries.indexed) ...<int>[
      entry.width,
      entry.height,
      entry.colorCount,
      0,
      ..._uint16LeBytes(entry.planes),
      ..._uint16LeBytes(entry.bitCount),
      ..._uint32LeBytes(entry.data.length),
      ..._uint32LeBytes(
        _icoImageDataOffset(
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

_IcoImageEntriesReadResult _icoImageEntries({
  required Uint8List groupData,
  required Map<int, Uint8List> iconResources,
  required int count,
  required int index,
}) {
  if (index >= count) {
    return const _IcoImageEntriesResolved(<_IcoImageEntry>[]);
  }

  return switch (_icoImageEntryAtIndex(
    groupData: groupData,
    iconResources: iconResources,
    index: index,
  )) {
    _IcoImageEntryInvalid() => const _IcoImageEntriesInvalid(),
    _IcoImageEntryMissingIconResource() => _icoImageEntries(
      groupData: groupData,
      iconResources: iconResources,
      count: count,
      index: index + 1,
    ),
    _IcoImageEntryFound(:final entry) => (() {
      final remaining = _icoImageEntries(
        groupData: groupData,
        iconResources: iconResources,
        count: count,
        index: index + 1,
      );
      return switch (remaining) {
        _IcoImageEntriesInvalid() => const _IcoImageEntriesInvalid(),
        _IcoImageEntriesResolved(:final entries) => _IcoImageEntriesResolved(
          <_IcoImageEntry>[entry, ...entries],
        ),
      };
    })(),
  };
}

_IcoImageEntryReadResult _icoImageEntryAtIndex({
  required Uint8List groupData,
  required Map<int, Uint8List> iconResources,
  required int index,
}) {
  final offset = 6 + index * 14;
  return _readUint32Option(groupData, offset + 8).match(
    () => const _IcoImageEntryInvalid(),
    (_) => _readUint16Option(groupData, offset + 12).match(
      () => const _IcoImageEntryInvalid(),
      (iconId) => _nullableOption(iconResources[iconId]).match(
        () => const _IcoImageEntryMissingIconResource(),
        (iconData) => _IcoImageEntryFound(
          _IcoImageEntry(
            width: groupData[offset],
            height: groupData[offset + 1],
            colorCount: groupData[offset + 2],
            planes: _readUint16Option(
              groupData,
              offset + 4,
            ).match(() => 0, (value) => value),
            bitCount: _readUint16Option(
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

int _icoImageDataOffset({
  required List<_IcoImageEntry> entries,
  required int entryIndex,
  required int headerLength,
}) {
  return headerLength +
      entries
          .take(entryIndex)
          .fold(0, (offset, entry) => offset + entry.data.length);
}

List<int> _uint16LeBytes(int value) {
  return <int>[value & 0xff, value >> 8 & 0xff];
}

List<int> _uint32LeBytes(int value) {
  return <int>[
    value & 0xff,
    value >> 8 & 0xff,
    value >> 16 & 0xff,
    value >> 24 & 0xff,
  ];
}

sealed class _IcoImageEntryReadResult {
  const _IcoImageEntryReadResult();
}

sealed class _IcoImageEntriesReadResult {
  const _IcoImageEntriesReadResult();
}

final class _IcoImageEntriesInvalid extends _IcoImageEntriesReadResult {
  const _IcoImageEntriesInvalid();
}

final class _IcoImageEntriesResolved extends _IcoImageEntriesReadResult {
  const _IcoImageEntriesResolved(this.entries);

  final List<_IcoImageEntry> entries;
}

final class _IcoImageEntryInvalid extends _IcoImageEntryReadResult {
  const _IcoImageEntryInvalid();
}

final class _IcoImageEntryMissingIconResource extends _IcoImageEntryReadResult {
  const _IcoImageEntryMissingIconResource();
}

final class _IcoImageEntryFound extends _IcoImageEntryReadResult {
  const _IcoImageEntryFound(this.entry);

  final _IcoImageEntry entry;
}

final class _IcoImageEntry {
  const _IcoImageEntry({
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
