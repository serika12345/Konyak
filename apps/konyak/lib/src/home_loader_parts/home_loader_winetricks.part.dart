part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderWinetricks on _KonyakHomeLoaderState {
  Future<void> _showWinetricks(BottleSummary bottle) async {
    _updateState(() {
      _isLoadingWinetricks = true;
    });

    late final WinetricksVerbListLoadResult listResult;
    try {
      listResult = await widget.cliClient.listWinetricksVerbs();
    } finally {
      if (mounted) {
        _updateState(() {
          _isLoadingWinetricks = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (listResult) {
      case LoadedWinetricksVerbs(:final categories):
        final verb = await showDialog<String>(
          context: context,
          builder: (context) =>
              WinetricksDialog(bottleName: bottle.name, categories: categories),
        );

        if (!mounted || verb == null) {
          return;
        }

        _updateState(() {
          _winetricksInstallProgressMessage = KonyakLocalizations.of(
            context,
          ).installingVerb(verb);
        });

        late final ProgramRunLoadResult runResult;
        try {
          runResult = await widget.cliClient.runWinetricksVerb(
            bottleId: bottle.id,
            verb: verb,
          );
        } finally {
          if (mounted) {
            _updateState(() {
              _winetricksInstallProgressMessage = null;
            });
          }
        }

        if (!mounted) {
          return;
        }

        _handleProgramRunResult(runResult);
      case WinetricksVerbListLoadFailure(:final message):
        _showSnackBar(message);
    }
  }
}
