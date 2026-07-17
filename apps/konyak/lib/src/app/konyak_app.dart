import 'package:flutter/material.dart';

import '../cli/konyak_cli_client.dart';
import '../files/bottle_archive_picker.dart';
import '../files/directory_picker.dart';
import '../files/gptk_wine_source_picker.dart';
import '../files/install_profile_manifest_picker.dart';
import '../files/program_file_picker.dart';
import '../icons/icon_file_loader.dart';
import '../icons/icon_file_loader_io.dart';
import '../l10n/konyak_localizations.dart';
import '../logs/log_reader.dart';
import '../logs/log_reader_io.dart';
import '../settings/app_settings_summary.dart';
import 'app_constants.dart';
import 'app_platform.dart';
import 'app_platform_io.dart';
import 'home_loader.dart';
import 'programs/program_window_probe.dart';
import 'widgets/icon_file_image.dart';

class KonyakApp extends StatefulWidget {
  KonyakApp({
    super.key,
    KonyakPlatform? platform,
    KonyakCliClient? cliClient,
    LogReader? logReader,
    ProgramFilePicker? programFilePicker,
    DirectoryPicker? directoryPicker,
    GptkWineSourcePicker? gptkWineSourcePicker,
    BottleArchivePicker? bottleArchivePicker,
    InstallProfileManifestPicker? installProfileManifestPicker,
    IconFileLoader? iconFileLoader,
    ProgramWindowProbe? programWindowProbe,
    this.initialExecutablePaths = const <String>[],
    this.executableOpenAutoRunBottleId,
    this.enableBackgroundServices = false,
  }) : platform = platform ?? currentKonyakPlatform(),
       cliClient = cliClient ?? createDefaultKonyakCliClient(),
       logReader = logReader ?? const DartIoLogReader(),
       programFilePicker =
           programFilePicker ?? const FileSelectorProgramFilePicker(),
       directoryPicker = directoryPicker ?? const FileSelectorDirectoryPicker(),
       gptkWineSourcePicker =
           gptkWineSourcePicker ?? const FileSelectorGptkWineSourcePicker(),
       bottleArchivePicker =
           bottleArchivePicker ?? const FileSelectorBottleArchivePicker(),
       installProfileManifestPicker =
           installProfileManifestPicker ??
           const FileSelectorInstallProfileManifestPicker(),
       iconFileLoader = iconFileLoader ?? const DartIoIconFileLoader(),
       programWindowProbe =
           programWindowProbe ?? const NativeProgramWindowProbe();

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;
  final LogReader logReader;
  final ProgramFilePicker programFilePicker;
  final DirectoryPicker directoryPicker;
  final GptkWineSourcePicker gptkWineSourcePicker;
  final BottleArchivePicker bottleArchivePicker;
  final InstallProfileManifestPicker installProfileManifestPicker;
  final IconFileLoader iconFileLoader;
  final ProgramWindowProbe programWindowProbe;
  final List<String> initialExecutablePaths;
  final String? executableOpenAutoRunBottleId;
  final bool enableBackgroundServices;

  @override
  State<KonyakApp> createState() => _KonyakAppState();
}

class _KonyakAppState extends State<KonyakApp> {
  AppAppearanceMode _appearanceMode = AppAppearanceMode.dark;
  AppLanguageMode _languageMode = AppLanguageMode.system;

  @override
  Widget build(BuildContext context) {
    return IconFileLoaderScope(
      loader: widget.iconFileLoader,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Konyak',
        theme: konyakThemeData(konyakLightColors),
        darkTheme: konyakThemeData(konyakDarkColors),
        themeMode: switch (_appearanceMode) {
          AppAppearanceMode.dark => ThemeMode.dark,
          AppAppearanceMode.light => ThemeMode.light,
          AppAppearanceMode.system => ThemeMode.system,
        },
        locale: localeForAppLanguageMode(_languageMode),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        home: KonyakHomeLoader(
          platform: widget.platform,
          cliClient: widget.cliClient,
          logReader: widget.logReader,
          programFilePicker: widget.programFilePicker,
          directoryPicker: widget.directoryPicker,
          gptkWineSourcePicker: widget.gptkWineSourcePicker,
          bottleArchivePicker: widget.bottleArchivePicker,
          installProfileManifestPicker: widget.installProfileManifestPicker,
          programWindowProbe: widget.programWindowProbe,
          initialExecutablePaths: widget.initialExecutablePaths,
          executableOpenAutoRunBottleId: widget.executableOpenAutoRunBottleId,
          enableBackgroundServices: widget.enableBackgroundServices,
          onAppSettingsLoaded: _handleAppSettingsLoaded,
          onAppearanceModeChanged: _setAppearanceMode,
          onLanguageModeChanged: _setLanguageMode,
        ),
      ),
    );
  }

  void _handleAppSettingsLoaded(AppSettingsSummary settings) {
    _setSettingsAppearanceAndLanguage(settings);
  }

  void _setAppearanceMode(AppAppearanceMode appearanceMode) {
    if (_appearanceMode == appearanceMode) {
      return;
    }

    setState(() {
      _appearanceMode = appearanceMode;
    });
  }

  void _setLanguageMode(AppLanguageMode languageMode) {
    if (_languageMode == languageMode) {
      return;
    }

    setState(() {
      _languageMode = languageMode;
    });
  }

  void _setSettingsAppearanceAndLanguage(AppSettingsSummary settings) {
    if (_appearanceMode == settings.appearanceMode &&
        _languageMode == settings.languageMode) {
      return;
    }

    setState(() {
      _appearanceMode = settings.appearanceMode;
      _languageMode = settings.languageMode;
    });
  }
}
