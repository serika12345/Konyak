import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux runner disables native window decorations', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, contains('gtk_window_set_decorated(window, FALSE)'));
    expect(source, isNot(contains('GtkHeaderBar')));
    expect(source, isNot(contains('gtk_window_set_titlebar')));
  });

  test('Linux runner handles in-app window control commands', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, contains('"konyak/linux_window"'));
    expect(source, contains('"setWindowDragRegion"'));
    expect(source, contains('"visibleExternalWindowIds"'));
    expect(source, contains('"runningWineProcessIds"'));
    expect(source, contains('"minimizeWindow"'));
    expect(source, contains('"toggleMaximizeWindow"'));
    expect(source, contains('"closeWindow"'));
    expect(source, contains('gtk_window_iconify'));
    expect(source, contains('gtk_window_maximize'));
    expect(source, contains('gtk_window_unmaximize'));
    expect(source, contains('gtk_window_close'));
  });

  test(
    'Linux runner probes visible Wine windows through X11 when available',
    () {
      final source = File('linux/runner/my_application.cc').readAsStringSync();
      final cmake = File('linux/CMakeLists.txt').readAsStringSync();
      final runnerCmake = File(
        'linux/runner/CMakeLists.txt',
      ).readAsStringSync();

      expect(source, contains('GDK_WINDOWING_X11'));
      expect(source, contains('GDK_IS_X11_DISPLAY'));
      expect(source, contains('XOpenDisplay'));
      expect(source, contains('XCloseDisplay'));
      expect(source, contains('DISPLAY'));
      expect(source, contains('_NET_CLIENT_LIST'));
      expect(source, contains('_NET_WM_PID'));
      expect(source, contains('XGetWindowProperty'));
      expect(source, contains('/proc/'));
      expect(source, contains('opendir("/proc")'));
      expect(source, contains('readdir'));
      expect(source, contains('running_matching_wine_process_ids'));
      expect(source, contains('includeWineProcessWindows'));
      expect(source, contains('includeWineProcesses'));
      expect(source, contains('descendantOfProcessIds'));
      expect(
        cmake,
        contains('pkg_check_modules(X11 REQUIRED IMPORTED_TARGET x11)'),
      );
      expect(runnerCmake, contains('PkgConfig::X11'));
    },
  );

  test(
    'Linux runner starts window drags from a transparent native overlay',
    () {
      final source = File('linux/runner/my_application.cc').readAsStringSync();

      expect(source, contains('GtkOverlay'));
      expect(source, contains('gtk_overlay_add_overlay'));
      expect(source, contains('GtkEventBox'));
      expect(source, contains('gtk_event_box_set_visible_window'));
      expect(source, contains('GDK_BUTTON_PRESS_MASK'));
      expect(source, contains('"button-press-event"'));
      expect(source, contains('GdkEventButton* event'));
      expect(source, contains('gtk_window_begin_move_drag'));
      expect(source, contains('gtk_widget_set_margin_start'));
      expect(source, contains('gtk_widget_set_margin_top'));
      expect(source, contains('gtk_widget_set_size_request'));
      expect(source, contains('event->x_root'));
      expect(source, contains('event->y_root'));
      expect(source, contains('event->time'));
      expect(source, isNot(contains('"startWindowDrag"')));
      expect(source, isNot(contains('gtk_get_current_event_time()')));
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
