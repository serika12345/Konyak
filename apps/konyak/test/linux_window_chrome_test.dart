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

  test('Linux runner starts at the macOS content dimensions', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(
      source,
      matches(
        RegExp(r'gtk_window_set_default_size\(\s*window,\s*800\s*,\s*500\s*\)'),
      ),
    );
  });

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

  test('Linux AppStream metadata avoids release packaging warnings', () {
    final appdata = File(
      'linux/runner/resources/app.konyak.Konyak.appdata.xml',
    ).readAsStringSync();

    expect(
      appdata,
      contains(
        '<summary>Manage Wine-based bottles for Windows apps and games</summary>',
      ),
    );
    expect(appdata, contains('<developer id="app.konyak">'));
    expect(
      appdata,
      contains(
        '<url type="homepage">https://github.com/serika12345/Konyak</url>',
      ),
    );
    expect(
      appdata,
      isNot(contains('https://github.com/masatokinugawa/Konyak')),
    );
  });

  test('Linux release build links GTK transitive dependencies explicitly', () {
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();
    final runnerCmake = File('linux/runner/CMakeLists.txt').readAsStringSync();
    final flake = File('../../flake.nix').readAsStringSync();
    final justfile = File('../../justfile').readAsStringSync();

    expect(
      cmake,
      contains(
        'pkg_check_modules(FONTCONFIG REQUIRED IMPORTED_TARGET fontconfig)',
      ),
    );
    expect(
      cmake,
      contains('pkg_check_modules(LIBMOUNT REQUIRED IMPORTED_TARGET mount)'),
    );
    expect(runnerCmake, contains('PkgConfig::FONTCONFIG'));
    expect(runnerCmake, contains('PkgConfig::LIBMOUNT'));
    expect(cmake, contains(r'${LIBMOUNT_LIBRARY_DIRS}'));
    expect(flake, contains('fontconfig'));
    expect(flake, contains('util-linux'));
    expect(justfile, contains('flutter-linux-loader-check'));
  });

  test('Linux release runs appimagetool without bubblewrap wrappers', () {
    final script = File(
      '../../scripts/build_linux_release.zsh',
    ).readAsStringSync();
    final flake = File('../../flake.nix').readAsStringSync();

    expect(script, contains('APPIMAGE_EXTRACT_AND_RUN=1'));
    expect(script, isNot(contains(r'appimage-run "$tool_path"')));
    expect(flake, isNot(contains('appimage-run')));
  });
}
