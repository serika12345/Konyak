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

  test('macOS runner extends Flutter content into the titlebar', () {
    final source = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(source, matches(RegExp(r'titlebarAppearsTransparent\s*=\s*true')));
    expect(
      source,
      matches(RegExp(r'styleMask\.insert\(\.fullSizeContentView\)')),
    );
    expect(source, matches(RegExp(r'isMovableByWindowBackground\s*=\s*true')));
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

  test('macOS app menu exposes manual update checks', () {
    final xib = File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();
    final appDelegate = File(
      'macos/Runner/AppDelegate.swift',
    ).readAsStringSync();

    expect(xib, contains('<menuItem title="Check for Updates…"'));
    expect(xib, contains('selector="checkKonyakUpdates:" target="Voe-Tx-rLC"'));
    expect(appDelegate, contains('@IBAction func checkKonyakUpdates'));
    expect(appDelegate, contains('invokeMethod("checkKonyakUpdates"'));
  });

  test('macOS File menu exposes the archive import command', () {
    final xib = File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();
    final appDelegate = File(
      'macos/Runner/AppDelegate.swift',
    ).readAsStringSync();

    expect(xib, contains('<menu key="submenu" title="File"'));
    expect(xib, contains('<menuItem title="Import Bottle"'));
    expect(
      xib,
      contains('selector="importBottleArchive:" target="Voe-Tx-rLC"'),
    );
    expect(appDelegate, contains('@IBAction func importBottleArchive'));
    expect(appDelegate, contains('invokeMethod("importBottleArchive"'));
  });

  test('macOS app registers and forwards Windows executable files', () {
    final infoPlist = File('macos/Runner/Info.plist').readAsStringSync();
    final appDelegate = File(
      'macos/Runner/AppDelegate.swift',
    ).readAsStringSync();

    expect(infoPlist, contains('<key>CFBundleDocumentTypes</key>'));
    expect(infoPlist, contains('<string>Windows executable</string>'));
    expect(infoPlist, contains('<string>exe</string>'));
    expect(infoPlist, contains('<key>CFBundleTypeRole</key>'));
    expect(infoPlist, contains('<string>Viewer</string>'));
    expect(infoPlist, contains('<key>LSItemContentTypes</key>'));
    expect(
      infoPlist,
      contains('<string>com.microsoft.windows-executable</string>'),
    );
    expect(
      appDelegate,
      contains('application(_ sender: NSApplication, openFiles'),
    );
    expect(
      appDelegate,
      contains('application(_ application: NSApplication, open urls'),
    );
    expect(appDelegate, contains('openExecutableFiles'));
    expect(appDelegate, contains('takePendingExecutableOpenPaths'));
    expect(appDelegate, contains('visibleExternalWindowIds'));
    expect(appDelegate, contains('setMethodCallHandler'));
    expect(appDelegate, contains('url.pathExtension.lowercased() == "exe"'));
    expect(appDelegate, isNot(contains('LaunchServices.OpenWith')));
    expect(
      appDelegate,
      isNot(contains('clearStaleExecutableOpenWithOverride')),
    );
    expect(appDelegate, isNot(contains('getxattr')));
    expect(appDelegate, isNot(contains('removexattr')));
  });

  test('macOS app waits for Flutter close cleanup before terminating', () {
    final appDelegate = File(
      'macos/Runner/AppDelegate.swift',
    ).readAsStringSync();

    expect(appDelegate, contains('applicationShouldTerminate'));
    expect(appDelegate, contains('terminateWineProcessesBeforeQuit'));
    expect(appDelegate, contains('.terminateLater'));
    expect(appDelegate, contains('reply(toApplicationShouldTerminate: true)'));
  });

  test('macOS app bundles a Quick Look thumbnail extension for EXE files', () {
    final project = File(
      'macos/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final extensionInfoPlist = File(
      'macos/ExecutableThumbnail/Info.plist',
    ).readAsStringSync();
    final provider = File(
      'macos/ExecutableThumbnail/ThumbnailProvider.swift',
    ).readAsStringSync();
    final extractor = File(
      'macos/ExecutableThumbnail/PortableExecutableIconExtractor.swift',
    ).readAsStringSync();
    final resourceReader = File(
      'macos/ExecutableThumbnail/PeResourceReader.swift',
    ).readAsStringSync();

    expect(project, contains('ExecutableThumbnail.appex'));
    expect(
      project,
      contains('productType = "com.apple.product-type.app-extension";'),
    );
    expect(project, contains('Embed App Extensions'));
    expect(project, contains('dstSubfolderSpec = 13;'));
    expect(
      project,
      contains('ExecutableThumbnail.appex in Embed App Extensions'),
    );
    expect(project, contains('QuickLookThumbnailing.framework'));
    expect(project, contains('PortableExecutableIconExtractor.swift'));
    expect(project, contains('PeResourceReader.swift'));
    expect(project, contains('target = 4B4B52010000000000000001'));
    const extensionConfigurationIds = <String, String>{
      'Debug': '4B4B52100000000000000001',
      'Release': '4B4B52110000000000000001',
      'Profile': '4B4B52120000000000000001',
    };
    for (final entry in extensionConfigurationIds.entries) {
      final configurationStart = project.indexOf(
        '${entry.value} /* ${entry.key} */ = {',
      );
      expect(
        configurationStart,
        greaterThanOrEqualTo(0),
        reason: 'missing ${entry.key} extension configuration',
      );
      final buildSettingsStart = project.indexOf(
        'buildSettings = {',
        configurationStart,
      );
      final buildSettingsEnd = project.indexOf(
        '\n\t\t\t};',
        buildSettingsStart,
      );
      final buildSettings = project.substring(
        buildSettingsStart,
        buildSettingsEnd,
      );
      expect(
        buildSettings,
        contains('INFOPLIST_FILE = ExecutableThumbnail/Info.plist;'),
      );
      expect(
        buildSettings,
        contains('CURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)";'),
      );
    }

    expect(
      extensionInfoPlist,
      contains('<string>com.apple.quicklook.thumbnail</string>'),
    );
    expect(extensionInfoPlist, contains('<key>QLSupportedContentTypes</key>'));
    expect(
      extensionInfoPlist,
      contains('<key>QLThumbnailMinimumDimension</key>'),
    );
    expect(
      extensionInfoPlist,
      contains('<string>com.microsoft.windows-executable</string>'),
    );
    expect(
      extensionInfoPlist,
      contains('<string>\$(PRODUCT_MODULE_NAME).ThumbnailProvider</string>'),
    );

    expect(provider, contains('final class ThumbnailProvider'));
    expect(provider, contains('QLThumbnailProvider'));
    expect(provider, contains('QLThumbnailReply(contextSize:'));
    expect(provider, contains('PortableExecutableIconExtractor'));
    expect(provider, isNot(contains('Process')));
    expect(provider, isNot(contains('konyak-cli')));

    expect(extractor, contains('enum PortableExecutableIconExtractor'));
    expect(extractor, contains('rtIcon'));
    expect(extractor, contains('rtGroupIcon'));
    expect(extractor, contains('PortableExecutableImage.parse'));
    expect(extractor, contains('Int(exactly:'));
    expect(extractor, isNot(contains('UInt32(Int.max)')));

    expect(resourceReader, contains('enum PeResourceReader'));
    expect(resourceReader, contains('resourceLeaf'));
    expect(resourceReader, contains('Int(exactly:'));
    expect(resourceReader, isNot(contains('UInt32(Int.max)')));
  });

  test('macOS release bundles zstd extraction support for runtime stacks', () {
    final releaseScript = File(
      '../../scripts/build_macos_release.zsh',
    ).readAsStringSync();
    final finalizerScript = File(
      '../../scripts/finalize_macos_app.zsh',
    ).readAsStringSync();
    final debugBuildScript = File(
      '../../scripts/build_macos_debug_app.zsh',
    ).readAsStringSync();
    final smokeScript = File(
      '../../scripts/smoke_macos_release_runtime_extraction.zsh',
    ).readAsStringSync();
    final finderSmokeScript = File(
      '../../scripts/smoke_macos_finder_integration.zsh',
    ).readAsStringSync();
    final cliBridgeSmokeScript = File(
      '../../scripts/smoke_macos_packaged_app_cli_bridge.zsh',
    ).readAsStringSync();
    final puttyFixtureScript = File(
      '../../scripts/fetch_windows_fixture_putty.zsh',
    ).readAsStringSync();
    final publishWorkflow = File(
      '../../.github/workflows/publish.yml',
    ).readAsStringSync();
    final justfile = File('../../justfile').readAsStringSync();
    final releaseDocs = File('../../docs/release.md').readAsStringSync();
    final thirdPartyNotices = File(
      '../../THIRD_PARTY_NOTICES.md',
    ).readAsStringSync();

    expect(releaseScript, contains('finalize_macos_app.zsh'));
    expect(releaseScript, contains('release_app_bundle='));
    expect(releaseScript, contains('rm -rf "\$release_app_bundle"'));
    expect(
      releaseScript,
      contains('ditto "\$app_bundle" "\$release_app_bundle"'),
    );
    expect(releaseScript, contains('dmg_path='));
    expect(releaseScript, contains('create-dmg'));
    expect(releaseScript, contains('resvg'));
    expect(releaseScript, contains('--app-drop-link 470 210'));
    expect(releaseScript, contains('format: "dmg"'));
    expect(
      releaseScript,
      isNot(contains('--keepParent "\$release_app_bundle" "\$zip_path"')),
    );
    expect(finalizerScript, contains('--app <path> --cli <path>'));
    expect(finalizerScript, contains('resources_dir='));
    expect(finalizerScript, contains('\$resources_dir/konyak-cli'));
    expect(finalizerScript, contains('\$resources_dir/zstd'));
    expect(finalizerScript, contains('libzstd.1.dylib'));
    expect(finalizerScript, contains('install_name_tool'));
    expect(finalizerScript, contains('@executable_path/libzstd.1.dylib'));
    expect(finalizerScript, contains('Zstandard-BSD-3-Clause.txt'));
    expect(finalizerScript, contains('codesign --verify'));
    expect(debugBuildScript, contains('flutter build macos'));
    expect(debugBuildScript, contains('--debug'));
    expect(debugBuildScript, contains('finalize_macos_app.zsh'));
    expect(debugBuildScript, contains('.dart_tool/konyak/app/macos/debug'));
    expect(smokeScript, contains('release_root='));
    expect(smokeScript, contains('\$release_root/Konyak.app'));
    expect(
      smokeScript,
      contains('install-macos-wine --reinstall --source-manifest'),
    );
    expect(smokeScript, contains('PATH=/usr/bin:/bin'));
    expect(finderSmokeScript, contains('lsregister'));
    expect(finderSmokeScript, contains('mdls'));
    expect(finderSmokeScript, contains('CGWindowListCopyWindowInfo'));
    expect(finderSmokeScript, contains('qlmanage'));
    expect(finderSmokeScript, contains('com.microsoft.windows-executable'));
    expect(finderSmokeScript, isNot(contains('xattr')));
    expect(finderSmokeScript, contains('KONYAK_MACOS_FINDER_SMOKE_APP'));
    expect(
      finderSmokeScript,
      contains('KONYAK_MACOS_FINDER_SMOKE_KEEP_APP_RUNNING'),
    );
    expect(cliBridgeSmokeScript, contains('/usr/bin/open'));
    expect(cliBridgeSmokeScript, contains('KONYAK_BUNDLE_RESOURCES'));
    expect(cliBridgeSmokeScript, contains('KONYAK_ENABLE_SMOKE_HOOKS=1'));
    expect(
      cliBridgeSmokeScript,
      contains('KONYAK_SMOKE_OPEN_EXECUTABLE_AUTO_RUN_BOTTLE_ID'),
    );
    expect(cliBridgeSmokeScript, contains('Contents/Resources/konyak-cli'));
    expect(cliBridgeSmokeScript, contains('run-program'));
    expect(cliBridgeSmokeScript, isNot(contains('wineloader" "cmd"')));
    expect(puttyFixtureScript, contains('putty_version=0.84'));
    expect(
      puttyFixtureScript,
      contains('https://the.earth.li/~sgtatham/putty/0.84/w64/putty.exe'),
    );
    expect(
      puttyFixtureScript,
      contains(
        '7056ca2f6a9f3c525845b116c7bf564ced3284a4083ea80d7e9ef51a16f612c4',
      ),
    );
    expect(puttyFixtureScript, contains('shasum -a 256'));
    expect(puttyFixtureScript, contains('.dart_tool/konyak/fixtures/windows'));
    expect(justfile, contains('macos-debug-app:'));
    expect(justfile, contains('fetch-windows-fixture-putty:'));
    expect(justfile, contains('smoke-macos-finder:'));
    expect(justfile, contains('smoke-macos-app-cli-bridge:'));
    expect(justfile, contains('smoke-macos-finder-putty:'));
    expect(justfile, contains('smoke-macos-runtime-install:'));
    expect(justfile, contains('smoke-macos-dmg-layout:'));
    expect(publishWorkflow, contains('smoke_macos_release_runtime_extraction'));
    expect(publishWorkflow, contains('smoke_macos_dmg_layout'));
    expect(publishWorkflow, contains('fetch_windows_fixture_putty'));
    expect(publishWorkflow, contains('smoke_macos_finder_integration'));
    expect(publishWorkflow, contains('smoke_macos_packaged_app_cli_bridge'));
    expect(releaseDocs, contains('Konyak.app'));
    expect(releaseDocs, contains('macos-debug-app'));
    expect(releaseDocs, contains('smoke-macos-finder'));
    expect(releaseDocs, contains('smoke-macos-dmg-layout'));
    expect(releaseDocs, contains('smoke-macos-app-cli-bridge'));
    expect(releaseDocs, contains('smoke-macos-finder-putty'));
    expect(releaseDocs, contains('create-dmg'));
    expect(releaseDocs, contains('PuTTY 0.84'));
    expect(releaseDocs, contains('Finder-to-Flutter-to-CLI'));
    expect(releaseDocs, contains('zstd'));
    expect(thirdPartyNotices, contains('Zstandard: BSD-3-Clause'));
  });

  test('macOS runtime CLI smoke runs backend probes through the CLI', () {
    final runtimeSmokeScript = File(
      '../../scripts/run_macos_runtime_cli_smoke.zsh',
    ).readAsStringSync();
    final runtimeSmokeWorkflow = File(
      '../../.github/workflows/macos-runtime-cli-smoke.yml',
    ).readAsStringSync();

    expect(
      runtimeSmokeScript,
      contains('runtime/konyak-macos-runtime/scripts/build-backend-probes.zsh'),
    );
    expect(runtimeSmokeScript, contains('run_backend_probe_smoke'));
    expect(runtimeSmokeScript, contains('wait_for_probe_sentinel'));
    expect(runtimeSmokeScript, contains('set-runtime-settings'));
    expect(runtimeSmokeScript, contains('run-program'));
    expect(runtimeSmokeScript, contains('dxvk-macos-probe'));
    expect(runtimeSmokeScript, contains('dxmt-probe'));
    expect(runtimeSmokeScript, contains('vkd3d-probe'));
    expect(runtimeSmokeScript, contains('KONYAK_D3D11_DEVICE_PROBE_OK'));
    expect(runtimeSmokeScript, contains('KONYAK_D3D12_DEVICE_PROBE_OK'));
    expect(runtimeSmokeScript, isNot(contains('DYLD_FALLBACK_LIBRARY_PATH')));

    expect(
      runtimeSmokeWorkflow,
      contains('runtime/konyak-macos-runtime/probes/windows/**'),
    );
    expect(
      runtimeSmokeWorkflow,
      contains('runtime/konyak-macos-runtime/scripts/build-backend-probes.zsh'),
    );
  });

  test('macOS app exposes visible external window ids to Flutter', () {
    final appDelegate = File(
      'macos/Runner/AppDelegate.swift',
    ).readAsStringSync();

    expect(appDelegate, contains('CGWindowListCopyWindowInfo'));
    expect(appDelegate, contains('.optionOnScreenOnly'));
    expect(appDelegate, contains('.excludeDesktopElements'));
    expect(appDelegate, contains('kCGWindowOwnerPID'));
    expect(appDelegate, contains('kCGWindowNumber'));
    expect(appDelegate, contains('windowFilter(from: call.arguments)'));
    expect(appDelegate, contains('KERN_PROC_PID'));
    expect(appDelegate, contains('kp_eproc.e_ppid'));
    expect(appDelegate, contains('kCGWindowOwnerName'));
    expect(appDelegate, contains('proc_pidpath'));
    expect(appDelegate, contains('isWineProcessName'));
    expect(appDelegate, contains('ProcessInfo.processInfo.processIdentifier'));
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
      'File',
      'Check for Updates…',
      'Import Bottle',
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
