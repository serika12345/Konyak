import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import 'external_payload_helpers.dart';
import 'wine_process_metadata.dart';

List<BottleProgramSource> bottleStartMenuSources(BottleRecord bottle) {
  return <BottleProgramSource>[
    BottleProgramSource(
      id: 'globalStartMenu',
      path: joinPath(bottle.path.value, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
      ]),
    ),
    BottleProgramSource(
      id: 'userStartMenu',
      path: joinPath(bottle.path.value, const [
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

class BottleProgramSource {
  BottleProgramSource({required String id, required String path})
    : id = ProgramSource(id),
      path = ProgramPath(path);

  final ProgramSource id;
  final ProgramPath path;
}

bool isShortcutPath(String path) {
  return path.toLowerCase().endsWith('.lnk') && !baseName(path).startsWith('.');
}

String shortcutProgramName(String path) {
  final shortcutBaseName = baseName(path);
  final extensionStart = shortcutBaseName.toLowerCase().lastIndexOf('.lnk');
  if (extensionStart <= 0) {
    return shortcutBaseName;
  }

  return shortcutBaseName.substring(0, extensionStart);
}

Option<String> shortcutTargetProgramPathFromBytes({
  required BottleRecord bottle,
  required Uint8List bytes,
}) {
  try {
    return shellLinkLocalBasePath(bytes).flatMap(
      (windowsPath) =>
          wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath),
    );
  } on RangeError {
    return const Option.none();
  }
}

Option<String> shellLinkLocalBasePath(Uint8List bytes) {
  const shellLinkHeaderSize = 0x4c;
  return readUint32Option(bytes, 0).flatMap(
    (headerSize) => headerSize == shellLinkHeaderSize
        ? readUint32Option(bytes, 0x14).flatMap(
            (linkFlags) =>
                shellLinkLinkInfoOffset(
                  bytes: bytes,
                  linkFlags: linkFlags,
                ).flatMap(
                  (offset) => shellLinkLocalBasePathAtLinkInfoOffset(
                    bytes: bytes,
                    offset: offset,
                  ),
                ),
          )
        : const Option.none(),
  );
}

Option<int> shellLinkLinkInfoOffset({
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

  return readUint16Option(
    bytes,
    shellLinkHeaderSize,
  ).map((idListSize) => shellLinkHeaderSize + 2 + idListSize);
}

Option<String> shellLinkLocalBasePathAtLinkInfoOffset({
  required Uint8List bytes,
  required int offset,
}) {
  return readUint32Option(bytes, offset).flatMap(
    (linkInfoSize) => readUint32Option(bytes, offset + 4).flatMap(
      (linkInfoHeaderSize) => readUint32Option(bytes, offset + 16).flatMap(
        (localBasePathOffset) => shellLinkLocalBasePathFromLinkInfo(
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

Option<String> shellLinkLocalBasePathFromLinkInfo({
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
      ? readUint32Option(bytes, offset + 28).flatMap(
          (localBasePathUnicodeOffset) => localBasePathUnicodeOffset > 0
              ? nullTerminatedUtf16LeStringOption(
                  bytes,
                  offset + localBasePathUnicodeOffset,
                  offset + linkInfoSize,
                )
              : const Option<String>.none(),
        )
      : const Option<String>.none();

  return unicodePath.match(
    () => nullTerminatedAsciiStringOption(
      bytes,
      offset + localBasePathOffset,
      offset + linkInfoSize,
    ),
    Option<String>.of,
  );
}
