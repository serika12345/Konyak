import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import 'pe_program_icons.dart';
import 'pe_program_image.dart';

Option<String> extractPeIcon({
  required PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) {
  return peIconBytes(image).flatMap(
    (icoBytes) => writePeIcon(
      bottle: bottle,
      programPath: programPath,
      fileStat: fileStat,
      icoBytes: icoBytes,
    ),
  );
}

Future<Option<String>> extractPeIconAsync({
  required PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) async {
  return peIconBytes(image).match(
    () async => const Option.none(),
    (icoBytes) => writePeIconAsync(
      bottle: bottle,
      programPath: programPath,
      fileStat: fileStat,
      icoBytes: icoBytes,
    ),
  );
}

Option<String> writePeIcon({
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

    return Option.of(iconPath);
  } on FileSystemException {
    return const Option.none();
  }
}

Future<Option<String>> writePeIconAsync({
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

    return Option.of(iconPath);
  } on FileSystemException {
    return const Option.none();
  }
}
