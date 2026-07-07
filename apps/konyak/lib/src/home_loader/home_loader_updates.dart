import 'package:flutter/material.dart';

import '../app/app_platform.dart';
import '../app/dialogs/confirmation_decision.dart';
import '../app/dialogs/dialog_decision.dart';
import '../app/runtime/runtime_platform.dart';
import '../app/startup/startup_update_checker.dart';
import '../app/utils/update_labels.dart';
import '../cli/cli_optional_fields.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_runtime_commands.dart';
import '../cli/konyak_cli_runtime_result_types.dart';
import '../cli/konyak_cli_update_result_types.dart';
import '../l10n/konyak_localizations.dart';
import '../runtimes/runtime_summary.dart';
import '../settings/app_settings_summary.dart';
import '../updates/update_check_summary.dart';
import 'blocking_progress_state.dart';
import 'home_loader.dart';
import 'home_loader_operation_state.dart';
import 'known_runtimes_state.dart';

extension KonyakHomeLoaderUpdates on KonyakHomeLoaderState {
  Future<bool> checkConfiguredUpdates(AppSettingsSummary settings) async {
    final result = await StartupUpdateChecker(
      platform: widget.platform,
      cliClient: widget.cliClient,
    ).check(settings);

    if (!mounted) {
      return false;
    }

    switch (result.knownRuntimesState) {
      case StartupKnownRuntimesLoaded(:final runtimes):
        _setKnownRuntimes(runtimes);
      case StartupKnownRuntimesSkipped():
        break;
    }

    final labels = result.availableUpdateLabels.toList();
    final managedRuntime = managedRuntimePlatform(widget.platform);
    switch (result.konyakUpdateState) {
      case StartupKonyakUpdateAvailable(:final update)
          when supportsStartupKonyakAppUpdatePrompt(widget.platform):
        labels.remove(updateCheckLabel(update, 'Konyak'));
        final installStarted = await confirmAndInstallAvailableKonyakUpdate(
          update,
        );
        if (!mounted) {
          return installStarted;
        }
        if (installStarted) {
          return true;
        }
      case StartupKonyakUpdateAvailable() || StartupKonyakUpdateUnavailable():
        break;
    }

    switch (result.runtimeUpdateState) {
      case StartupRuntimeUpdateAvailable(:final update):
        await confirmAndInstallAvailableRuntimeUpdate(update, managedRuntime);
        if (!mounted) {
          return false;
        }
      case StartupRuntimeUpdateUnavailable():
        break;
    }

    if (labels.isEmpty) {
      return false;
    }

    showSnackBar(
      KonyakLocalizations.of(context).updatesAvailable(labels.join(', ')),
    );
    return false;
  }

  Future<bool> confirmAndInstallAvailableKonyakUpdate(
    UpdateCheckSummary update,
  ) async {
    final decision = await confirmKonyakUpdateInstall(update);
    if (!mounted) {
      return false;
    }

    return switch (decision) {
      ConfirmedDialogDecision() => installAvailableKonyakUpdate(),
      CancelledDialogDecision() => false,
    };
  }

  Future<void> checkKonyakUpdateFromMenu() async {
    if (_isCheckingKonyakUpdate()) {
      return;
    }

    updateState(() {
      operationState = startHomeLoaderOperation(
        state: operationState,
        operation: HomeLoaderOperation.checkingKonyakUpdate,
      );
      konyakUpdateCheckProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).checkingForKonyakUpdatesEllipsis,
      );
    });

    try {
      final result = await widget.cliClient.checkKonyakUpdate();

      if (!mounted) {
        return;
      }

      updateState(() {
        konyakUpdateCheckProgress = const BlockingProgressState.hidden();
      });

      switch (result) {
        case LoadedUpdateCheck(:final update) when update.status == 'available':
          final installStarted = await confirmAndInstallAvailableKonyakUpdate(
            update,
          );
          if (installStarted) {
            return;
          }
          if (!mounted) {
            return;
          }
          await checkManagedRuntimeUpdateFromMenu(
            managedRuntimePlatform(widget.platform),
          );
        case LoadedUpdateCheck(:final update) when update.status == 'current':
          final handledRuntimeUpdate = await checkManagedRuntimeUpdateFromMenu(
            managedRuntimePlatform(widget.platform),
          );
          if (!mounted) {
            return;
          }
          if (!handledRuntimeUpdate) {
            showSnackBar(KonyakLocalizations.of(context).konyakIsUpToDate);
          }
        case LoadedUpdateCheck():
          showSnackBar(
            KonyakLocalizations.of(context).konyakUpdateStatusIsUnknown,
          );
        case UpdateCheckLoadFailure(:final message):
          showWarningSnackBar(
            KonyakLocalizations.of(context).konyakUpdateCheckFailed(message),
          );
      }
    } finally {
      if (mounted) {
        updateState(() {
          operationState = finishHomeLoaderOperation(
            state: operationState,
            operation: HomeLoaderOperation.checkingKonyakUpdate,
          );
          konyakUpdateCheckProgress = const BlockingProgressState.hidden();
        });
      }
    }
  }

  bool _isCheckingKonyakUpdate() {
    return isHomeLoaderOperationRunning(
      state: operationState,
      operation: HomeLoaderOperation.checkingKonyakUpdate,
    );
  }

  Future<ConfirmationDecision> confirmKonyakUpdateInstall(
    UpdateCheckSummary update,
  ) async {
    final localizations = KonyakLocalizations.of(context);
    final (title, message) = switch (update.latestVersion) {
      PresentCliOptionalString(:final value) => (
        localizations.installKonyakVersionUpdateTitle(value),
        localizations.installKonyakVersionUpdateMessage(value),
      ),
      AbsentCliOptionalString() || ExplicitNullCliOptionalString() => (
        localizations.installKonyakUpdateTitle,
        localizations.installKonyakUpdateMessage,
      ),
    };
    return showDialogDecision<ConfirmationDecision>(
      context: context,
      dismissedDecision: const ConfirmationDecision.cancelled(),
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.cancelled());
            },
            child: Text(localizations.notNow),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.confirmed());
            },
            child: Text(localizations.install),
          ),
        ],
      ),
    );
  }

  Future<bool> checkManagedRuntimeUpdateFromMenu(
    ManagedRuntimePlatform managedRuntime,
  ) async {
    final runtimeListResult = await widget.cliClient.listKnownRuntimes();
    if (!mounted) {
      return false;
    }

    switch (runtimeListResult) {
      case LoadedRuntimeList(:final runtimes):
        _setKnownRuntimes(runtimes);
        switch (runtimeForPlatformSelection(widget.platform, runtimes)) {
          case RuntimeForPlatformFound(:final runtime)
              when runtime.isInstalled == true:
            final updateResult = await widget.cliClient.checkRuntimeUpdate(
              managedRuntime.runtimeId,
            );
            if (!mounted) {
              return false;
            }
            switch (updateResult) {
              case LoadedUpdateCheck(:final update)
                  when update.status == 'available':
                await confirmAndInstallAvailableRuntimeUpdate(
                  update,
                  managedRuntime,
                );
                return true;
              case LoadedUpdateCheck(:final update)
                  when update.status == 'current':
                showSnackBar(
                  KonyakLocalizations.of(
                    context,
                  ).runtimeIsUpToDate(managedRuntime.displayName),
                );
                return true;
              case LoadedUpdateCheck():
                showSnackBar(
                  KonyakLocalizations.of(
                    context,
                  ).runtimeUpdateStatusIsUnknown(managedRuntime.displayName),
                );
                return true;
              case UpdateCheckLoadFailure(:final message):
                showWarningSnackBar(
                  KonyakLocalizations.of(context).runtimeUpdateCheckFailed(
                    managedRuntime.displayName,
                    message,
                  ),
                );
                return true;
            }
          case RuntimeForPlatformFound() || RuntimeForPlatformMissing():
            return false;
        }
      case RuntimeListLoadFailure(:final message):
        _setKnownRuntimes(const <RuntimeSummary>[]);
        showWarningSnackBar(
          KonyakLocalizations.of(
            context,
          ).runtimeUpdateCheckFailed(managedRuntime.displayName, message),
        );
        return true;
    }
  }

  Future<ConfirmationDecision> confirmRuntimeUpdateInstall({
    required UpdateCheckSummary update,
    required ManagedRuntimePlatform managedRuntime,
  }) async {
    final localizations = KonyakLocalizations.of(context);
    final (title, message) = switch (update.latestVersion) {
      PresentCliOptionalString(:final value) => (
        localizations.installRuntimeVersionUpdateTitle(
          managedRuntime.displayName,
          value,
        ),
        localizations.installRuntimeVersionUpdateMessage(
          managedRuntime.displayName,
          value,
        ),
      ),
      AbsentCliOptionalString() || ExplicitNullCliOptionalString() => (
        localizations.installRuntimeUpdateTitle(managedRuntime.displayName),
        localizations.installRuntimeUpdateMessage(managedRuntime.displayName),
      ),
    };
    return showDialogDecision<ConfirmationDecision>(
      context: context,
      dismissedDecision: const ConfirmationDecision.cancelled(),
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.cancelled());
            },
            child: Text(localizations.notNow),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.confirmed());
            },
            child: Text(localizations.install),
          ),
        ],
      ),
    );
  }

  Future<bool> confirmAndInstallAvailableRuntimeUpdate(
    UpdateCheckSummary update,
    ManagedRuntimePlatform managedRuntime,
  ) async {
    final decision = await confirmRuntimeUpdateInstall(
      update: update,
      managedRuntime: managedRuntime,
    );
    if (!mounted) {
      return false;
    }

    return switch (decision) {
      ConfirmedDialogDecision() => installAvailableRuntimeUpdate(
        update,
        managedRuntime,
      ),
      CancelledDialogDecision() => false,
    };
  }

  Future<bool> installAvailableRuntimeUpdate(
    UpdateCheckSummary update,
    ManagedRuntimePlatform managedRuntime,
  ) async {
    final installResult = await widget.cliClient.installRuntimeUpdate(
      managedRuntime.runtimeId,
    );

    if (!mounted) {
      return false;
    }

    switch (installResult) {
      case InstalledRuntime(:final runtime):
        _setKnownRuntimes(
          upsertRuntimeSummary(knownRuntimes.runtimes, runtime),
        );
        showSnackBar(
          KonyakLocalizations.of(context).installedRuntimeUpdate(
            updateCheckLabel(update, managedRuntime.displayName),
          ),
        );
        return true;
      case RuntimeInstallLoadFailure(:final message):
        showWarningSnackBar(
          KonyakLocalizations.of(
            context,
          ).runtimeUpdateInstallFailed(managedRuntime.displayName, message),
        );
        return false;
    }
  }

  Future<bool> installAvailableKonyakUpdate() async {
    final installResult = await widget.cliClient.installKonyakUpdate();

    if (!mounted) {
      return false;
    }

    switch (installResult) {
      case InstalledUpdate(:final update) when update.status == 'installed':
        showSnackBar(
          KonyakLocalizations.of(
            context,
          ).installingKonyakUpdate(installedUpdateLabel(update, 'Konyak')),
        );
        return true;
      case InstalledUpdate():
        return false;
      case UpdateInstallLoadFailure(:final message):
        showSnackBar(
          KonyakLocalizations.of(context).konyakUpdateInstallFailed(message),
        );
        return false;
    }
  }

  void _setKnownRuntimes(List<RuntimeSummary> runtimes) {
    if (!mounted) {
      return;
    }

    updateState(() {
      knownRuntimes = KnownRuntimesState.loaded(runtimes);
    });
  }
}

bool supportsStartupKonyakAppUpdatePrompt(KonyakPlatform platform) {
  return platform.isMacOS || platform.isLinux;
}
