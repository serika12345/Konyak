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
          var knownRuntimes = const <RuntimeSummary>[];
          String? runtimeLoadError;
          final managedRuntime = managedRuntimePlatform(widget.platform);
          if (managedRuntime != null) {
            final runtimeResult = await widget.cliClient.listKnownRuntimes();
            if (!mounted) {
              return;
            }
            switch (runtimeResult) {
              case LoadedRuntimeList(:final runtimes):
                knownRuntimes = runtimesForPlatform(widget.platform, runtimes);
                _knownRuntimes = runtimes;
              case RuntimeListLoadFailure(:final message):
                runtimeLoadError = message;
            }
          }
          await showDialog<void>(
            context: context,
            builder: (context) => AppSettingsDialog(
              platform: widget.platform,
              initialSettings: settings,
              directoryPicker: widget.directoryPicker,
              runtimes: knownRuntimes,
              runtimeLoadError: runtimeLoadError,
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

  Future<void> _showAbout() async {
    showAboutDialog(
      context: context,
      applicationName: 'Konyak',
      applicationVersion: 'Linux preview',
      applicationLegalese: 'MIT License',
      applicationIcon: Image.asset(
        'assets/icons/konyak.png',
        width: 48,
        height: 48,
      ),
      children: const [
        Text('Flutter desktop UI for Konyak.'),
        SizedBox(height: 10),
        Text(
          'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.',
        ),
      ],
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
        return settings;
      case AppSettingsLoadFailure(:final message):
        _showSnackBar(message);
        return null;
    }
  }
}
