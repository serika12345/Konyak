part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderBottles on _KonyakHomeLoaderState {
  Future<void> _loadBottles() async {
    _updateState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.cliClient.listBottles();

    if (!mounted) {
      return;
    }

    _updateState(() {
      _isLoading = false;

      switch (result) {
        case LoadedBottleList(:final bottles):
          _bottles = bottles;
          _errorMessage = null;
        case BottleListLoadFailure(:final message):
          _errorMessage = message;
      }
    });

    unawaited(_drainPendingExecutableOpenPaths());
  }

  Future<void> _createBottle() async {
    await _createBottleFromDialog();
  }

  Future<BottleSummary?> _createBottleFromDialog() async {
    final input = await showDialog<CreateBottleInput>(
      context: context,
      builder: (context) => const CreateBottleDialog(),
    );

    if (input == null) {
      return null;
    }

    return _createBottleFromInput(input);
  }

  Future<BottleSummary?> _createBottleFromInput(CreateBottleInput input) async {
    _updateState(() {
      _isCreatingBottle = true;
    });

    late final BottleCreateLoadResult result;
    try {
      result = await widget.cliClient.createBottle(
        name: input.name,
        windowsVersion: input.windowsVersion,
      );
    } finally {
      if (mounted) {
        _updateState(() {
          _isCreatingBottle = false;
        });
      }
    }

    if (!mounted) {
      return null;
    }

    switch (result) {
      case CreatedBottle(:final bottle):
        _storeBottle(bottle);
        return bottle;
      case ExistingBottle(:final message) ||
          BottleCreateLoadFailure(:final message):
        _showSnackBar(message);
        return null;
    }
  }

  void _storeBottle(BottleSummary bottle, {String? oldBottleId}) {
    _updateState(() {
      _bottles = oldBottleId == null
          ? upsertBottle(_bottles, bottle)
          : replaceBottle(_bottles, oldBottleId: oldBottleId, bottle: bottle);
      _errorMessage = null;
    });
  }

  void _handleBottleUpdateResult(
    BottleUpdateLoadResult result, {
    String? oldBottleId,
    String Function(BottleSummary bottle)? successMessage,
  }) {
    switch (result) {
      case UpdatedBottle(:final bottle):
        _storeBottle(bottle, oldBottleId: oldBottleId);
        final message = successMessage?.call(bottle);
        if (message != null) {
          _showSnackBar(message);
        }
      case MissingBottleUpdate(:final message) ||
          BottleUpdateLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _setRuntimeSettings({
    required BottleSummary bottle,
    required BottleRuntimeSettingsSummary runtimeSettings,
    required String controlKey,
  }) async {
    if (_pendingRuntimeSettingsControls.containsKey(bottle.id)) {
      return;
    }

    final previousBottle = findSelectedBottle(_bottles, bottle.id) ?? bottle;
    _updateState(() {
      _pendingRuntimeSettingsControls[bottle.id] = controlKey;
      _bottles = upsertBottle(
        _bottles,
        previousBottle.withRuntimeSettings(runtimeSettings),
      );
      _errorMessage = null;
    });

    final BottleUpdateLoadResult result;
    result = await widget.cliClient.setRuntimeSettings(
      bottleId: bottle.id,
      runtimeSettings: runtimeSettings,
    );

    if (!mounted) {
      return;
    }

    String? failureMessage;
    _updateState(() {
      _pendingRuntimeSettingsControls.remove(bottle.id);
      switch (result) {
        case UpdatedBottle(:final bottle):
          _bottles = upsertBottle(_bottles, bottle);
          _errorMessage = null;
        case MissingBottleUpdate(:final message) ||
            BottleUpdateLoadFailure(:final message):
          _bottles = upsertBottle(_bottles, previousBottle);
          _errorMessage = null;
          failureMessage = message;
      }
    });

    final resolvedFailureMessage = failureMessage;
    if (resolvedFailureMessage != null) {
      _showSnackBar(resolvedFailureMessage);
    }
  }

  Future<void> _loadBottleConfiguration(BottleSummary bottle) async {
    await _reloadBottle(bottle);
    await _loadRuntimeCapabilities();
  }

  Future<BottleSummary?> _reloadBottle(BottleSummary bottle) async {
    final result = await widget.cliClient.inspectBottle(bottle.id);

    if (!mounted) {
      return null;
    }

    switch (result) {
      case LoadedBottleDetail(:final bottle):
        _storeBottle(bottle);
        return bottle;
      case MissingBottleDetail(:final message) ||
          BottleDetailLoadFailure(:final message):
        _showSnackBar(message);
        return null;
    }
  }

  Future<void> _loadRuntimeCapabilities() async {
    final result = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedRuntimeList(:final runtimes):
        _setKnownRuntimes(runtimes);
      case RuntimeListLoadFailure():
        _setKnownRuntimes(const <RuntimeSummary>[]);
    }
  }

  Future<void> _deleteBottle(BottleSummary bottle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteBottleDialog(bottleName: bottle.name),
    );

    if (confirmed != true) {
      return;
    }

    await _deleteBottleAfterConfirmation(bottle);
  }

  Future<void> _deleteBottleAfterConfirmation(BottleSummary bottle) async {
    final result = await widget.cliClient.deleteBottle(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case DeletedBottle(:final bottle):
        _updateState(() {
          _bottles = removeBottle(_bottles, bottle.id);
          _errorMessage = null;
        });
        _showSnackBar(
          KonyakLocalizations.of(context).deletedBottle(bottle.name),
        );
      case MissingBottleDelete(:final message):
        _showSnackBar(message);
      case BottleDeleteLoadFailure(:final message):
        _showBottleDeleteFailureSnackBar(bottle: bottle, message: message);
    }
  }

  void _showBottleDeleteFailureSnackBar({
    required BottleSummary bottle,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _showWarningSnackBar(
      message,
      action: SnackBarAction(
        label: KonyakLocalizations.of(context).retry,
        textColor: colorScheme.onErrorContainer,
        onPressed: () {
          final currentBottle =
              findSelectedBottle(_bottles, bottle.id) ?? bottle;
          unawaited(_deleteBottleAfterConfirmation(currentBottle));
        },
      ),
    );
  }

  Future<void> _renameBottle(BottleSummary bottle) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => RenameBottleDialog(bottleName: bottle.name),
    );

    if (name == null) {
      return;
    }

    final result = await widget.cliClient.renameBottle(
      bottleId: bottle.id,
      name: name,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(
      result,
      oldBottleId: bottle.id,
      successMessage: (bottle) =>
          KonyakLocalizations.of(context).renamedBottle(bottle.name),
    );
  }

  Future<void> _moveBottle(BottleSummary bottle) async {
    final path = await showDialog<String>(
      context: context,
      builder: (context) => MoveBottleDialog(
        bottleName: bottle.name,
        initialPath: bottle.path,
        directoryPicker: widget.directoryPicker,
      ),
    );

    if (path == null) {
      return;
    }

    final result = await widget.cliClient.moveBottle(
      bottleId: bottle.id,
      path: path,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(
      result,
      successMessage: (bottle) =>
          KonyakLocalizations.of(context).movedBottle(bottle.name),
    );
  }

  Future<void> _exportBottleArchive(BottleSummary bottle) async {
    final archivePath = await widget.bottleArchivePicker.pickArchiveExportPath(
      suggestedName: '${bottle.id}.konyak-bottle.tar',
    );
    if (archivePath == null) {
      return;
    }

    _updateState(() {
      _archiveProgressMessage = KonyakLocalizations.of(
        context,
      ).exportingBottleArchiveEllipsis;
    });

    late final BottleArchiveExportLoadResult result;
    try {
      result = await widget.cliClient.exportBottleArchive(
        bottleId: bottle.id,
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        _updateState(() {
          _archiveProgressMessage = null;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case ExportedBottleArchive():
        _showSnackBar(
          KonyakLocalizations.of(context).exportedBottle(bottle.name),
        );
      case BottleArchiveExportLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _importBottleArchive() async {
    final archivePath = await widget.bottleArchivePicker.pickArchiveToImport();
    if (archivePath == null) {
      return;
    }

    _updateState(() {
      _archiveProgressMessage = KonyakLocalizations.of(
        context,
      ).importingBottleArchiveEllipsis;
    });

    late final BottleArchiveImportLoadResult result;
    try {
      result = await widget.cliClient.importBottleArchive(
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        _updateState(() {
          _archiveProgressMessage = null;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case ImportedBottleArchive(:final bottle):
        _storeBottle(bottle);
        _showSnackBar(
          KonyakLocalizations.of(context).importedBottle(bottle.name),
        );
      case BottleArchiveImportLoadFailure(:final message):
        _showSnackBar(message);
    }
  }
}
