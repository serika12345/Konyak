import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:konyak/main.dart';
import 'package:konyak/src/app/app_constants.dart';
import 'package:konyak/src/app/home/sidebar.dart';
import 'package:konyak/src/app/programs/pin_program_action.dart';
import 'package:konyak/src/app/programs/program_window_probe.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';
import 'package:konyak/src/files/bottle_archive_picker.dart';
import 'package:konyak/src/files/directory_picker.dart';
import 'package:konyak/src/files/gptk_wine_source_picker.dart';
import 'package:konyak/src/files/program_file_picker.dart';
import 'package:konyak/src/icons/icon_file_loader.dart';
import 'package:konyak/src/l10n/konyak_localizations.dart';
import 'package:konyak/src/logs/log_reader.dart';

part 'widget_shell_sidebar.part.dart';
part 'widget_bottle_management.part.dart';
part 'widget_programs.part.dart';
part 'widget_bottle_configuration.part.dart';
part 'widget_menus_winetricks.part.dart';
part 'widget_settings.part.dart';
part 'widget_macos_startup.part.dart';

void main() {
  defineShellAndSidebarWidgetTests();
  defineBottleManagementWidgetTests();
  defineProgramWidgetTests();
  defineBottleConfigurationWidgetTests();
  defineMenuWinetricksAndInstalledProgramWidgetTests();
  defineSettingsWidgetTests();
  defineMacosStartupAndRuntimeWidgetTests();
}

final Matcher _regularTextWeight = anyOf(isNull, FontWeight.normal);
const _expandedSidebarWidth = 190.0;
const _collapsedSidebarWidth = 44.0;

Future<void> _loadKonyakTestFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/inter/Inter-Variable.ttf'));
  await inter.load();

  final notoSansJp = FontLoader('Noto Sans JP')
    ..addFont(
      rootBundle.load('assets/fonts/noto_sans_jp/NotoSansJP-Variable.ttf'),
    );
  await notoSansJp.load();
}

Future<void> _expectGoldenFileWithinTolerance(
  Finder finder,
  String goldenFile, {
  required double diffTolerance,
}) async {
  final previousGoldenFileComparator = goldenFileComparator;
  goldenFileComparator = _TolerantGoldenFileComparator(
    Uri.parse('test/widget_test.dart'),
    diffTolerance: diffTolerance,
  );
  addTearDown(() => goldenFileComparator = previousGoldenFileComparator);

  await expectLater(finder, matchesGoldenFile(goldenFile));
}

final class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(super.testFile, {required double diffTolerance})
    : assert(
        0 <= diffTolerance && diffTolerance <= 1,
        'diffTolerance must be between 0 and 1',
      ),
      _diffTolerance = diffTolerance;

  final double _diffTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _diffTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

KonyakApp _testKonyakApp({
  KonyakPlatform platform = KonyakPlatform.macos,
  KonyakCliClient? cliClient,
  LogReader? logReader,
  ProgramFilePicker? programFilePicker,
  DirectoryPicker? directoryPicker,
  GptkWineSourcePicker? gptkWineSourcePicker,
  BottleArchivePicker? bottleArchivePicker,
  IconFileLoader? iconFileLoader,
  ProgramWindowProbe? programWindowProbe,
  List<String> initialExecutablePaths = const <String>[],
  String? executableOpenAutoRunBottleId,
  bool enableBackgroundServices = false,
}) {
  return KonyakApp(
    platform: platform,
    cliClient: cliClient,
    logReader: logReader,
    programFilePicker: programFilePicker,
    directoryPicker: directoryPicker,
    gptkWineSourcePicker: gptkWineSourcePicker,
    bottleArchivePicker: bottleArchivePicker,
    iconFileLoader: iconFileLoader,
    programWindowProbe: programWindowProbe ?? const _NoopProgramWindowProbe(),
    initialExecutablePaths: initialExecutablePaths,
    executableOpenAutoRunBottleId: executableOpenAutoRunBottleId,
    enableBackgroundServices: enableBackgroundServices,
  );
}

Widget _testSidebar({
  required bool reserveLeadingWindowControlsSpace,
  KonyakPlatform platform = KonyakPlatform.macos,
}) {
  return MaterialApp(
    theme: konyakThemeData(konyakDarkColors),
    supportedLocales: KonyakLocalizations.supportedLocales,
    localizationsDelegates: KonyakLocalizations.localizationsDelegates,
    home: Scaffold(
      body: KonyakSidebar(
        platform: platform,
        reserveLeadingWindowControlsSpace: reserveLeadingWindowControlsSpace,
        bottles: const <BottleSummary>[],
        selectedBottleId: null,
        searchController: TextEditingController(),
        onSearchChanged: (_) {},
        onToggleSidebar: () {},
        onBottleSelected: (_) {},
        onBottleContextMenuAction: (_, _) {},
      ),
    ),
  );
}

FontWeight? _fontWeightForText(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.fontWeight;
}

Finder _windowControlDotFinder(Color color) {
  return find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) {
      return false;
    }

    final decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == color;
  });
}

double _sidebarWidth(WidgetTester tester) {
  return tester.getSize(find.byKey(const ValueKey('sidebar-slot'))).width;
}

Uint8List _singlePixelIcoBytes() {
  const headerLength = 6;
  const entryLength = 16;
  const imageOffset = headerLength + entryLength;
  const dibLength = 40 + 4 + 4;
  final bytes = Uint8List(imageOffset + dibLength);

  _writeU16(bytes, 2, 1);
  _writeU16(bytes, 4, 1);
  bytes[6] = 1;
  bytes[7] = 1;
  _writeU16(bytes, 10, 1);
  _writeU16(bytes, 12, 32);
  _writeU32(bytes, 14, dibLength);
  _writeU32(bytes, 18, imageOffset);

  final dibOffset = imageOffset;
  _writeU32(bytes, dibOffset, 40);
  _writeI32(bytes, dibOffset + 4, 1);
  _writeI32(bytes, dibOffset + 8, 2);
  _writeU16(bytes, dibOffset + 12, 1);
  _writeU16(bytes, dibOffset + 14, 32);
  _writeU32(bytes, dibOffset + 20, 4);

  final pixelOffset = dibOffset + 40;
  bytes[pixelOffset] = 0;
  bytes[pixelOffset + 1] = 0;
  bytes[pixelOffset + 2] = 0xff;
  bytes[pixelOffset + 3] = 0xff;

  return bytes;
}

String _macosRuntimeListPayload({
  bool dxvkAvailable = true,
  bool dxmtAvailable = true,
  bool gptkAvailable = true,
}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'runtimes': <Object?>[
      <String, Object?>{
        'id': 'konyak-macos-wine',
        'name': 'Konyak macOS Wine',
        'platform': 'macos',
        'architecture': 'x86_64',
        'runnerKind': 'macosWine',
        'isBundled': false,
        'isUpdateable': true,
        'isInstalled': true,
        'stack': <String, Object?>{
          'schemaVersion': 1,
          'id': 'macos-konyak-runtime-stack',
          'name': 'Konyak macOS runtime stack',
          'compatibilityTarget': 'macos-konyak-runtime-stack',
          'isComplete': dxvkAvailable && dxmtAvailable,
          'backends': <Object?>[
            _runtimeStackBackendPayload(
              id: 'dxvk-macos',
              name: 'DXVK-macOS',
              role: 'd3d9-d3d11-metal-translation',
              componentIds: const <String>['dxvk-macos', 'moltenvk'],
              isAvailable: dxvkAvailable,
              missingPaths: dxvkAvailable
                  ? const <String>[]
                  : ['/runtime/lib/dxvk/x86_64-windows/dxgi.dll'],
            ),
            _runtimeStackBackendPayload(
              id: 'dxmt',
              name: 'DXMT',
              role: 'd3d10-d3d11-metal-translation',
              componentIds: const <String>['dxmt'],
              isAvailable: dxmtAvailable,
              missingPaths: dxmtAvailable
                  ? const <String>[]
                  : ['/runtime/lib/dxmt/x86_64-windows/d3d11.dll'],
            ),
            _runtimeStackBackendPayload(
              id: 'gptk-d3dmetal',
              name: 'GPTK/D3DMetal',
              role: 'd3d12-metal-translation',
              componentIds: const <String>['gptk-d3dmetal'],
              isAvailable: gptkAvailable,
              missingPaths: gptkAvailable
                  ? const <String>[]
                  : [
                      '/runtime/components/gptk-d3dmetal/lib/external/'
                          'D3DMetal.framework',
                    ],
            ),
          ],
          'components': <Object?>[
            _runtimeStackComponentPayload(
              id: 'wine',
              name: 'Wine',
              role: 'windows-runner',
            ),
            _runtimeStackComponentPayload(
              id: 'wine32on64',
              name: 'Wine32-on-64 support',
              role: '32-bit-windows-support',
            ),
            _runtimeStackComponentPayload(
              id: 'dxvk-macos',
              name: 'DXVK-macOS',
              role: 'd3d9-d3d11-translation',
              missingPaths: dxvkAvailable
                  ? const <String>[]
                  : ['/runtime/lib/dxvk/x86_64-windows/dxgi.dll'],
            ),
            _runtimeStackComponentPayload(
              id: 'dxmt',
              name: 'DXMT',
              role: 'd3d10-d3d11-metal-translation',
              missingPaths: dxmtAvailable
                  ? const <String>[]
                  : ['/runtime/lib/dxmt/x86_64-windows/d3d11.dll'],
            ),
            _runtimeStackComponentPayload(
              id: 'moltenvk',
              name: 'MoltenVK',
              role: 'vulkan-metal-translation',
            ),
            _runtimeStackComponentPayload(
              id: 'gstreamer',
              name: 'GStreamer runtime',
              role: 'media-runtime',
            ),
            _runtimeStackComponentPayload(
              id: 'wine-mono',
              name: 'wine-mono',
              role: 'dotnet-runtime',
            ),
            _runtimeStackComponentPayload(
              id: 'winetricks',
              name: 'winetricks',
              role: 'verb-installer',
            ),
            _runtimeStackComponentPayload(
              id: 'gptk-d3dmetal',
              name: 'GPTK/D3DMetal',
              role: 'd3d12-metal-translation',
              isRequired: false,
              version: gptkAvailable ? 'user-provided' : null,
              missingPaths: gptkAvailable
                  ? const <String>[]
                  : [
                      '/runtime/components/gptk-d3dmetal/lib/external/'
                          'D3DMetal.framework',
                    ],
            ),
          ],
        },
      },
    ],
  });
}

String _linuxRuntimeListPayload({bool dxvkAvailable = true}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'runtimes': <Object?>[
      <String, Object?>{
        'id': 'konyak-linux-wine',
        'name': 'Konyak Linux Wine',
        'platform': 'linux',
        'architecture': 'x86_64',
        'runnerKind': 'wine',
        'isBundled': false,
        'isUpdateable': true,
        'isInstalled': true,
        'stack': <String, Object?>{
          'schemaVersion': 1,
          'id': 'linux-wine-runtime-stack',
          'name': 'Linux Wine/Proton runtime stack',
          'compatibilityTarget': 'linux-wine-runtime-stack',
          'isComplete': dxvkAvailable,
          'backends': <Object?>[
            _runtimeStackBackendPayload(
              id: 'dxvk',
              name: 'DXVK',
              role: 'd3d9-d3d11-vulkan-translation',
              componentIds: const <String>['dxvk'],
              isAvailable: dxvkAvailable,
              missingPaths: dxvkAvailable
                  ? const <String>[]
                  : ['/runtime/dxvk/x64/dxgi.dll'],
            ),
            _runtimeStackBackendPayload(
              id: 'vkd3d-proton',
              name: 'vkd3d-proton',
              role: 'd3d12-vulkan-translation',
              componentIds: const <String>['vkd3d-proton'],
            ),
          ],
          'components': <Object?>[
            _runtimeStackComponentPayload(
              id: 'wine',
              name: 'Wine',
              role: 'windows-runner',
            ),
            _runtimeStackComponentPayload(
              id: 'winetricks',
              name: 'winetricks',
              role: 'verb-installer',
            ),
            _runtimeStackComponentPayload(
              id: 'wine-mono',
              name: 'wine-mono',
              role: 'dotnet-runtime',
            ),
            _runtimeStackComponentPayload(
              id: 'dxvk',
              name: 'DXVK',
              role: 'd3d9-d3d11-vulkan-translation',
              missingPaths: dxvkAvailable
                  ? const <String>[]
                  : ['/runtime/dxvk/x64/dxgi.dll'],
            ),
            _runtimeStackComponentPayload(
              id: 'vkd3d-proton',
              name: 'vkd3d-proton',
              role: 'd3d12-vulkan-translation',
            ),
          ],
        },
      },
    ],
  });
}

Map<String, Object?> _runtimeStackBackendPayload({
  required String id,
  required String name,
  required String role,
  required List<String> componentIds,
  bool isAvailable = true,
  List<String> missingComponentIds = const <String>[],
  List<String> missingPaths = const <String>[],
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'role': role,
    'isAvailable': isAvailable,
    'componentIds': componentIds,
    'missingComponentIds': missingComponentIds,
    'missingPaths': missingPaths,
  };
}

Map<String, Object?> _runtimeStackComponentPayload({
  required String id,
  required String name,
  required String role,
  bool isRequired = true,
  String? version,
  List<String> missingPaths = const <String>[],
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'role': role,
    'isRequired': isRequired,
    'isInstalled': missingPaths.isEmpty,
    'paths': const <String>[],
    'missingPaths': missingPaths,
    ...?version == null ? null : <String, Object?>{'version': version},
  };
}

void _writeU16(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setUint16(offset, value, Endian.little);
}

void _writeU32(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setUint32(offset, value, Endian.little);
}

void _writeI32(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setInt32(offset, value, Endian.little);
}

final class _QueuedProcessRunner implements ProcessRunner {
  _QueuedProcessRunner(List<ProcessRunResult> results)
    : _results = List.of(results);

  final List<ProcessRunResult> _results;
  final List<List<String>> argumentsLog = [];

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    void Function(int processId)? onStarted,
    void Function(String line)? onStdoutLine,
  }) async {
    argumentsLog.add(List.unmodifiable(arguments));

    if (_results.isEmpty) {
      return const ProcessRunResult(
        exitCode: 1,
        stdout: '',
        stderr: 'No queued result.',
      );
    }

    return _results.removeAt(0);
  }
}

final class _FutureQueuedProcessRunner implements ProcessRunner {
  _FutureQueuedProcessRunner(
    List<Future<ProcessRunResult>> results, {
    this.startedProcessId,
  }) : _results = List.of(results);

  final List<Future<ProcessRunResult>> _results;
  final int? startedProcessId;
  final List<List<String>> argumentsLog = [];

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    void Function(int processId)? onStarted,
    void Function(String line)? onStdoutLine,
  }) {
    argumentsLog.add(List.unmodifiable(arguments));
    _onStdoutLine = onStdoutLine;
    final processId = startedProcessId;
    if (processId != null) {
      onStarted?.call(processId);
    }

    if (_results.isEmpty) {
      return Future.value(
        const ProcessRunResult(
          exitCode: 1,
          stdout: '',
          stderr: 'No queued result.',
        ),
      );
    }

    return _results.removeAt(0);
  }

  void emitStdoutLine(String line) {
    _onStdoutLine?.call(line);
  }

  void Function(String line)? _onStdoutLine;
}

final class _NoopProgramWindowProbe implements ProgramWindowProbe {
  const _NoopProgramWindowProbe();

  @override
  Future<Set<String>?> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  }) async {
    return null;
  }

  @override
  Future<Set<int>?> runningWineProcessIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcesses = false,
  }) async {
    return null;
  }
}

final class _MutableProgramWindowProbe implements ProgramWindowProbe {
  final Map<String, int> visibleWindowRootProcessIds = <String, int>{};
  final Set<String> visibleWineWindowIds = <String>{};
  final Set<int> runningWineProcessIdSet = <int>{};

  @override
  Future<Set<String>?> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  }) async {
    if ((!platform.isMacOS && !platform.isLinux) ||
        (descendantOfProcessIds.isEmpty && !includeWineProcessWindows)) {
      return null;
    }

    return <String>{
      for (final window in visibleWindowRootProcessIds.entries)
        if (descendantOfProcessIds.contains(window.value)) window.key,
      if (includeWineProcessWindows) ...visibleWineWindowIds,
    };
  }

  @override
  Future<Set<int>?> runningWineProcessIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcesses = false,
  }) async {
    if (!platform.isLinux ||
        (descendantOfProcessIds.isEmpty && !includeWineProcesses)) {
      return null;
    }

    return Set<int>.of(runningWineProcessIdSet);
  }
}

final class _FakeLogReader implements LogReader {
  const _FakeLogReader({required this.logs});

  final Map<String, String> logs;

  @override
  Future<LogReadResult> readLog(String path) async {
    final content = logs[path];
    if (content == null) {
      return LogReadFailure(message: 'Log not found: $path');
    }

    return ReadLog(content: content);
  }
}

final class _FakeIconFileLoader implements IconFileLoader {
  const _FakeIconFileLoader({required this.icons});

  final Map<String, Uint8List> icons;

  @override
  Future<Uint8List?> loadIconBytes(String path) async => icons[path];
}

final class _FakeProgramFilePicker implements ProgramFilePicker {
  const _FakeProgramFilePicker({required this.path, this.initialDirectories});

  final String? path;
  final List<String?>? initialDirectories;

  @override
  Future<String?> pickProgramPath({String? initialDirectory}) async {
    initialDirectories?.add(initialDirectory);
    return path;
  }
}

final class _FakeDirectoryPicker implements DirectoryPicker {
  const _FakeDirectoryPicker({required this.path});

  final String? path;

  @override
  Future<String?> pickDirectoryPath() async => path;
}

final class _FakeGptkWineSourcePicker implements GptkWineSourcePicker {
  const _FakeGptkWineSourcePicker({required this.path});

  final String? path;

  @override
  Future<String?> pickSourcePath() async => path;
}

final class _FakeBottleArchivePicker implements BottleArchivePicker {
  const _FakeBottleArchivePicker({this.importPath, this.exportPath});

  final String? importPath;
  final String? exportPath;

  @override
  Future<String?> pickArchiveToImport() async => importPath;

  @override
  Future<String?> pickArchiveExportPath({required String suggestedName}) async {
    return exportPath;
  }
}
