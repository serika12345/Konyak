import 'dart:async';

import 'package:flutter/material.dart';

import '../app/dialogs/process_manager_dialog.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_runtime_commands.dart';
import '../cli/konyak_cli_wine_process_result_types.dart';
import '../l10n/konyak_localizations.dart';
import '../logs/log_reader.dart';
import 'home_loader.dart';

extension KonyakHomeLoaderWineProcesses on KonyakHomeLoaderState {
  Future<void> terminateWineProcessesOnClose() async {
    if (!widget.enableBackgroundServices || hasTerminatedWineProcesses) {
      return;
    }

    final settings = appSettings;
    if (settings == null || !settings.terminateWineProcessesOnClose) {
      return;
    }

    hasTerminatedWineProcesses = true;
    await widget.cliClient.terminateWineProcesses();
  }

  Future<void> terminateBottleProcesses(BottleSummary bottle) async {
    final result = await widget.cliClient.terminateWineProcesses(
      bottleId: bottle.id,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      TerminatedWineProcesses() => KonyakLocalizations.of(
        context,
      ).stoppedProcessesIn(bottle.name),
      WineProcessTerminationLoadFailure(:final message) => message,
    };

    showSnackBar(message);
  }

  Future<void> showProcessManager() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ProcessManagerDialog(
        bottles: bottles,
        onLoadProcesses: widget.cliClient.listWineProcesses,
        onTerminateProcess: (process) {
          return widget.cliClient.terminateWineProcess(
            bottleId: process.bottleId,
            processId: process.processId,
          );
        },
      ),
    );
  }

  Future<void> showLatestLog() async {
    final logPath = latestRunLogPath;
    if (logPath == null) {
      return;
    }

    final result = await widget.logReader.readLog(logPath);

    if (!mounted) {
      return;
    }

    switch (result) {
      case ReadLog(:final content):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(KonyakLocalizations.of(context).latestRunLog),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(child: SelectableText(content)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(KonyakLocalizations.of(context).close),
              ),
            ],
          ),
        );
      case LogReadFailure(:final message):
        showSnackBar(message);
    }
  }
}
