part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderExecutables on _KonyakHomeLoaderState {
  Future<void> _handleMacosMenuMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'openSettings':
        unawaited(_showSettings());
        return;
      case 'importBottleArchive':
        unawaited(_importBottleArchive());
        return;
      case 'reinstallMacosRuntime':
        unawaited(_reinstallMacosRuntimeFromMenu());
        return;
      case 'checkKonyakUpdates':
        unawaited(_checkKonyakUpdateFromMenu());
        return;
      case 'openExecutableFiles':
        _pendingExecutableOpenPaths.addAll(
          _validExecutableOpenPathsFromChannel(call.arguments),
        );
        unawaited(_drainPendingExecutableOpenPaths());
        return;
      case 'terminateWineProcessesBeforeQuit':
        await _terminateWineProcessesOnClose();
        return;
      default:
        throw MissingPluginException(
          'Unsupported macOS menu method: ${call.method}',
        );
    }
  }

  Future<void> _loadPendingExecutableOpenPathsFromPlatform() async {
    if (!widget.platform.isMacOS) {
      return;
    }

    try {
      final arguments = await _macosMenuChannel.invokeMethod<Object?>(
        'takePendingExecutableOpenPaths',
      );
      if (!mounted) {
        return;
      }

      _pendingExecutableOpenPaths.addAll(
        _validExecutableOpenPathsFromChannel(arguments),
      );
      unawaited(_drainPendingExecutableOpenPaths());
    } on MissingPluginException {
      return;
    }
  }

  Future<void> _drainPendingExecutableOpenPaths() async {
    if (!mounted || _isLoading || _isHandlingExecutableOpen) {
      return;
    }

    _isHandlingExecutableOpen = true;
    try {
      while (mounted && !_isLoading && _pendingExecutableOpenPaths.isNotEmpty) {
        final programPath = _pendingExecutableOpenPaths.removeAt(0);
        await _showOpenExecutable(programPath);
      }
    } finally {
      _isHandlingExecutableOpen = false;
      if (mounted && !_isLoading && _pendingExecutableOpenPaths.isNotEmpty) {
        unawaited(_drainPendingExecutableOpenPaths());
      }
    }
  }

  Future<void> _showOpenExecutable(String programPath) async {
    final autoRunBottle = _executableOpenAutoRunBottle();
    if (autoRunBottle != null) {
      await _runProgramPath(bottle: autoRunBottle, programPath: programPath);
      return;
    }

    final decision = await showDialog<OpenExecutableDecision>(
      context: context,
      builder: (context) =>
          OpenExecutableDialog(programPath: programPath, bottles: _bottles),
    );

    if (!mounted || decision == null) {
      return;
    }

    switch (decision) {
      case RunExecutableInBottle(:final bottle):
        await _runProgramPath(bottle: bottle, programPath: programPath);
      case CreateBottleForExecutable():
        final bottle = await _createBottleFromDialog();
        if (!mounted || bottle == null) {
          return;
        }
        await _runProgramPath(bottle: bottle, programPath: programPath);
    }
  }

  BottleSummary? _executableOpenAutoRunBottle() {
    final bottleId = widget.executableOpenAutoRunBottleId?.trim();
    if (bottleId == null || bottleId.isEmpty) {
      return null;
    }

    for (final bottle in _bottles) {
      if (bottle.id == bottleId) {
        return bottle;
      }
    }

    return null;
  }
}
