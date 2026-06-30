import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/dialogs/open_executable_dialog.dart';
import '../bottles/bottle_summary.dart';
import 'bottle_operation_outcome.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';
import 'home_loader_platform_helpers.dart';
import 'home_loader_programs.dart';
import 'home_loader_runtimes.dart';
import 'home_loader_settings.dart';
import 'home_loader_wine_processes.dart';

extension KonyakHomeLoaderExecutables on KonyakHomeLoaderState {
  Future<void> handleMacosMenuMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'openSettings':
        unawaited(showSettings());
        return;
      case 'importBottleArchive':
        unawaited(importBottleArchive());
        return;
      case 'reinstallMacosRuntime':
        unawaited(reinstallMacosRuntimeFromMenu());
        return;
      case 'checkKonyakUpdates':
        unawaited(checkKonyakUpdateFromMenu());
        return;
      case 'openExecutableFiles':
        pendingExecutableOpenPaths.addAll(
          validExecutableOpenPathsFromChannel(call.arguments),
        );
        unawaited(drainPendingExecutableOpenPaths());
        return;
      case 'terminateWineProcessesBeforeQuit':
        await terminateWineProcessesOnClose();
        return;
      default:
        throw MissingPluginException(
          'Unsupported macOS menu method: ${call.method}',
        );
    }
  }

  Future<void> loadPendingExecutableOpenPathsFromPlatform() async {
    if (!widget.platform.isMacOS) {
      return;
    }

    try {
      final arguments = await macosMenuChannel.invokeMethod<Object?>(
        'takePendingExecutableOpenPaths',
      );
      if (!mounted) {
        return;
      }

      pendingExecutableOpenPaths.addAll(
        validExecutableOpenPathsFromChannel(arguments),
      );
      unawaited(drainPendingExecutableOpenPaths());
    } on MissingPluginException {
      return;
    }
  }

  Future<void> drainPendingExecutableOpenPaths() async {
    if (!mounted || isLoading || isHandlingExecutableOpen) {
      return;
    }

    isHandlingExecutableOpen = true;
    try {
      while (mounted && !isLoading && pendingExecutableOpenPaths.isNotEmpty) {
        final programPath = pendingExecutableOpenPaths.removeAt(0);
        await showOpenExecutable(programPath);
      }
    } finally {
      isHandlingExecutableOpen = false;
      if (mounted && !isLoading && pendingExecutableOpenPaths.isNotEmpty) {
        unawaited(drainPendingExecutableOpenPaths());
      }
    }
  }

  Future<void> showOpenExecutable(String programPath) async {
    final autoRunBottle = executableOpenAutoRunBottle();
    if (autoRunBottle != null) {
      await runProgramPath(bottle: autoRunBottle, programPath: programPath);
      return;
    }

    final decision = await showDialog<OpenExecutableDecision>(
      context: context,
      builder: (context) =>
          OpenExecutableDialog(programPath: programPath, bottles: bottles),
    );

    if (!mounted || decision == null) {
      return;
    }

    switch (decision) {
      case RunExecutableInBottle(:final bottle):
        await runProgramPath(bottle: bottle, programPath: programPath);
      case CreateBottleForExecutable():
        final createOutcome = await createBottleFromDialog();
        if (!mounted) {
          return;
        }
        switch (createOutcome) {
          case CompletedBottleOperation(:final bottle):
            await runProgramPath(bottle: bottle, programPath: programPath);
          case CancelledBottleOperation():
          case FailedBottleOperation():
          case UnmountedBottleOperation():
            return;
        }
    }
  }

  BottleSummary? executableOpenAutoRunBottle() {
    final bottleId = widget.executableOpenAutoRunBottleId?.trim();
    if (bottleId == null || bottleId.isEmpty) {
      return null;
    }

    for (final bottle in bottles) {
      if (bottle.id == bottleId) {
        return bottle;
      }
    }

    return null;
  }
}
