part of '../../../konyak_cli.dart';

List<_BottleProgramSource> _bottleStartMenuSources(BottleRecord bottle) {
  return <_BottleProgramSource>[
    _BottleProgramSource(
      id: 'globalStartMenu',
      path: _joinPath(bottle.path, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
      ]),
    ),
    _BottleProgramSource(
      id: 'userStartMenu',
      path: _joinPath(bottle.path, const [
        'drive_c',
        'users',
        'crossover',
        'AppData',
        'Roaming',
        'Microsoft',
        'Windows',
        'Start Menu',
      ]),
    ),
  ];
}

class _BottleProgramSource {
  const _BottleProgramSource({required this.id, required this.path});

  final String id;
  final String path;
}

bool _isShortcutPath(String path) {
  return path.toLowerCase().endsWith('.lnk') &&
      !_baseName(path).startsWith('.');
}

String _shortcutProgramName(String path) {
  final baseName = _baseName(path);
  final extensionStart = baseName.toLowerCase().lastIndexOf('.lnk');
  if (extensionStart <= 0) {
    return baseName;
  }

  return baseName.substring(0, extensionStart);
}

Option<String> _shortcutTargetProgramPathFromBytes({
  required BottleRecord bottle,
  required Uint8List bytes,
}) {
  try {
    return _shellLinkLocalBasePath(bytes).flatMap(
      (windowsPath) =>
          _wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath),
    );
  } on RangeError {
    return const Option.none();
  }
}

Option<String> _shellLinkLocalBasePath(Uint8List bytes) {
  const shellLinkHeaderSize = 0x4c;
  final headerSize = _readUint32(bytes, 0);
  final linkFlags = _readUint32(bytes, 0x14);
  if (headerSize != shellLinkHeaderSize || linkFlags == null) {
    return const Option.none();
  }

  var offset = shellLinkHeaderSize;
  if (linkFlags & 0x00000001 != 0) {
    final idListSize = _readUint16(bytes, offset);
    if (idListSize == null) {
      return const Option.none();
    }
    offset += 2 + idListSize;
  }

  if (linkFlags & 0x00000002 == 0) {
    return const Option.none();
  }

  final linkInfoSize = _readUint32(bytes, offset);
  final linkInfoHeaderSize = _readUint32(bytes, offset + 4);
  final localBasePathOffset = _readUint32(bytes, offset + 16);
  if (linkInfoSize == null ||
      linkInfoHeaderSize == null ||
      localBasePathOffset == null ||
      linkInfoSize <= 0 ||
      offset + linkInfoSize > bytes.length) {
    return const Option.none();
  }

  if (linkInfoHeaderSize >= 0x24) {
    final localBasePathUnicodeOffset = _readUint32(bytes, offset + 28);
    if (localBasePathUnicodeOffset != null && localBasePathUnicodeOffset > 0) {
      return Option.fromNullable(
        _nullTerminatedUtf16LeString(
          bytes,
          offset + localBasePathUnicodeOffset,
          offset + linkInfoSize,
        ),
      );
    }
  }

  return Option.fromNullable(
    _nullTerminatedAsciiString(
      bytes,
      offset + localBasePathOffset,
      offset + linkInfoSize,
    ),
  );
}
