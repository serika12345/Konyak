import 'dart:async';

import 'package:flutter/material.dart';

import '../app/dialogs/winetricks_dialog.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_winetricks_result_types.dart';
import '../l10n/konyak_localizations.dart';
import 'home_loader.dart';
import 'home_loader_programs.dart';

extension KonyakHomeLoaderWinetricks on KonyakHomeLoaderState {
  Future<void> showWinetricks(BottleSummary bottle) async {
    updateState(() {
      isLoadingWinetricks = true;
    });

    late final WinetricksVerbListLoadResult listResult;
    try {
      listResult = await widget.cliClient.listWinetricksVerbs();
    } finally {
      if (mounted) {
        updateState(() {
          isLoadingWinetricks = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (listResult) {
      case LoadedWinetricksVerbs(:final categories):
        final decision = winetricksVerbDecisionFromNullable(
          await showDialog<WinetricksVerbDecision>(
            context: context,
            builder: (context) => WinetricksDialog(
              bottleName: bottle.name,
              categories: categories,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        final String verb;
        switch (decision) {
          case InstallWinetricksVerb(:final verbId):
            verb = verbId;
          case CancelledWinetricksDialog():
            return;
        }

        updateState(() {
          winetricksInstallProgressMessage = KonyakLocalizations.of(
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
            updateState(() {
              winetricksInstallProgressMessage = null;
            });
          }
        }

        if (!mounted) {
          return;
        }

        handleProgramRunResult(runResult);
      case WinetricksVerbListLoadFailure(:final message):
        showSnackBar(message);
    }
  }
}
