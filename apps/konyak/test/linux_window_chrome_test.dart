import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux GTK header bar hides the title text', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, contains('gtk_header_bar_set_title(header_bar, "")'));
  });

  test('Linux GTK header bar shows minimize, maximize, and close controls', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(
      source,
      matches(
        RegExp(
          r'gtk_header_bar_set_decoration_layout\(\s*header_bar,\s*":minimize,maximize,close"\s*\)',
        ),
      ),
    );
  });

  test(
    'Linux fallback window title is hidden when not using a GTK header bar',
    () {
      final source = File('linux/runner/my_application.cc').readAsStringSync();

      expect(source, contains('gtk_window_set_title(window, "")'));
    },
  );

  test('Linux desktop entry accepts Windows executable files', () {
    final desktopEntry = File(
      'linux/runner/resources/app.konyak.Konyak.desktop.in',
    ).readAsStringSync();

    expect(desktopEntry, contains('Exec=@BINARY_NAME@ %f'));
    expect(desktopEntry, contains('MimeType=application/x-ms-dos-executable;'));
    expect(desktopEntry, contains('application/x-msdownload;'));
    expect(
      desktopEntry,
      contains('application/vnd.microsoft.portable-executable;'),
    );
    expect(desktopEntry, contains('application/x-msi;'));
    expect(desktopEntry, contains('application/x-ms-installer;'));
    expect(desktopEntry, contains('application/x-ms-shortcut;'));
    expect(desktopEntry, contains('application/x-msdos-program;'));
    expect(desktopEntry, contains('text/x-msdos-batch;'));
  });
}
