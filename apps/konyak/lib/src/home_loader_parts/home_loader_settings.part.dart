part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderSettings on _KonyakHomeLoaderState {
  Future<void> _showSettings() async {
    if (_isShowingSettings) {
      return;
    }

    _isShowingSettings = true;
    try {
      final result = await widget.cliClient.getAppSettings();

      if (!mounted) {
        return;
      }

      switch (result) {
        case LoadedAppSettings(:final settings):
          _appSettings = settings;
          widget.onAppSettingsLoaded(settings);
          final managedRuntime = managedRuntimePlatform(widget.platform);
          await showDialog<void>(
            context: context,
            builder: (context) => AppSettingsDialog(
              platform: widget.platform,
              initialSettings: settings,
              directoryPicker: widget.directoryPicker,
              runtimes: runtimesForPlatform(widget.platform, _knownRuntimes),
              isLoadingRuntimes:
                  managedRuntime != null && !_hasLoadedKnownRuntimes,
              onLoadRuntimes: managedRuntime == null || _hasLoadedKnownRuntimes
                  ? null
                  : _loadSettingsRuntimes,
              onInstallRuntime: managedRuntime != null
                  ? _installSettingsRuntime
                  : null,
              onInstallGptkWine: widget.platform.isMacOS
                  ? _installGptkWine
                  : null,
              onOpenGptkPage: widget.platform.isMacOS ? _openGptkPage : null,
              onSettingsChanged: _setAppSettings,
            ),
          );
        case AppSettingsLoadFailure(:final message):
          _showSnackBar(message);
      }
    } finally {
      _isShowingSettings = false;
    }
  }

  Future<RuntimeListLoadResult> _loadSettingsRuntimes() async {
    final result = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return result;
    }

    switch (result) {
      case LoadedRuntimeList(:final runtimes):
        _setKnownRuntimes(runtimes);
      case RuntimeListLoadFailure():
        break;
    }

    return result;
  }

  Future<void> _showAbout() async {
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

  Future<AppSettingsSummary?> _setAppSettings(
    AppSettingsSummary settings,
  ) async {
    final result = await widget.cliClient.setAppSettings(settings: settings);

    if (!mounted) {
      return null;
    }

    switch (result) {
      case LoadedAppSettings(:final settings):
        _appSettings = settings;
        widget.onAppearanceModeChanged(settings.appearanceMode);
        widget.onLanguageModeChanged(settings.languageMode);
        return settings;
      case AppSettingsLoadFailure(:final message):
        _showSnackBar(message);
        return null;
    }
  }
}
