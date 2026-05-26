import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS runner starts at Konyak content dimensions', () {
    final xib = File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();

    expect(
      xib,
      contains(
        '<rect key="contentRect" x="335" y="390" width="800" height="500"/>',
      ),
    );
    expect(
      xib,
      contains('<rect key="frame" x="0.0" y="0.0" width="800" height="500"/>'),
    );
  });

  test('macOS runner applies Konyak minimum content dimensions', () {
    final source = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(
      source,
      matches(
        RegExp(
          r'contentMinSize\s*=\s*NSSize\(\s*width:\s*600\s*,\s*height:\s*316\s*\)',
        ),
      ),
    );
  });

  test('macOS runner hides the native window title', () {
    final source = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(source, matches(RegExp(r'titleVisibility\s*=\s*\.hidden')));
  });

  test('macOS app menu opens Settings with the standard shortcut', () {
    final xib = File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();
    final appDelegate = File(
      'macos/Runner/AppDelegate.swift',
    ).readAsStringSync();
    final window = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(xib, contains('<menuItem title="Settings…" keyEquivalent=","'));
    expect(xib, contains('selector="openSettings:" target="Voe-Tx-rLC"'));
    expect(appDelegate, contains('@IBAction func openSettings'));
    expect(appDelegate, contains('FlutterMethodChannel('));
    expect(appDelegate, contains('name: "konyak/menu"'));
    expect(window, contains('configureMenuChannel'));
  });

  test('macOS app menu omits unused default items', () {
    final xib = File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();

    for (final removedTitle in [
      'Services',
      'Edit',
      'Undo',
      'Redo',
      'Cut',
      'Copy',
      'Paste',
      'Find',
      'Spelling and Grammar',
      'Substitutions',
      'Transformations',
      'Speech',
      'View',
      'Enter Full Screen',
      'Window',
      'Minimize',
      'Zoom',
      'Bring All to Front',
      'Help',
    ]) {
      expect(xib, isNot(contains('<menuItem title="$removedTitle"')));
    }

    for (final retainedTitle in [
      'About APP_NAME',
      'Settings…',
      'Hide APP_NAME',
      'Hide Others',
      'Show All',
      'Quit APP_NAME',
    ]) {
      expect(xib, contains('<menuItem title="$retainedTitle"'));
    }
  });
}
