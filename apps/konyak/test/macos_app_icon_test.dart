import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository keeps the original Konyak icon source image', () {
    const source = _ExpectedPng(
      size: 1254,
      byteLength: 1500583,
      fnv1a64: '72bf7738c90e8b79',
    );

    final bytes = File('assets/icons/konyak.png').readAsBytesSync();
    final dimensions = _readPngDimensions(bytes);

    expect(dimensions.width, source.size);
    expect(dimensions.height, source.size);
    expect(_readPngColorType(bytes), 6);
    expect(bytes.length, source.byteLength);
    expect(_fnv1a64(bytes), source.fnv1a64);
  });

  test('macOS AppIcon catalog uses the generated Konyak icon assets', () {
    const expectedIcons = <String, _ExpectedPng>{
      'app_icon_16.png': _ExpectedPng(
        size: 16,
        byteLength: 664,
        fnv1a64: 'cd4e204982b2a596',
      ),
      'app_icon_32.png': _ExpectedPng(
        size: 32,
        byteLength: 1675,
        fnv1a64: 'd7d7c82097b33baa',
      ),
      'app_icon_64.png': _ExpectedPng(
        size: 64,
        byteLength: 4946,
        fnv1a64: 'ec0ef340b59d1f2a',
      ),
      'app_icon_128.png': _ExpectedPng(
        size: 128,
        byteLength: 15310,
        fnv1a64: 'cacb1f644f523844',
      ),
      'app_icon_256.png': _ExpectedPng(
        size: 256,
        byteLength: 48625,
        fnv1a64: '4e9bab9ffb8175f8',
      ),
      'app_icon_512.png': _ExpectedPng(
        size: 512,
        byteLength: 171622,
        fnv1a64: '0e6aced11a986549',
      ),
      'app_icon_1024.png': _ExpectedPng(
        size: 1024,
        byteLength: 673730,
        fnv1a64: '47d162b901b9c633',
      ),
    };

    const iconDirectory = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';

    for (final entry in expectedIcons.entries) {
      final bytes = File('$iconDirectory/${entry.key}').readAsBytesSync();
      final dimensions = _readPngDimensions(bytes);

      expect(dimensions.width, entry.value.size, reason: entry.key);
      expect(dimensions.height, entry.value.size, reason: entry.key);
      expect(_readPngColorType(bytes), 6, reason: entry.key);
      expect(bytes.length, entry.value.byteLength, reason: entry.key);
      expect(_fnv1a64(bytes), entry.value.fnv1a64, reason: entry.key);
    }
  });

  test('Linux runner bundles and applies the generated Konyak icon', () {
    const expectedIcon = _ExpectedPng(
      size: 256,
      byteLength: 48625,
      fnv1a64: '4e9bab9ffb8175f8',
    );

    final bytes = File(
      'linux/runner/resources/app_icon_256.png',
    ).readAsBytesSync();
    final dimensions = _readPngDimensions(bytes);

    expect(dimensions.width, expectedIcon.size);
    expect(dimensions.height, expectedIcon.size);
    expect(_readPngColorType(bytes), 6);
    expect(bytes.length, expectedIcon.byteLength);
    expect(_fnv1a64(bytes), expectedIcon.fnv1a64);

    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('runner/resources/app_icon_256.png'),
    );
    expect(
      File('linux/runner/my_application.cc').readAsStringSync(),
      contains('gtk_window_set_icon_from_file'),
    );
    expect(
      File('linux/runner/my_application.cc').readAsStringSync(),
      contains('gtk_window_set_default_icon_name(APPLICATION_ID)'),
    );
    expect(
      File('linux/runner/my_application.cc').readAsStringSync(),
      contains('gdk_set_program_class(APPLICATION_ID)'),
    );
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('icons/hicolor/256x256/apps'),
    );
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('applications'),
    );
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('metainfo'),
    );
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('app.konyak.Konyak.desktop'),
    );
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('app.konyak.Konyak.appdata.xml'),
    );
    expect(
      File(
        'linux/runner/resources/app.konyak.Konyak.desktop.in',
      ).readAsStringSync(),
      contains('Icon=app.konyak.Konyak'),
    );
    expect(
      File(
        'linux/runner/resources/app.konyak.Konyak.desktop.in',
      ).readAsStringSync(),
      contains('StartupWMClass=app.konyak.Konyak'),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/icons/konyak.png'),
    );
    expect(
      File(
        'linux/runner/resources/app.konyak.Konyak.appdata.xml',
      ).readAsStringSync(),
      contains('<id>app.konyak.Konyak</id>'),
    );
    expect(
      File(
        'linux/runner/resources/app.konyak.Konyak.appdata.xml',
      ).readAsStringSync(),
      contains(
        '<launchable type="desktop-id">app.konyak.Konyak.desktop</launchable>',
      ),
    );
  });

  test('macOS runner applies the generated app icon at launch', () {
    expect(
      File('macos/Runner/Info.plist').readAsStringSync(),
      contains('<key>CFBundleIconFile</key>\n\t<string>AppIcon</string>'),
    );
    expect(
      File('macos/Runner/MainFlutterWindow.swift').readAsStringSync(),
      contains('NSApplication.shared.applicationIconImage'),
    );
  });
}

({int width, int height}) _readPngDimensions(Uint8List bytes) {
  const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  expect(bytes.length, greaterThanOrEqualTo(24));
  expect(bytes.take(pngSignature.length), pngSignature);

  final data = ByteData.sublistView(bytes);
  return (width: data.getUint32(16), height: data.getUint32(20));
}

int _readPngColorType(Uint8List bytes) {
  expect(bytes.length, greaterThanOrEqualTo(26));
  return ByteData.sublistView(bytes).getUint8(25);
}

String _fnv1a64(Uint8List bytes) {
  final mask = (BigInt.one << 64) - BigInt.one;
  final prime = BigInt.parse('100000001b3', radix: 16);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);

  for (final byte in bytes) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask;
  }

  return hash.toRadixString(16).padLeft(16, '0');
}

class _ExpectedPng {
  const _ExpectedPng({
    required this.size,
    required this.byteLength,
    required this.fnv1a64,
  });

  final int size;
  final int byteLength;
  final String fnv1a64;
}
