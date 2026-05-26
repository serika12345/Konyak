import 'package:flutter/material.dart';

import '../cli/konyak_cli_client.dart';
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
    this.enableBackgroundServices = false,
  }) : platform = platform ?? currentKonyakPlatform(),
       cliClient = cliClient ?? createDefaultKonyakCliClient(),
       logReader = logReader ?? const DartIoLogReader(),
       programFilePicker =
           programFilePicker ?? const FileSelectorProgramFilePicker(),
       directoryPicker = directoryPicker ?? const FileSelectorDirectoryPicker();

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;
  final LogReader logReader;
  final ProgramFilePicker programFilePicker;
  final DirectoryPicker directoryPicker;
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
