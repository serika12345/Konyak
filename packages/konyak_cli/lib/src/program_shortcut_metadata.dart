part of '../konyak_cli.dart';

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

String? _shortcutTargetProgramPath({
  required BottleRecord bottle,
  required String shortcutPath,
}) {
  try {
    final bytes = File(shortcutPath).readAsBytesSync();
    final windowsPath = _shellLinkLocalBasePath(bytes);
    if (windowsPath == null) {
      return null;
    }

    return _wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath);
  } on FileSystemException {
    return null;
  } on RangeError {
    return null;
  }
}

String _metadataProgramPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  if (!_isShortcutPath(programPath)) {
    return programPath;
  }

  return _shortcutTargetProgramPath(
        bottle: bottle,
        shortcutPath: programPath,
      ) ??
      programPath;
}

String? _shellLinkLocalBasePath(Uint8List bytes) {
  const shellLinkHeaderSize = 0x4c;
  final headerSize = _readUint32(bytes, 0);
  final linkFlags = _readUint32(bytes, 0x14);
  if (headerSize != shellLinkHeaderSize || linkFlags == null) {
    return null;
  }

  var offset = shellLinkHeaderSize;
  if (linkFlags & 0x00000001 != 0) {
    final idListSize = _readUint16(bytes, offset);
    if (idListSize == null) {
      return null;
    }
    offset += 2 + idListSize;
  }

  if (linkFlags & 0x00000002 == 0) {
    return null;
  }

  final linkInfoSize = _readUint32(bytes, offset);
  final linkInfoHeaderSize = _readUint32(bytes, offset + 4);
  final localBasePathOffset = _readUint32(bytes, offset + 16);
  if (linkInfoSize == null ||
      linkInfoHeaderSize == null ||
      localBasePathOffset == null ||
      linkInfoSize <= 0 ||
      offset + linkInfoSize > bytes.length) {
    return null;
  }

  if (linkInfoHeaderSize >= 0x24) {
    final localBasePathUnicodeOffset = _readUint32(bytes, offset + 28);
    if (localBasePathUnicodeOffset != null && localBasePathUnicodeOffset > 0) {
      return _nullTerminatedUtf16LeString(
        bytes,
        offset + localBasePathUnicodeOffset,
        offset + linkInfoSize,
      );
    }
  }

  return _nullTerminatedAsciiString(
    bytes,
    offset + localBasePathOffset,
    offset + linkInfoSize,
  );
}
