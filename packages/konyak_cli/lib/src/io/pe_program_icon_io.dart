import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../domain/bottle/bottle_models.dart';
import 'pe_program_icons.dart';
import 'pe_program_image.dart';

String? extractPeIcon({
  required PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) {
  return peIconBytes(image).match(
    missingPeIconPath,
    (icoBytes) => writePeIcon(
      bottle: bottle,
      programPath: programPath,
      fileStat: fileStat,
      icoBytes: icoBytes,
    ),
  );
}

Future<String?> extractPeIconAsync({
  required PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) async {
  return peIconBytes(image).match(
    () async => missingPeIconPath(),
    (icoBytes) => writePeIconAsync(
      bottle: bottle,
      programPath: programPath,
      fileStat: fileStat,
      icoBytes: icoBytes,
    ),
  );
}

String? missingPeIconPath() {
  return null;
}

String? writePeIcon({
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
  required Uint8List icoBytes,
}) {
  final iconPath = peIconCachePath(
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

Future<String?> writePeIconAsync({
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
  required Uint8List icoBytes,
}) async {
  final iconPath = peIconCachePath(
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
