import 'dart:async';

import 'package:flutter/material.dart';

import '../app/dialogs/app_settings_dialog.dart';
import '../app/runtime/runtime_platform.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_runtime_result_types.dart';
import '../cli/konyak_cli_settings_commands.dart';
import '../cli/konyak_cli_settings_result_types.dart';
import '../l10n/konyak_localizations.dart';
import '../settings/app_settings_summary.dart';
import 'home_loader.dart';
import 'home_loader_runtimes.dart';

extension KonyakHomeLoaderSettings on KonyakHomeLoaderState {
  Future<void> showSettings() async {
    if (isShowingSettings) {
      return;
    }

    isShowingSettings = true;
    try {
      final result = await widget.cliClient.getAppSettings();

      if (!mounted) {
        return;
      }

      switch (result) {
        case LoadedAppSettings(:final settings):
          appSettings = settings;
          widget.onAppSettingsLoaded(settings);
          await showDialog<void>(
            context: context,
            builder: (context) => AppSettingsDialog(
              platform: widget.platform,
              initialSettings: settings,
              directoryPicker: widget.directoryPicker,
              runtimes: runtimesForPlatform(
                widget.platform,
                knownRuntimes.runtimes,
              ),
              isLoadingRuntimes: !knownRuntimes.isLoaded,
              onLoadRuntimes: knownRuntimes.isLoaded
                  ? null
                  : loadSettingsRuntimes,
              onInstallRuntime: installSettingsRuntime,
              onInstallGptkWine: widget.platform.isMacOS
                  ? installGptkWine
                  : null,
              onOpenGptkPage: widget.platform.isMacOS ? openGptkPage : null,
              onSettingsChanged: setAppSettings,
            ),
          );
        case AppSettingsLoadFailure(:final message):
          showSnackBar(message);
      }
    } finally {
      isShowingSettings = false;
    }
  }

  Future<RuntimeListLoadResult> loadSettingsRuntimes() async {
    final result = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return result;
    }

    switch (result) {
      case LoadedRuntimeList(:final runtimes):
        setKnownRuntimes(runtimes);
      case RuntimeListLoadFailure():
        break;
    }

    return result;
  }

  Future<void> showAbout() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(context).textTheme;
        final localizations = KonyakLocalizations.of(context);

        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/icons/konyak.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text('Konyak', style: textTheme.headlineMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(localizations.runtimeLicensesNotice),
                const SizedBox(height: 24),
                Text(localizations.mitLicense),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Konyak',
                  applicationLegalese: 'MIT License',
                  applicationIcon: Image.asset(
                    'assets/icons/konyak.png',
                    width: 48,
                    height: 48,
                  ),
                );
              },
              child: Text(localizations.viewLicenses),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }

  Future<AppSettingsSummary?> setAppSettings(
    AppSettingsSummary settings,
  ) async {
    final result = await widget.cliClient.setAppSettings(settings: settings);

    if (!mounted) {
      return null;
    }

    switch (result) {
      case LoadedAppSettings(:final settings):
        appSettings = settings;
        widget.onAppearanceModeChanged(settings.appearanceMode);
        widget.onLanguageModeChanged(settings.languageMode);
        return settings;
      case AppSettingsLoadFailure(:final message):
        showSnackBar(message);
        return null;
    }
  }
}
