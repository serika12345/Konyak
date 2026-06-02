import 'dart:typed_data';

abstract interface class IconFileLoader {
  Future<Uint8List?> loadIconBytes(String path);
}
