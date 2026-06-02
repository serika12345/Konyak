part of '../konyak_cli.dart';

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
