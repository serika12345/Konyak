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
        await _checkConfiguredUpdates(settings);
        await _promptForMissingManagedRuntime();
      case AppSettingsLoadFailure():
        break;
    }
  }

  Future<void> _checkConfiguredUpdates(AppSettingsSummary settings) async {
    final result = await StartupUpdateChecker(
      platform: widget.platform,
      cliClient: widget.cliClient,
    ).check(settings);

    if (!mounted) {
      return;
    }

    final knownRuntimes = result.knownRuntimes;
    if (knownRuntimes != null) {
      _setKnownRuntimes(knownRuntimes);
    }

    if (result.availableUpdateLabels.isEmpty) {
      return;
    }

    _showSnackBar(
      'Updates available: ${result.availableUpdateLabels.join(', ')}',
    );
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
        _showSnackBar('Installed ${runtime.name}');
      case RuntimeInstallLoadFailure(:final message):
        _showSnackBar('Runtime install failed: $message');
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
      _runtimeInstallProgressMessage = 'Downloading $runtimeName...';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $runtimeName?'),
        content: Text(
          'Konyak will download $runtimeName into your Konyak runtime directory. '
          'The runtime is separate from the application and remains under its own license.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
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
      return const RuntimeInstallLoadFailure(
        exitCode: 64,
        message: 'Managed runtime installation is not supported.',
        diagnostic: '',
      );
    }

    _updateState(() {
      _runtimeInstallProgressMessage =
          'Downloading ${managedRuntime.displayName}...';
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
        _showSnackBar('Reinstalled ${runtime.name}');
      case RuntimeInstallLoadFailure(:final message):
        _showSnackBar('Runtime reinstall failed: $message');
    }
  }

  Future<RuntimeInstallLoadResult> _installGptkWine() async {
    final sourcePath = await widget.gptkWineSourcePicker.pickSourcePath();
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return const RuntimeInstallLoadFailure(
        exitCode: 64,
        message: 'GPTK/D3DMetal source was not selected.',
        diagnostic: '',
      );
    }

    _updateState(() {
      _runtimeInstallProgressMessage = 'Importing GPTK/D3DMetal...';
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
