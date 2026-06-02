part of '../konyak_cli.dart';

Uint8List? _peIconBytes(_PortableExecutableImage image) {
  final groupResources = _peResourceLeaves(image, 14);
  if (groupResources.isEmpty) {
    return null;
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
    if (icon != null) {
      return icon;
    }
  }

  return null;
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
  return _joinPath(bottle.path, ['cache', 'icons', '$cacheKey.ico']);
}

Uint8List? _icoFromGroupIconResource(
  Uint8List groupData, {
  required Map<int, Uint8List> iconResources,
}) {
  final count = _readUint16(groupData, 4);
  if (count == null || count <= 0 || groupData.length < 6 + count * 14) {
    return null;
  }

  final entries = <_IcoImageEntry>[];
  for (var index = 0; index < count; index += 1) {
    final offset = 6 + index * 14;
    final bytesInResource = _readUint32(groupData, offset + 8);
    final iconId = _readUint16(groupData, offset + 12);
    if (bytesInResource == null || iconId == null) {
      return null;
    }
    final iconData = iconResources[iconId];
    if (iconData == null) {
      continue;
    }

    entries.add(
      _IcoImageEntry(
        width: groupData[offset],
        height: groupData[offset + 1],
        colorCount: groupData[offset + 2],
        planes: _readUint16(groupData, offset + 4) ?? 0,
        bitCount: _readUint16(groupData, offset + 6) ?? 0,
        data: iconData,
      ),
    );
  }

  if (entries.isEmpty) {
    return null;
  }

  final header = Uint8List(6 + entries.length * 16);
  _writeUint16(header, 2, 1);
  _writeUint16(header, 4, entries.length);

  var imageOffset = header.length;
  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    final offset = 6 + index * 16;
    header[offset] = entry.width;
    header[offset + 1] = entry.height;
    header[offset + 2] = entry.colorCount;
    _writeUint16(header, offset + 4, entry.planes);
    _writeUint16(header, offset + 6, entry.bitCount);
    _writeUint32(header, offset + 8, entry.data.length);
    _writeUint32(header, offset + 12, imageOffset);
    imageOffset += entry.data.length;
  }

  final output = BytesBuilder(copy: false)..add(header);
  for (final entry in entries) {
    output.add(entry.data);
  }

  return output.takeBytes();
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
