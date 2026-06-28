import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_platform.dart';
import '../app/runtime/runtime_platform.dart';
import '../app/startup/startup_update_checker.dart';
import '../app/utils/update_labels.dart';
import '../cli/konyak_cli_process_runner.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_runtime_commands.dart';
import '../cli/konyak_cli_runtime_result_types.dart';
import '../cli/konyak_cli_settings_commands.dart';
import '../cli/konyak_cli_settings_result_types.dart';
import '../cli/konyak_cli_update_result_types.dart';
import '../cli/runtime_install_contract.dart';
import '../l10n/konyak_localizations.dart';
import '../runtimes/runtime_summary.dart';
import '../settings/app_settings_summary.dart';
import '../updates/update_check_summary.dart';
import 'home_loader.dart';
import 'home_loader_platform_helpers.dart';

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
        appSettings = settings;
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

  Future<bool> checkConfiguredUpdates(AppSettingsSummary settings) async {
    final result = await StartupUpdateChecker(
      platform: widget.platform,
      cliClient: widget.cliClient,
    ).check(settings);

    if (!mounted) {
      return false;
    }

    final knownRuntimes = result.knownRuntimes;
    if (knownRuntimes != null) {
      setKnownRuntimes(knownRuntimes);
    }

    final labels = result.availableUpdateLabels.toList();
    final konyakUpdate = result.konyakUpdate;
    if (supportsStartupKonyakAppUpdatePrompt(widget.platform) &&
        konyakUpdate != null) {
      labels.remove(updateCheckLabel(konyakUpdate, 'Konyak'));
      final installStarted = await confirmAndInstallAvailableKonyakUpdate(
        konyakUpdate,
      );
      if (!mounted) {
        return installStarted;
      }
      if (installStarted) {
        return true;
      }
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
    final confirmed = await confirmKonyakUpdateInstall(update);
    if (!mounted || !confirmed) {
      return false;
    }

    return installAvailableKonyakUpdate();
  }

  Future<void> checkKonyakUpdateFromMenu() async {
    if (isCheckingKonyakUpdate) {
      return;
    }

    updateState(() {
      isCheckingKonyakUpdate = true;
      konyakUpdateCheckProgressMessage = KonyakLocalizations.of(
        context,
      ).checkingForKonyakUpdatesEllipsis;
    });

    try {
      final result = await widget.cliClient.checkKonyakUpdate();

      if (!mounted) {
        return;
      }

      updateState(() {
        konyakUpdateCheckProgressMessage = null;
      });

      switch (result) {
        case LoadedUpdateCheck(:final update) when update.status == 'available':
          await confirmAndInstallAvailableKonyakUpdate(update);
        case LoadedUpdateCheck(:final update) when update.status == 'current':
          showSnackBar(KonyakLocalizations.of(context).konyakIsUpToDate);
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
          isCheckingKonyakUpdate = false;
          konyakUpdateCheckProgressMessage = null;
        });
      }
    }
  }

  Future<bool> confirmKonyakUpdateInstall(UpdateCheckSummary update) async {
    final latestVersion = update.latestVersion;
    final localizations = KonyakLocalizations.of(context);
    final title = latestVersion == null
        ? localizations.installKonyakUpdateTitle
        : localizations.installKonyakVersionUpdateTitle(latestVersion);
    final message = latestVersion == null
        ? localizations.installKonyakUpdateMessage
        : localizations.installKonyakVersionUpdateMessage(latestVersion);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.install),
          ),
        ],
      ),
    );

    return confirmed ?? false;
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

  void setKnownRuntimes(List<RuntimeSummary> runtimes) {
    if (!mounted) {
      return;
    }

    updateState(() {
      knownRuntimes = List.unmodifiable(runtimes);
      hasLoadedKnownRuntimes = true;
    });
  }

  Future<List<RuntimeSummary>?> loadKnownRuntimes() async {
    final runtimeResult = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return null;
    }

    switch (runtimeResult) {
      case LoadedRuntimeList(:final runtimes):
        setKnownRuntimes(runtimes);
        return runtimes;
      case RuntimeListLoadFailure():
        setKnownRuntimes(const <RuntimeSummary>[]);
        return null;
    }
  }

  Future<RuntimeSummary?> ensureRuntimeForPlatformLoaded() async {
    if (!hasLoadedKnownRuntimes) {
      final runtimes = await loadKnownRuntimes();
      if (!mounted) {
        return null;
      }

      if (runtimes == null) {
        return null;
      }

      return runtimeForPlatform(widget.platform, runtimes);
    }

    return runtimeForPlatform(widget.platform, knownRuntimes);
  }

  Future<void> promptForMissingManagedRuntime() async {
    final managedRuntime = managedRuntimePlatform(widget.platform);
    if (managedRuntime == null) {
      return;
    }

    final runtime = await ensureRuntimeForPlatformLoaded();
    if (!mounted || runtime?.isInstalled == true) {
      return;
    }

    final installResult = await confirmAndInstallManagedRuntime(
      runtimeName: runtime?.name ?? managedRuntime.displayName,
      installRuntime: installManagedRuntimeForPlatform,
    );

    if (!mounted || installResult == null) {
      return;
    }

    switch (installResult) {
      case InstalledRuntime(:final runtime):
        updateState(() {
          knownRuntimes = upsertRuntimeSummary(knownRuntimes, runtime);
          hasLoadedKnownRuntimes = true;
        });
        showSnackBar(
          KonyakLocalizations.of(context).installedRuntime(runtime.name),
        );
      case RuntimeInstallLoadFailure(:final message):
        showSnackBar(
          KonyakLocalizations.of(context).runtimeInstallFailed(message),
        );
    }
  }

  Future<RuntimeInstallLoadResult> installManagedRuntimeForPlatform() {
    return widget.platform.isMacOS
        ? widget.cliClient.installMacosWine(onProgress: setRuntimeProgress)
        : widget.cliClient.installLinuxWine(onProgress: setRuntimeProgress);
  }

  void setRuntimeProgress(RuntimeInstallProgress progress) {
    if (!mounted) {
      return;
    }

    updateState(() {
      runtimeInstallProgressMessage = progress.message;
      runtimeInstallProgressFraction = progress.fraction;
    });
  }

  Future<RuntimeInstallLoadResult?> confirmAndInstallManagedRuntime({
    required String runtimeName,
    required Future<RuntimeInstallLoadResult> Function() installRuntime,
  }) async {
    final confirmed = await confirmRuntimeDownload(runtimeName);
    if (!mounted || !confirmed) {
      return null;
    }

    updateState(() {
      runtimeInstallProgressMessage = KonyakLocalizations.of(
        context,
      ).downloadProgress(runtimeName);
      runtimeInstallProgressFraction = 0;
    });

    try {
      return await installRuntime();
    } finally {
      if (mounted) {
        updateState(() {
          runtimeInstallProgressMessage = null;
          runtimeInstallProgressFraction = null;
        });
      }
    }
  }

  Future<bool> confirmRuntimeDownload(String runtimeName) async {
    final localizations = KonyakLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.downloadRuntimeTitle(runtimeName)),
        content: Text(localizations.downloadRuntimeMessage(runtimeName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.download),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<RuntimeInstallLoadResult> installSettingsRuntime({
    bool reinstall = false,
  }) async {
    final managedRuntime = managedRuntimePlatform(widget.platform);
    if (managedRuntime == null) {
      return RuntimeInstallLoadFailure(
        exitCode: 64,
        message: KonyakLocalizations.of(
          context,
        ).managedRuntimeInstallationIsNotSupported,
        diagnostic: '',
      );
    }

    updateState(() {
      runtimeInstallProgressMessage = KonyakLocalizations.of(
        context,
      ).downloadProgress(managedRuntime.displayName);
      runtimeInstallProgressFraction = 0;
    });

    final RuntimeInstallLoadResult result;
    try {
      result = widget.platform.isMacOS
          ? await widget.cliClient.installMacosWine(
              reinstall: reinstall,
              onProgress: setRuntimeProgress,
            )
          : await widget.cliClient.installLinuxWine(
              reinstall: reinstall,
              onProgress: setRuntimeProgress,
            );
    } finally {
      if (mounted) {
        updateState(() {
          runtimeInstallProgressMessage = null;
          runtimeInstallProgressFraction = null;
        });
      }
    }

    if (!mounted) {
      return result;
    }

    switch (result) {
      case InstalledRuntime(:final runtime):
        updateState(() {
          knownRuntimes = upsertRuntimeSummary(knownRuntimes, runtime);
          hasLoadedKnownRuntimes = true;
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

  Future<RuntimeInstallLoadResult> installGptkWine() async {
    final localizations = KonyakLocalizations.of(context);
    final sourcePath = await widget.gptkWineSourcePicker.pickSourcePath();
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return RuntimeInstallLoadFailure(
        exitCode: 64,
        message: localizations.gptkD3dmetalSourceWasNotSelected,
        diagnostic: '',
      );
    }

    updateState(() {
      runtimeInstallProgressMessage =
          localizations.importingGptkD3dmetalEllipsis;
      runtimeInstallProgressFraction = 0;
    });

    final ProcessRunResult installResult;
    try {
      installResult = await widget.cliClient.installGptkWine(
        sourcePath: sourcePath,
      );
    } finally {
      if (mounted) {
        updateState(() {
          runtimeInstallProgressMessage = null;
          runtimeInstallProgressFraction = null;
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
          updateState(() {
            knownRuntimes = runtimes;
            hasLoadedKnownRuntimes = true;
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

  Future<void> openGptkPage() async {
    const url = 'https://developer.apple.com/games/game-porting-toolkit/';
    final result = await widget.cliClient.openUrl(url);
    if (!mounted || result.exitCode == 0) {
      return;
    }
    showSnackBar(openUrlFailureMessage(result));
  }
}

bool supportsStartupKonyakAppUpdatePrompt(KonyakPlatform platform) {
  return platform.isMacOS || platform.isLinux;
}
