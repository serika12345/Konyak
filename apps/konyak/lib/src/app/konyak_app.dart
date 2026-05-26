import 'package:flutter/material.dart';

import '../cli/konyak_cli_client.dart';
import '../files/bottle_archive_picker.dart';
import '../files/directory_picker.dart';
import '../files/program_file_picker.dart';
import '../logs/log_reader.dart';
import '../settings/app_settings_summary.dart';
import 'app_constants.dart';
import 'app_platform.dart';
import 'home_loader.dart';

class KonyakApp extends StatefulWidget {
  KonyakApp({
    super.key,
    KonyakPlatform? platform,
    KonyakCliClient? cliClient,
    LogReader? logReader,
    ProgramFilePicker? programFilePicker,
    DirectoryPicker? directoryPicker,
    BottleArchivePicker? bottleArchivePicker,
    this.enableBackgroundServices = false,
  }) : platform = platform ?? currentKonyakPlatform(),
       cliClient = cliClient ?? createDefaultKonyakCliClient(),
       logReader = logReader ?? const DartIoLogReader(),
       programFilePicker =
           programFilePicker ?? const FileSelectorProgramFilePicker(),
       directoryPicker = directoryPicker ?? const FileSelectorDirectoryPicker(),
       bottleArchivePicker =
           bottleArchivePicker ?? const FileSelectorBottleArchivePicker();

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;
  final LogReader logReader;
  final ProgramFilePicker programFilePicker;
  final DirectoryPicker directoryPicker;
  final BottleArchivePicker bottleArchivePicker;
  final bool enableBackgroundServices;

  @override
  State<KonyakApp> createState() => _KonyakAppState();
}

class _KonyakAppState extends State<KonyakApp> {
  AppAppearanceMode _appearanceMode = AppAppearanceMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Konyak',
      theme: konyakThemeData(konyakLightColors),
      darkTheme: konyakThemeData(konyakDarkColors),
      themeMode: switch (_appearanceMode) {
        AppAppearanceMode.dark => ThemeMode.dark,
        AppAppearanceMode.light => ThemeMode.light,
        AppAppearanceMode.system => ThemeMode.system,
      },
      home: KonyakHomeLoader(
        platform: widget.platform,
        cliClient: widget.cliClient,
        logReader: widget.logReader,
        programFilePicker: widget.programFilePicker,
        directoryPicker: widget.directoryPicker,
        bottleArchivePicker: widget.bottleArchivePicker,
        enableBackgroundServices: widget.enableBackgroundServices,
        onAppSettingsLoaded: _handleAppSettingsLoaded,
        onAppearanceModeChanged: _setAppearanceMode,
      ),
    );
  }

  void _handleAppSettingsLoaded(AppSettingsSummary settings) {
    _setAppearanceMode(settings.appearanceMode);
  }

  void _setAppearanceMode(AppAppearanceMode appearanceMode) {
    if (_appearanceMode == appearanceMode) {
      return;
    }

    setState(() {
      _appearanceMode = appearanceMode;
    });
  }
}
