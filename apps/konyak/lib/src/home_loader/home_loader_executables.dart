import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/dialogs/open_executable_dialog.dart';
import '../app/home/bottle_list_load_state.dart';
import 'bottle_operation_outcome.dart';
import 'executable_auto_run_bottle_selection.dart';
import 'executable_open_queue_state.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';
import 'home_loader_operation_state.dart';
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
        switch (executableOpenPathsChannelPayloadFrom(call.arguments)) {
          case ValidExecutableOpenPathsChannelPayload(:final paths):
            executableOpenQueueState = enqueueExecutableOpenPaths(
              state: executableOpenQueueState,
              paths: paths,
            );
            unawaited(drainPendingExecutableOpenPaths());
          case PartialExecutableOpenPathsChannelPayload(:final paths):
            executableOpenQueueState = enqueueExecutableOpenPaths(
              state: executableOpenQueueState,
              paths: paths,
            );
            unawaited(drainPendingExecutableOpenPaths());
          case InvalidExecutableOpenPathsChannelPayload():
            return;
        }
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

      switch (executableOpenPathsChannelPayloadFrom(arguments)) {
        case ValidExecutableOpenPathsChannelPayload(:final paths):
          executableOpenQueueState = enqueueExecutableOpenPaths(
            state: executableOpenQueueState,
            paths: paths,
          );
          unawaited(drainPendingExecutableOpenPaths());
        case PartialExecutableOpenPathsChannelPayload(:final paths):
          executableOpenQueueState = enqueueExecutableOpenPaths(
            state: executableOpenQueueState,
            paths: paths,
          );
          unawaited(drainPendingExecutableOpenPaths());
        case InvalidExecutableOpenPathsChannelPayload():
          return;
      }
    } on MissingPluginException {
      return;
    }
  }

  Future<void> drainPendingExecutableOpenPaths() async {
    if (!mounted ||
        isBottleListLoading(bottleListLoadState) ||
        !hasPendingExecutableOpenPaths(executableOpenQueueState) ||
        _isHandlingExecutableOpen()) {
      return;
    }

    operationState = startHomeLoaderOperation(
      state: operationState,
      operation: HomeLoaderOperation.handlingExecutableOpen,
    );
    try {
      while (mounted &&
          !isBottleListLoading(bottleListLoadState) &&
          hasPendingExecutableOpenPaths(executableOpenQueueState)) {
        switch (dequeueExecutableOpenPath(executableOpenQueueState)) {
          case DequeuedExecutableOpenPath(
            programPath: final programPath,
            state: final nextState,
          ):
            executableOpenQueueState = nextState;
            await showOpenExecutable(programPath);
          case EmptyExecutableOpenQueue(state: final nextState):
            executableOpenQueueState = nextState;
            return;
        }
      }
    } finally {
      operationState = finishHomeLoaderOperation(
        state: operationState,
        operation: HomeLoaderOperation.handlingExecutableOpen,
      );
      if (mounted &&
          !isBottleListLoading(bottleListLoadState) &&
          hasPendingExecutableOpenPaths(executableOpenQueueState)) {
        unawaited(drainPendingExecutableOpenPaths());
      }
    }
  }

  bool _isHandlingExecutableOpen() {
    return isHomeLoaderOperationRunning(
      state: operationState,
      operation: HomeLoaderOperation.handlingExecutableOpen,
    );
  }

  Future<void> showOpenExecutable(String programPath) async {
    switch (executableOpenAutoRunBottle()) {
      case FoundExecutableAutoRunBottle(:final bottle):
        await runProgramPath(bottle: bottle, programPath: programPath);
        return;
      case MissingExecutableAutoRunBottle():
      case DisabledExecutableAutoRunBottle():
        break;
    }

    if (!mounted) {
      return;
    }

    final decision = openExecutableDecisionFromNullable(
      await showDialog<OpenExecutableDecision>(
        context: context,
        builder: (context) =>
            OpenExecutableDialog(programPath: programPath, bottles: bottles),
      ),
    );

    if (!mounted) {
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
      case CancelledOpenExecutableDialog():
        return;
    }
  }

  ExecutableAutoRunBottleSelection executableOpenAutoRunBottle() {
    return switch (widget.executableOpenAutoRunBottleId) {
      null => const ExecutableAutoRunBottleSelection.disabled(),
      final bottleId => selectExecutableAutoRunBottle(
        bottles: bottles,
        bottleId: bottleId,
      ),
    };
  }
}
