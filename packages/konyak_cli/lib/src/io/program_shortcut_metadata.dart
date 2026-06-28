part of '../../konyak_cli.dart';

List<_BottleProgramSource> _bottleStartMenuSources(BottleRecord bottle) {
  return <_BottleProgramSource>[
    _BottleProgramSource(
      id: 'globalStartMenu',
      path: _joinPath(bottle.path.value, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
      ]),
    ),
    _BottleProgramSource(
      id: 'userStartMenu',
      path: _joinPath(bottle.path.value, const [
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
  _BottleProgramSource({required String id, required String path})
    : id = ProgramSource(id),
      path = ProgramPath(path);

  final ProgramSource id;
  final ProgramPath path;
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
  return _readUint32Option(bytes, 0).flatMap(
    (headerSize) => headerSize == shellLinkHeaderSize
        ? _readUint32Option(bytes, 0x14).flatMap(
            (linkFlags) =>
                _shellLinkLinkInfoOffset(
                  bytes: bytes,
                  linkFlags: linkFlags,
                ).flatMap(
                  (offset) => _shellLinkLocalBasePathAtLinkInfoOffset(
                    bytes: bytes,
                    offset: offset,
                  ),
                ),
          )
        : const Option.none(),
  );
}

Option<int> _shellLinkLinkInfoOffset({
  required Uint8List bytes,
  required int linkFlags,
}) {
  const shellLinkHeaderSize = 0x4c;
  if (linkFlags & 0x00000002 == 0) {
    return const Option.none();
  }

  if (linkFlags & 0x00000001 == 0) {
    return Option.of(shellLinkHeaderSize);
  }

  return _readUint16Option(
    bytes,
    shellLinkHeaderSize,
  ).map((idListSize) => shellLinkHeaderSize + 2 + idListSize);
}

Option<String> _shellLinkLocalBasePathAtLinkInfoOffset({
  required Uint8List bytes,
  required int offset,
}) {
  return _readUint32Option(bytes, offset).flatMap(
    (linkInfoSize) => _readUint32Option(bytes, offset + 4).flatMap(
      (linkInfoHeaderSize) => _readUint32Option(bytes, offset + 16).flatMap(
        (localBasePathOffset) => _shellLinkLocalBasePathFromLinkInfo(
          bytes: bytes,
          offset: offset,
          linkInfoSize: linkInfoSize,
          linkInfoHeaderSize: linkInfoHeaderSize,
          localBasePathOffset: localBasePathOffset,
        ),
      ),
    ),
  );
}

Option<String> _shellLinkLocalBasePathFromLinkInfo({
  required Uint8List bytes,
  required int offset,
  required int linkInfoSize,
  required int linkInfoHeaderSize,
  required int localBasePathOffset,
}) {
  if (linkInfoSize <= 0 || offset + linkInfoSize > bytes.length) {
    return const Option.none();
  }

  final unicodePath = linkInfoHeaderSize >= 0x24
      ? _readUint32Option(bytes, offset + 28).flatMap(
          (localBasePathUnicodeOffset) => localBasePathUnicodeOffset > 0
              ? _nullTerminatedUtf16LeStringOption(
                  bytes,
                  offset + localBasePathUnicodeOffset,
                  offset + linkInfoSize,
                )
              : const Option<String>.none(),
        )
      : const Option<String>.none();

  return unicodePath.match(
    () => _nullTerminatedAsciiStringOption(
      bytes,
      offset + localBasePathOffset,
      offset + linkInfoSize,
    ),
    Option<String>.of,
  );
}
