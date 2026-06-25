part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderRuntimes on _KonyakHomeLoaderState {
  Future<void> _initializeBackgroundServices() async {
    if (widget.platform.isLinux) {
      await widget.cliClient.installLinuxFileAssociations();
      if (!mounted) {
        return;
      }
    }

    final result = await widget.cliClient.getAppSettings();

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedAppSettings(:final settings):
        _appSettings = settings;
        widget.onAppSettingsLoaded(settings);
        final appUpdateInstallStarted = await _checkConfiguredUpdates(settings);
        if (appUpdateInstallStarted) {
          return;
        }
        await _promptForMissingManagedRuntime();
      case AppSettingsLoadFailure():
        break;
    }
  }

  Future<bool> _checkConfiguredUpdates(AppSettingsSummary settings) async {
    final result = await StartupUpdateChecker(
      platform: widget.platform,
      cliClient: widget.cliClient,
    ).check(settings);

    if (!mounted) {
      return false;
    }

    final knownRuntimes = result.knownRuntimes;
    if (knownRuntimes != null) {
      _setKnownRuntimes(knownRuntimes);
    }

    final labels = result.availableUpdateLabels.toList();
    final konyakUpdate = result.konyakUpdate;
    if (_supportsStartupKonyakAppUpdatePrompt(widget.platform) &&
        konyakUpdate != null) {
      labels.remove(updateCheckLabel(konyakUpdate, 'Konyak'));
      final installStarted = await _confirmAndInstallAvailableKonyakUpdate(
        konyakUpdate,
      );
      if (!mounted) {
        return installStarted;
      }
      if (installStarted) {
        return true;
      }
    }

    if (labels.isEmpty) {
      return false;
    }

    _showSnackBar(
      KonyakLocalizations.of(context).updatesAvailable(labels.join(', ')),
    );
    return false;
  }

  Future<bool> _confirmAndInstallAvailableKonyakUpdate(
    UpdateCheckSummary update,
  ) async {
    final confirmed = await _confirmKonyakUpdateInstall(update);
    if (!mounted || !confirmed) {
      return false;
    }

    return _installAvailableKonyakUpdate();
  }

  Future<void> _checkKonyakUpdateFromMenu() async {
    if (_isCheckingKonyakUpdate) {
      return;
    }

    _updateState(() {
      _isCheckingKonyakUpdate = true;
      _konyakUpdateCheckProgressMessage = KonyakLocalizations.of(
        context,
      ).checkingForKonyakUpdatesEllipsis;
    });

    try {
      final result = await widget.cliClient.checkKonyakUpdate();

      if (!mounted) {
        return;
      }

      _updateState(() {
        _konyakUpdateCheckProgressMessage = null;
      });

      switch (result) {
        case LoadedUpdateCheck(:final update) when update.status == 'available':
          await _confirmAndInstallAvailableKonyakUpdate(update);
        case LoadedUpdateCheck(:final update) when update.status == 'current':
          _showSnackBar(KonyakLocalizations.of(context).konyakIsUpToDate);
        case LoadedUpdateCheck():
          _showSnackBar(
            KonyakLocalizations.of(context).konyakUpdateStatusIsUnknown,
          );
        case UpdateCheckLoadFailure(:final message):
          _showWarningSnackBar(
            KonyakLocalizations.of(context).konyakUpdateCheckFailed(message),
          );
      }
    } finally {
      if (mounted) {
        _updateState(() {
          _isCheckingKonyakUpdate = false;
          _konyakUpdateCheckProgressMessage = null;
        });
      }
    }
  }

  Future<bool> _confirmKonyakUpdateInstall(UpdateCheckSummary update) async {
    final latestVersion = update.latestVersion;
    final localizations = KonyakLocalizations.of(context);
    final title = latestVersion == null
        ? localizations.installKonyakUpdateTitle
        : localizations.installKonyakVersionUpdateTitle(latestVersion);
    final message = latestVersion == null
        ? localizations.installKonyakUpdateMessage
        : localizations.installKonyakVersionUpdateMessage(latestVersion);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.install),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<bool> _installAvailableKonyakUpdate() async {
    final installResult = await widget.cliClient.installKonyakUpdate();

    if (!mounted) {
      return false;
    }

    switch (installResult) {
      case InstalledUpdate(:final update) when update.status == 'installed':
        _showSnackBar(
          KonyakLocalizations.of(
            context,
          ).installingKonyakUpdate(installedUpdateLabel(update, 'Konyak')),
        );
        return true;
      case InstalledUpdate():
        return false;
      case UpdateInstallLoadFailure(:final message):
        _showSnackBar(
          KonyakLocalizations.of(context).konyakUpdateInstallFailed(message),
        );
        return false;
    }
  }

  void _setKnownRuntimes(List<RuntimeSummary> runtimes) {
    if (!mounted) {
      return;
    }

    _updateState(() {
      _knownRuntimes = List.unmodifiable(runtimes);
      _hasLoadedKnownRuntimes = true;
    });
  }

  Future<List<RuntimeSummary>?> _loadKnownRuntimes() async {
    final runtimeResult = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return null;
    }

    switch (runtimeResult) {
      case LoadedRuntimeList(:final runtimes):
        _setKnownRuntimes(runtimes);
        return runtimes;
      case RuntimeListLoadFailure():
        _setKnownRuntimes(const <RuntimeSummary>[]);
        return null;
    }
  }

  Future<RuntimeSummary?> _ensureRuntimeForPlatformLoaded() async {
    if (!_hasLoadedKnownRuntimes) {
      final runtimes = await _loadKnownRuntimes();
      if (!mounted) {
        return null;
      }

      if (runtimes == null) {
        return null;
      }

      return runtimeForPlatform(widget.platform, runtimes);
    }

    return runtimeForPlatform(widget.platform, _knownRuntimes);
  }

  Future<void> _promptForMissingManagedRuntime() async {
    final managedRuntime = managedRuntimePlatform(widget.platform);
    if (managedRuntime == null) {
      return;
    }

    final runtime = await _ensureRuntimeForPlatformLoaded();
    if (!mounted || runtime?.isInstalled == true) {
      return;
    }

    final installResult = await _confirmAndInstallManagedRuntime(
      runtimeName: runtime?.name ?? managedRuntime.displayName,
      installRuntime: _installManagedRuntimeForPlatform,
    );

    if (!mounted || installResult == null) {
      return;
    }

    switch (installResult) {
      case InstalledRuntime(:final runtime):
        _updateState(() {
          _knownRuntimes = upsertRuntimeSummary(_knownRuntimes, runtime);
          _hasLoadedKnownRuntimes = true;
        });
        _showSnackBar(
          KonyakLocalizations.of(context).installedRuntime(runtime.name),
        );
      case RuntimeInstallLoadFailure(:final message):
        _showSnackBar(
          KonyakLocalizations.of(context).runtimeInstallFailed(message),
        );
    }
  }

  Future<RuntimeInstallLoadResult> _installManagedRuntimeForPlatform() {
    return widget.platform.isMacOS
        ? widget.cliClient.installMacosWine(onProgress: _setRuntimeProgress)
        : widget.cliClient.installLinuxWine(onProgress: _setRuntimeProgress);
  }

  void _setRuntimeProgress(RuntimeInstallProgress progress) {
    if (!mounted) {
      return;
    }

    _updateState(() {
      _runtimeInstallProgressMessage = progress.message;
      _runtimeInstallProgressFraction = progress.fraction;
    });
  }

  Future<RuntimeInstallLoadResult?> _confirmAndInstallManagedRuntime({
    required String runtimeName,
    required Future<RuntimeInstallLoadResult> Function() installRuntime,
  }) async {
    final confirmed = await _confirmRuntimeDownload(runtimeName);
    if (!mounted || !confirmed) {
      return null;
    }

    _updateState(() {
      _runtimeInstallProgressMessage = KonyakLocalizations.of(
        context,
      ).downloadProgress(runtimeName);
      _runtimeInstallProgressFraction = 0;
    });

    try {
      return await installRuntime();
    } finally {
      if (mounted) {
        _updateState(() {
          _runtimeInstallProgressMessage = null;
          _runtimeInstallProgressFraction = null;
        });
      }
    }
  }

  Future<bool> _confirmRuntimeDownload(String runtimeName) async {
    final localizations = KonyakLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.downloadRuntimeTitle(runtimeName)),
        content: Text(localizations.downloadRuntimeMessage(runtimeName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.download),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<RuntimeInstallLoadResult> _installSettingsRuntime({
    bool reinstall = false,
  }) async {
    final managedRuntime = managedRuntimePlatform(widget.platform);
    if (managedRuntime == null) {
      return RuntimeInstallLoadFailure(
        exitCode: 64,
        message: KonyakLocalizations.of(
          context,
        ).managedRuntimeInstallationIsNotSupported,
        diagnostic: '',
      );
    }

    _updateState(() {
      _runtimeInstallProgressMessage = KonyakLocalizations.of(
        context,
      ).downloadProgress(managedRuntime.displayName);
      _runtimeInstallProgressFraction = 0;
    });

    final RuntimeInstallLoadResult result;
    try {
      result = widget.platform.isMacOS
          ? await widget.cliClient.installMacosWine(
              reinstall: reinstall,
              onProgress: _setRuntimeProgress,
            )
          : await widget.cliClient.installLinuxWine(
              reinstall: reinstall,
              onProgress: _setRuntimeProgress,
            );
    } finally {
      if (mounted) {
        _updateState(() {
          _runtimeInstallProgressMessage = null;
          _runtimeInstallProgressFraction = null;
        });
      }
    }

    if (!mounted) {
      return result;
    }

    switch (result) {
      case InstalledRuntime(:final runtime):
        _updateState(() {
          _knownRuntimes = upsertRuntimeSummary(_knownRuntimes, runtime);
          _hasLoadedKnownRuntimes = true;
        });
      case RuntimeInstallLoadFailure():
        break;
    }

    return result;
  }

  Future<void> _reinstallMacosRuntimeFromMenu() async {
    if (!widget.platform.isMacOS) {
      return;
    }

    await _reinstallManagedRuntimeFromMenu();
  }

  Future<void> _reinstallManagedRuntimeFromMenu() async {
    if (!widget.platform.isMacOS && !widget.platform.isLinux) {
      return;
    }

    final result = await _installSettingsRuntime(reinstall: true);
    if (!mounted) {
      return;
    }

    switch (result) {
      case InstalledRuntime(:final runtime):
        _showSnackBar(
          KonyakLocalizations.of(context).reinstalledRuntime(runtime.name),
        );
      case RuntimeInstallLoadFailure(:final message):
        _showSnackBar(
          KonyakLocalizations.of(context).runtimeReinstallFailed(message),
        );
    }
  }

  Future<RuntimeInstallLoadResult> _installGptkWine() async {
    final localizations = KonyakLocalizations.of(context);
    final sourcePath = await widget.gptkWineSourcePicker.pickSourcePath();
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return RuntimeInstallLoadFailure(
        exitCode: 64,
        message: localizations.gptkD3dmetalSourceWasNotSelected,
        diagnostic: '',
      );
    }

    _updateState(() {
      _runtimeInstallProgressMessage =
          localizations.importingGptkD3dmetalEllipsis;
      _runtimeInstallProgressFraction = 0;
    });

    final ProcessRunResult installResult;
    try {
      installResult = await widget.cliClient.installGptkWine(
        sourcePath: sourcePath,
      );
    } finally {
      if (mounted) {
        _updateState(() {
          _runtimeInstallProgressMessage = null;
          _runtimeInstallProgressFraction = null;
        });
      }
    }

    if (installResult.exitCode != 0) {
      return RuntimeInstallLoadFailure(
        exitCode: installResult.exitCode,
        message: _installGptkFailureMessage(
          installResult,
          command: 'install-gptk-wine',
        ),
        diagnostic: installResult.stderr,
      );
    }

    final runtimesResult = await widget.cliClient.listKnownRuntimes();
    switch (runtimesResult) {
      case LoadedRuntimeList(:final runtimes):
        if (mounted) {
          _updateState(() {
            _knownRuntimes = runtimes;
            _hasLoadedKnownRuntimes = true;
          });
        }
        return installedRuntimeForPlatform(runtimes, widget.platform);
      case RuntimeListLoadFailure(
        :final exitCode,
        :final message,
        :final diagnostic,
      ):
        return RuntimeInstallLoadFailure(
          exitCode: exitCode,
          message: message,
          diagnostic: diagnostic,
        );
    }
  }

  Future<void> _openGptkPage() async {
    const url = 'https://developer.apple.com/games/game-porting-toolkit/';
    final result = await widget.cliClient.openUrl(url);
    if (!mounted || result.exitCode == 0) {
      return;
    }
    _showSnackBar(_openUrlFailureMessage(result));
  }
}

bool _supportsStartupKonyakAppUpdatePrompt(KonyakPlatform platform) {
  return platform.isMacOS || platform.isLinux;
}
