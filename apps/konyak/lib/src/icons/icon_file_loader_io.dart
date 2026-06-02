import 'dart:io';
import 'dart:typed_data';

import 'icon_file_loader.dart';

final class DartIoIconFileLoader implements IconFileLoader {
  const DartIoIconFileLoader();

  @override
  Future<Uint8List?> loadIconBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }
}
