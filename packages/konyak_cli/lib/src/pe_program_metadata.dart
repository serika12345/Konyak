part of '../konyak_cli.dart';

String _uniqueProgramId({
  required String baseId,
  required List<BottleProgramRecord> existing,
}) {
  final fallbackBaseId = baseId.isEmpty ? 'program' : baseId;
  if (existing.every((program) => program.id != fallbackBaseId)) {
    return fallbackBaseId;
  }

  var suffix = 2;
  while (existing.any((program) => program.id == '$fallbackBaseId-$suffix')) {
    suffix += 1;
  }

  return '$fallbackBaseId-$suffix';
}

String? _extractPeIcon({
  required _PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) {
  final icoBytes = _peIconBytes(image);
  if (icoBytes == null) {
    return null;
  }

  final cacheKey = sha256
      .convert(
        utf8.encode(
          '$programPath|${fileStat.size}|'
          '${fileStat.modified.millisecondsSinceEpoch}',
        ),
      )
      .toString()
      .substring(0, 24);
  final iconPath = _joinPath(bottle.path, ['cache', 'icons', '$cacheKey.ico']);

  try {
    final iconFile = File(iconPath);
    iconFile.parent.createSync(recursive: true);
    iconFile.writeAsBytesSync(icoBytes);

    return iconPath;
  } on FileSystemException {
    return null;
  }
}

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

Map<String, String> _peVersionStrings(_PortableExecutableImage image) {
  final resources = _peResourceLeaves(image, 16);
  final values = <String, String>{};
  for (final resource in resources) {
    final strings = _utf16LeTokens(resource.data);
    for (final key in const <String>[
      'FileDescription',
      'ProductName',
      'CompanyName',
      'FileVersion',
      'ProductVersion',
    ]) {
      values.putIfAbsent(key, () => _valueAfterToken(strings, key) ?? '');
      if (values[key] == '') {
        values.remove(key);
      }
    }
  }

  return Map.unmodifiable(values);
}

String? _valueAfterToken(List<String> values, String key) {
  final knownKeys = const <String>{
    'FileDescription',
    'ProductName',
    'CompanyName',
    'FileVersion',
    'ProductVersion',
  };
  for (var index = 0; index < values.length; index += 1) {
    if (values[index] != key) {
      continue;
    }
    for (
      var valueIndex = index + 1;
      valueIndex < values.length;
      valueIndex += 1
    ) {
      final value = values[valueIndex];
      if (knownKeys.contains(value)) {
        break;
      }
      if (value.isNotEmpty) {
        return value;
      }
    }
  }

  return null;
}

List<String> _utf16LeTokens(Uint8List bytes) {
  final codeUnits = <int>[];
  for (var offset = 0; offset + 1 < bytes.length; offset += 2) {
    codeUnits.add(_readUint16(bytes, offset) ?? 0);
  }

  return String.fromCharCodes(codeUnits)
      .split('\u0000')
      .map((value) => value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String? _nullTerminatedAsciiString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final endOffset = _nullByteOffset(bytes, offset, maximumOffset);
  if (endOffset == null) {
    return null;
  }

  return ascii.decode(
    Uint8List.sublistView(bytes, offset, endOffset),
    allowInvalid: true,
  );
}

String? _nullTerminatedUtf16LeString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset + 1 >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final codeUnits = <int>[];
  for (var cursor = offset; cursor + 1 < maximumOffset; cursor += 2) {
    final codeUnit = _readUint16(bytes, cursor);
    if (codeUnit == null || codeUnit == 0) {
      break;
    }
    codeUnits.add(codeUnit);
  }

  return codeUnits.isEmpty ? null : String.fromCharCodes(codeUnits);
}

int? _nullByteOffset(Uint8List bytes, int offset, int maximumOffset) {
  final boundedMaximum = min(maximumOffset, bytes.length);
  for (var cursor = offset; cursor < boundedMaximum; cursor += 1) {
    if (bytes[cursor] == 0) {
      return cursor;
    }
  }

  return null;
}

List<_PeResourceLeaf> _peResourceLeaves(
  _PortableExecutableImage image,
  int typeId,
) {
  final resourceRootOffset = image.resourceRootOffset;
  if (resourceRootOffset == null) {
    return const <_PeResourceLeaf>[];
  }

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
}

List<_PeResourceLeaf> _peResourceLeavesFromDirectory({
  required _PortableExecutableImage image,
  required int directoryOffset,
  required List<int> ids,
}) {
  final resourceRootOffset = image.resourceRootOffset;
  if (resourceRootOffset == null) {
    return const <_PeResourceLeaf>[];
  }

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
    final dataOffset = image.rawOffsetForRva(dataRva);
    if (dataOffset == null || dataOffset + size > image.bytes.length) {
      continue;
    }

    leaves.add(
      _PeResourceLeaf(
        ids: nextIds,
        data: Uint8List.sublistView(image.bytes, dataOffset, dataOffset + size),
      ),
    );
  }

  return List.unmodifiable(leaves);
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

final class _PortableExecutableImage {
  const _PortableExecutableImage({
    required this.bytes,
    required this.machine,
    required this.sections,
    required this.resourceRva,
    required this.resourceRootOffset,
  });

  final Uint8List bytes;
  final int machine;
  final List<_PeSection> sections;
  final int? resourceRva;
  final int? resourceRootOffset;

  String? get architecture {
    return switch (machine) {
      0x014c => 'x86',
      0x8664 => 'x86_64',
      0xaa64 => 'arm64',
      0x01c4 => 'arm',
      _ => null,
    };
  }

  int? rawOffsetForRva(int rva) {
    for (final section in sections) {
      final sectionSize = max(section.virtualSize, section.rawSize);
      if (rva >= section.virtualAddress &&
          rva < section.virtualAddress + sectionSize) {
        return section.rawOffset + (rva - section.virtualAddress);
      }
    }

    return null;
  }

  static _PortableExecutableImage? parse(Uint8List bytes) {
    if (bytes.length < 0x40 || bytes[0] != 0x4d || bytes[1] != 0x5a) {
      return null;
    }

    final peOffset = _readUint32(bytes, 0x3c);
    if (peOffset == null ||
        peOffset + 24 > bytes.length ||
        bytes[peOffset] != 0x50 ||
        bytes[peOffset + 1] != 0x45 ||
        bytes[peOffset + 2] != 0x00 ||
        bytes[peOffset + 3] != 0x00) {
      return null;
    }

    final machine = _readUint16(bytes, peOffset + 4);
    final sectionCount = _readUint16(bytes, peOffset + 6);
    final optionalHeaderSize = _readUint16(bytes, peOffset + 20);
    if (machine == null ||
        sectionCount == null ||
        optionalHeaderSize == null ||
        optionalHeaderSize < 2) {
      return null;
    }

    final optionalHeaderOffset = peOffset + 24;
    final magic = _readUint16(bytes, optionalHeaderOffset);
    final dataDirectoryOffset = switch (magic) {
      0x010b => optionalHeaderOffset + 96,
      0x020b => optionalHeaderOffset + 112,
      _ => null,
    };
    if (dataDirectoryOffset == null) {
      return null;
    }

    final resourceDirectoryOffset = dataDirectoryOffset + 8 * 2;
    final resourceRva = _readUint32(bytes, resourceDirectoryOffset);
    final sectionHeaderOffset = optionalHeaderOffset + optionalHeaderSize;
    final sections = <_PeSection>[];
    for (var index = 0; index < sectionCount; index += 1) {
      final offset = sectionHeaderOffset + index * 40;
      if (offset + 40 > bytes.length) {
        return null;
      }

      final virtualSize = _readUint32(bytes, offset + 8);
      final virtualAddress = _readUint32(bytes, offset + 12);
      final rawSize = _readUint32(bytes, offset + 16);
      final rawOffset = _readUint32(bytes, offset + 20);
      if (virtualSize == null ||
          virtualAddress == null ||
          rawSize == null ||
          rawOffset == null) {
        return null;
      }
      sections.add(
        _PeSection(
          virtualSize: virtualSize,
          virtualAddress: virtualAddress,
          rawSize: rawSize,
          rawOffset: rawOffset,
        ),
      );
    }

    final image = _PortableExecutableImage(
      bytes: bytes,
      machine: machine,
      sections: List.unmodifiable(sections),
      resourceRva: resourceRva,
      resourceRootOffset: null,
    );

    return _PortableExecutableImage(
      bytes: bytes,
      machine: machine,
      sections: List.unmodifiable(sections),
      resourceRva: resourceRva,
      resourceRootOffset: resourceRva == null
          ? null
          : image.rawOffsetForRva(resourceRva),
    );
  }
}

final class _PeSection {
  const _PeSection({
    required this.virtualSize,
    required this.virtualAddress,
    required this.rawSize,
    required this.rawOffset,
  });

  final int virtualSize;
  final int virtualAddress;
  final int rawSize;
  final int rawOffset;
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
