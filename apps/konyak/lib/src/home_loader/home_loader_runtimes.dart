import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../app/dialogs/confirmation_decision.dart';
import '../app/dialogs/dialog_decision.dart';
import '../app/runtime/runtime_platform.dart';
import '../cli/konyak_cli_client.dart' show NotifyRuntimeInstallProgress;
import '../cli/konyak_cli_process_runner.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_runtime_commands.dart';
import '../cli/konyak_cli_runtime_result_types.dart';
import '../cli/konyak_cli_settings_commands.dart';
import '../cli/konyak_cli_settings_result_types.dart';
import '../cli/runtime_install_contract.dart';
import '../files/file_path_pick_result.dart';
import '../l10n/konyak_localizations.dart';
import '../runtimes/gptk_import_version.dart';
import '../runtimes/runtime_summary.dart';
import 'app_settings_state.dart';
import 'blocking_progress_state.dart';
import 'home_loader.dart';
import 'home_loader_platform_helpers.dart';
import 'home_loader_updates.dart';
import 'known_runtimes_state.dart';

part 'home_loader_runtimes.freezed.dart';

extension KonyakHomeLoaderRuntimes on KonyakHomeLoaderState {
  Future<void> initializeBackgroundServices() async {
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
        appSettings = AppSettingsState.loaded(settings);
        widget.onAppSettingsLoaded(settings);
        final appUpdateInstallStarted = await checkConfiguredUpdates(settings);
        if (appUpdateInstallStarted) {
          return;
        }
        await promptForMissingManagedRuntime();
      case AppSettingsLoadFailure():
        break;
    }
  }

  void setKnownRuntimes(List<RuntimeSummary> runtimes) {
    if (!mounted) {
      return;
    }

    updateState(() {
      knownRuntimes = KnownRuntimesState.loaded(runtimes);
    });
  }

  Future<KnownRuntimesLoadOutcome> loadKnownRuntimes() async {
    final runtimeResult = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return const KnownRuntimesLoadOutcome.unmounted();
    }

    switch (runtimeResult) {
      case LoadedRuntimeList(:final runtimes):
        setKnownRuntimes(runtimes);
        return KnownRuntimesLoadOutcome.loaded(runtimes);
      case RuntimeListLoadFailure():
        setKnownRuntimes(const <RuntimeSummary>[]);
        return const KnownRuntimesLoadOutcome.failed();
    }
  }

  Future<RuntimeForPlatformLoadOutcome> ensureRuntimeForPlatformLoaded() async {
    if (!knownRuntimes.isLoaded) {
      final runtimesLoad = await loadKnownRuntimes();
      if (!mounted) {
        return const RuntimeForPlatformLoadOutcome.unmounted();
      }

      return switch (runtimesLoad) {
        _LoadedKnownRuntimes(:final runtimes) => runtimeForPlatformLoadOutcome(
          runtimes,
        ),
        _FailedKnownRuntimesLoad() =>
          const RuntimeForPlatformLoadOutcome.loadFailed(),
        _UnmountedKnownRuntimesLoad() =>
          const RuntimeForPlatformLoadOutcome.unmounted(),
      };
    }

    return runtimeForPlatformLoadOutcome(knownRuntimes.runtimes);
  }

  RuntimeForPlatformLoadOutcome runtimeForPlatformLoadOutcome(
    List<RuntimeSummary> runtimes,
  ) {
    return switch (runtimeForPlatformSelection(widget.platform, runtimes)) {
      RuntimeForPlatformFound(:final runtime) =>
        RuntimeForPlatformLoadOutcome.found(runtime),
      RuntimeForPlatformMissing(:final managedRuntime) =>
        RuntimeForPlatformLoadOutcome.missing(managedRuntime),
    };
  }

  Future<void> promptForMissingManagedRuntime() async {
    final runtimeLoad = await ensureRuntimeForPlatformLoaded();

    final String runtimeName;
    switch (runtimeLoad) {
      case FoundRuntimeForPlatformLoad(:final runtime)
          when runtime.isInstalled == true:
      case FailedRuntimeForPlatformLoad():
      case UnmountedRuntimeForPlatformLoad():
        return;
      case FoundRuntimeForPlatformLoad(:final runtime):
        runtimeName = runtime.name;
      case MissingRuntimeForPlatformLoad(:final managedRuntime):
        runtimeName = managedRuntime.displayName;
    }

    final installOutcome = await confirmAndInstallManagedRuntime(
      runtimeName: runtimeName,
      installRuntime: installManagedRuntimeForPlatform,
    );

    switch (installOutcome) {
      case CompletedManagedRuntimeInstall(:final result):
        if (!mounted) {
          return;
        }
        switch (result) {
          case InstalledRuntime(:final runtime):
            updateState(() {
              knownRuntimes = KnownRuntimesState.loaded(
                upsertRuntimeSummary(knownRuntimes.runtimes, runtime),
              );
            });
            showSnackBar(
              KonyakLocalizations.of(context).installedRuntime(runtime.name),
            );
          case RuntimeInstallLoadFailure(:final message):
            showSnackBar(
              KonyakLocalizations.of(context).runtimeInstallFailed(message),
            );
        }
      case CancelledManagedRuntimeInstall():
      case UnmountedManagedRuntimeInstall():
        return;
    }
  }

  Future<RuntimeInstallLoadResult> installManagedRuntimeForPlatform() {
    return widget.platform.isMacOS
        ? widget.cliClient.installMacosWine(
            progressObservation: NotifyRuntimeInstallProgress(
              setRuntimeProgress,
            ),
          )
        : widget.cliClient.installLinuxWine(
            progressObservation: NotifyRuntimeInstallProgress(
              setRuntimeProgress,
            ),
          );
  }

  void setRuntimeProgress(RuntimeInstallProgress progress) {
    if (!mounted) {
      return;
    }

    updateState(() {
      runtimeInstallProgress = BlockingProgressState.determinate(
        message: progress.message,
        progress: progress.fraction,
      );
    });
  }

  Future<ManagedRuntimeInstallOutcome> confirmAndInstallManagedRuntime({
    required String runtimeName,
    required Future<RuntimeInstallLoadResult> Function() installRuntime,
  }) async {
    final decision = await confirmRuntimeDownload(runtimeName);
    if (!mounted) {
      return const ManagedRuntimeInstallOutcome.unmounted();
    }

    switch (decision) {
      case ConfirmedDialogDecision():
        break;
      case CancelledDialogDecision():
        return const ManagedRuntimeInstallOutcome.cancelled();
    }

    updateState(() {
      runtimeInstallProgress = BlockingProgressState.determinate(
        message: KonyakLocalizations.of(context).downloadProgress(runtimeName),
        progress: 0,
      );
    });

    try {
      final result = await installRuntime();
      return mounted
          ? ManagedRuntimeInstallOutcome.completed(result)
          : const ManagedRuntimeInstallOutcome.unmounted();
    } finally {
      if (mounted) {
        updateState(() {
          runtimeInstallProgress = const BlockingProgressState.hidden();
        });
      }
    }
  }

  Future<ConfirmationDecision> confirmRuntimeDownload(
    String runtimeName,
  ) async {
    final localizations = KonyakLocalizations.of(context);
    return showDialogDecision<ConfirmationDecision>(
      context: context,
      dismissedDecision: const ConfirmationDecision.cancelled(),
      builder: (context) => AlertDialog(
        title: Text(localizations.downloadRuntimeTitle(runtimeName)),
        content: Text(localizations.downloadRuntimeMessage(runtimeName)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.cancelled());
            },
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.confirmed());
            },
            child: Text(localizations.download),
          ),
        ],
      ),
    );
  }

  Future<RuntimeInstallLoadResult> installSettingsRuntime({
    bool reinstall = false,
  }) async {
    final managedRuntime = managedRuntimePlatform(widget.platform);

    updateState(() {
      runtimeInstallProgress = BlockingProgressState.determinate(
        message: KonyakLocalizations.of(
          context,
        ).downloadProgress(managedRuntime.displayName),
        progress: 0,
      );
    });

    final RuntimeInstallLoadResult result;
    try {
      result = widget.platform.isMacOS
          ? await widget.cliClient.installMacosWine(
              reinstall: reinstall,
              progressObservation: NotifyRuntimeInstallProgress(
                setRuntimeProgress,
              ),
            )
          : await widget.cliClient.installLinuxWine(
              reinstall: reinstall,
              progressObservation: NotifyRuntimeInstallProgress(
                setRuntimeProgress,
              ),
            );
    } finally {
      if (mounted) {
        updateState(() {
          runtimeInstallProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return result;
    }

    switch (result) {
      case InstalledRuntime(:final runtime):
        updateState(() {
          knownRuntimes = KnownRuntimesState.loaded(
            upsertRuntimeSummary(knownRuntimes.runtimes, runtime),
          );
        });
      case RuntimeInstallLoadFailure():
        break;
    }

    return result;
  }

  Future<void> reinstallMacosRuntimeFromMenu() async {
    if (!widget.platform.isMacOS) {
      return;
    }

    await reinstallManagedRuntimeFromMenu();
  }

  Future<void> reinstallManagedRuntimeFromMenu() async {
    if (!widget.platform.isMacOS && !widget.platform.isLinux) {
      return;
    }

    final result = await installSettingsRuntime(reinstall: true);
    if (!mounted) {
      return;
    }

    switch (result) {
      case InstalledRuntime(:final runtime):
        showSnackBar(
          KonyakLocalizations.of(context).reinstalledRuntime(runtime.name),
        );
      case RuntimeInstallLoadFailure(:final message):
        showSnackBar(
          KonyakLocalizations.of(context).runtimeReinstallFailed(message),
        );
    }
  }

  Future<RuntimeInstallLoadResult> installGptkWine(
    GptkImportVersion version,
  ) async {
    final localizations = KonyakLocalizations.of(context);
    final sourceSelection = await widget.gptkWineSourcePicker.pickSourcePath();
    return switch (sourceSelection) {
      PickedFilePath(:final path) => installGptkWineFromPath(path, version),
      CancelledFilePathPick() => RuntimeInstallLoadFailure(
        exitCode: 64,
        message: localizations.gptkD3dmetalSourceWasNotSelected,
        diagnostic: '',
      ),
    };
  }

  Future<RuntimeInstallLoadResult> installGptkWineFromPath(
    String sourcePath,
    GptkImportVersion version,
  ) async {
    final localizations = KonyakLocalizations.of(context);
    updateState(() {
      runtimeInstallProgress = BlockingProgressState.determinate(
        message: localizations.importingGptkD3dmetalEllipsis,
        progress: 0,
      );
    });

    final ProcessRunResult installResult;
    try {
      installResult = await widget.cliClient.installGptkWine(
        sourcePath: sourcePath,
        version: version,
      );
    } finally {
      if (mounted) {
        updateState(() {
          runtimeInstallProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (installResult.exitCode != 0) {
      return RuntimeInstallLoadFailure(
        exitCode: installResult.exitCode,
        message: installGptkFailureMessage(
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
          setKnownRuntimes(runtimes);
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

  Future<void> openGptkPage() async {
    const url = 'https://developer.apple.com/games/game-porting-toolkit/';
    final result = await widget.cliClient.openUrl(url);
    if (!mounted || result.exitCode == 0) {
      return;
    }
    showSnackBar(openUrlFailureMessage(result));
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class KnownRuntimesLoadOutcome with _$KnownRuntimesLoadOutcome {
  const KnownRuntimesLoadOutcome._();

  const factory KnownRuntimesLoadOutcome.unmounted() =
      _UnmountedKnownRuntimesLoad;

  const factory KnownRuntimesLoadOutcome.failed() = _FailedKnownRuntimesLoad;

  factory KnownRuntimesLoadOutcome.loaded(List<RuntimeSummary> runtimes) {
    return KnownRuntimesLoadOutcome._loaded(List.unmodifiable(runtimes));
  }

  const factory KnownRuntimesLoadOutcome._loaded(
    List<RuntimeSummary> runtimes,
  ) = _LoadedKnownRuntimes;

  List<RuntimeSummary> get runtimes {
    return switch (this) {
      _LoadedKnownRuntimes(:final runtimes) => runtimes,
      _FailedKnownRuntimesLoad() => const <RuntimeSummary>[],
      _UnmountedKnownRuntimesLoad() => const <RuntimeSummary>[],
    };
  }

  bool get isLoaded {
    return switch (this) {
      _LoadedKnownRuntimes() => true,
      _FailedKnownRuntimesLoad() => false,
      _UnmountedKnownRuntimesLoad() => false,
    };
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeForPlatformLoadOutcome
    with _$RuntimeForPlatformLoadOutcome {
  const factory RuntimeForPlatformLoadOutcome.found(RuntimeSummary runtime) =
      FoundRuntimeForPlatformLoad;

  const factory RuntimeForPlatformLoadOutcome.missing(
    ManagedRuntimePlatform managedRuntime,
  ) = MissingRuntimeForPlatformLoad;

  const factory RuntimeForPlatformLoadOutcome.loadFailed() =
      FailedRuntimeForPlatformLoad;

  const factory RuntimeForPlatformLoadOutcome.unmounted() =
      UnmountedRuntimeForPlatformLoad;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ManagedRuntimeInstallOutcome with _$ManagedRuntimeInstallOutcome {
  const factory ManagedRuntimeInstallOutcome.completed(
    RuntimeInstallLoadResult result,
  ) = CompletedManagedRuntimeInstall;

  const factory ManagedRuntimeInstallOutcome.cancelled() =
      CancelledManagedRuntimeInstall;

  const factory ManagedRuntimeInstallOutcome.unmounted() =
      UnmountedManagedRuntimeInstall;
}
