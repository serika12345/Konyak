part of '../../konyak_cli.dart';

String? _extractPeIcon({
  required _PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) {
  return _peIconBytes(image).match(
    _missingPeIconPath,
    (icoBytes) => _writePeIcon(
      bottle: bottle,
      programPath: programPath,
      fileStat: fileStat,
      icoBytes: icoBytes,
    ),
  );
}

Future<String?> _extractPeIconAsync({
  required _PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) async {
  return _peIconBytes(image).match(
    () async => _missingPeIconPath(),
    (icoBytes) => _writePeIconAsync(
      bottle: bottle,
      programPath: programPath,
      fileStat: fileStat,
      icoBytes: icoBytes,
    ),
  );
}

String? _missingPeIconPath() {
  return null;
}

String? _writePeIcon({
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
  required Uint8List icoBytes,
}) {
  final iconPath = _peIconCachePath(
    bottle: bottle,
    programPath: programPath,
    fileStat: fileStat,
  );
  try {
    final iconFile = File(iconPath);
    iconFile.parent.createSync(recursive: true);
    iconFile.writeAsBytesSync(icoBytes);

    return iconPath;
  } on FileSystemException {
    return null;
  }
}

Future<String?> _writePeIconAsync({
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
  required Uint8List icoBytes,
}) async {
  final iconPath = _peIconCachePath(
    bottle: bottle,
    programPath: programPath,
    fileStat: fileStat,
  );
  try {
    final iconFile = File(iconPath);
    await iconFile.parent.create(recursive: true);
    await iconFile.writeAsBytes(icoBytes);

    return iconPath;
  } on FileSystemException {
    return null;
  }
}
