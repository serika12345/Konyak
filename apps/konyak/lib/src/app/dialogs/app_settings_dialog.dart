import 'dart:async';

import 'package:flutter/material.dart';

import '../../cli/konyak_cli_client.dart';
import '../../files/directory_picker.dart';
import '../../files/file_path_pick_result.dart';
import '../../l10n/konyak_localizations.dart';
import '../../runtimes/gptk_import_version.dart';
import '../../runtimes/runtime_summary.dart';
import '../../settings/app_settings_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import 'app_settings_dialog_operation_state.dart';
import 'app_settings_rows.dart';
import 'app_settings_runtime_section.dart';
import 'app_settings_runtime_view_model.dart';
import 'app_settings_save_outcome.dart';
import 'confirmation_decision.dart';
import 'dialog_decision.dart';

class AppSettingsDialog extends StatefulWidget {
  const AppSettingsDialog({
    super.key,
    required this.platform,
    required this.initialSettings,
    required this.directoryPicker,
    this.runtimes = const <RuntimeSummary>[],
    this.runtimeOperationState = const RuntimeSectionOperationState.idle(),
    this.onLoadRuntimes,
    this.onInstallRuntime,
    this.onInstallGptkWine,
    this.onOpenGptkPage,
    required this.onSettingsChanged,
  });

  final KonyakPlatform platform;
  final AppSettingsSummary initialSettings;
  final DirectoryPicker directoryPicker;
  final List<RuntimeSummary> runtimes;
  final RuntimeSectionOperationState runtimeOperationState;
  final Future<RuntimeListLoadResult> Function()? onLoadRuntimes;
  final Future<RuntimeInstallLoadResult> Function()? onInstallRuntime;
  final Future<RuntimeInstallLoadResult> Function(GptkImportVersion version)?
  onInstallGptkWine;
  final Future<void> Function()? onOpenGptkPage;
  final Future<AppSettingsSaveOutcome> Function(AppSettingsSummary settings)
  onSettingsChanged;

  @override
  State<AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<AppSettingsDialog> {
  late AppSettingsSummary _settings = widget.initialSettings;
  late List<RuntimeSummary> _runtimes = widget.runtimes;
  late RuntimeSectionOperationState _runtimeOperationState =
      widget.runtimeOperationState;
  AppSettingsDialogOperationState _operationState =
      const AppSettingsDialogOperationState.idle();
  GptkImportVersion _gptkImportVersion = GptkImportVersion.auto;
  String? _gptkImportFailureMessage;

  @override
  void initState() {
    super.initState();
    if (isRuntimeSectionLoading(_runtimeOperationState)) {
      unawaited(_loadRuntimes());
    }
  }

  Future<void> _loadRuntimes() async {
    final loadRuntimes = widget.onLoadRuntimes;
    if (loadRuntimes == null) {
      setState(() {
        _runtimeOperationState = const RuntimeSectionOperationState.idle();
      });
      return;
    }

    final result = await loadRuntimes();

    if (!mounted) {
      return;
    }

    setState(() {
      switch (result) {
        case LoadedRuntimeList(:final runtimes):
          _runtimes = runtimes;
          _runtimeOperationState = const RuntimeSectionOperationState.idle();
        case RuntimeListLoadFailure(:final message):
          _runtimeOperationState = RuntimeSectionOperationState.failed(message);
      }
    });
  }

  Future<void> _save(AppSettingsSummary settings) async {
    final previousSettings = _settings;
    setState(() {
      _settings = settings;
      _operationState = startAppSettingsDialogOperation(
        state: _operationState,
        operation: AppSettingsDialogOperation.savingSettings,
      );
    });

    final saveOutcome = await widget.onSettingsChanged(settings);

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = saveOutcome.settingsOr(previousSettings);
      _operationState = finishAppSettingsDialogOperation(
        state: _operationState,
        operation: AppSettingsDialogOperation.savingSettings,
      );
    });
  }

  Future<void> _browseBottlePath() async {
    final selection = await widget.directoryPicker.pickDirectoryPath();
    switch (selection) {
      case PickedFilePath(:final path):
        await _save(_settings.withDefaultBottlePath(path));
      case CancelledFilePathPick():
        return;
    }
  }

  Future<void> _installRuntime() async {
    final installRuntime = widget.onInstallRuntime;
    if (installRuntime == null ||
        _isOperationRunning(AppSettingsDialogOperation.installingRuntime)) {
      return;
    }

    setState(() {
      _operationState = startAppSettingsDialogOperation(
        state: _operationState,
        operation: AppSettingsDialogOperation.installingRuntime,
      );
      _runtimeOperationState = const RuntimeSectionOperationState.idle();
    });

    final result = await installRuntime();

    if (!mounted) {
      return;
    }

    setState(() {
      switch (result) {
        case InstalledRuntime(:final runtime):
          _runtimes = upsertRuntime(_runtimes, runtime);
          _runtimeOperationState = const RuntimeSectionOperationState.idle();
        case RuntimeInstallLoadFailure(:final message):
          _runtimeOperationState = RuntimeSectionOperationState.failed(message);
      }
      _operationState = finishAppSettingsDialogOperation(
        state: _operationState,
        operation: AppSettingsDialogOperation.installingRuntime,
      );
    });
  }

  Future<void> _installGptkWine() async {
    final installGptkWine = widget.onInstallGptkWine;
    if (installGptkWine == null ||
        _isOperationRunning(AppSettingsDialogOperation.importingGptkWine)) {
      return;
    }

    final localizations = KonyakLocalizations.of(context);
    final decision = await showDialogDecision<ConfirmationDecision>(
      context: context,
      dismissedDecision: const ConfirmationDecision.cancelled(),
      builder: (context) => AlertDialog(
        title: Text(localizations.importD3dmetalBackend),
        content: Text(localizations.importD3dmetalBackendMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.cancelled());
            },
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const ValueKey('app-settings-confirm-gptk-wine-button'),
            onPressed: () {
              Navigator.of(context).pop(const ConfirmationDecision.confirmed());
            },
            child: Text(localizations.importD3dmetal),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }

    switch (decision) {
      case ConfirmedDialogDecision():
        break;
      case CancelledDialogDecision():
        return;
    }

    setState(() {
      _operationState = startAppSettingsDialogOperation(
        state: _operationState,
        operation: AppSettingsDialogOperation.importingGptkWine,
      );
      _runtimeOperationState = const RuntimeSectionOperationState.idle();
      _gptkImportFailureMessage = null;
    });

    final result = await installGptkWine(_gptkImportVersion);

    if (!mounted) {
      return;
    }

    setState(() {
      switch (result) {
        case InstalledRuntime(:final runtime):
          _runtimes = upsertRuntime(_runtimes, runtime);
          _runtimeOperationState = const RuntimeSectionOperationState.idle();
          _gptkImportFailureMessage = null;
        case RuntimeInstallLoadFailure(:final message):
          _runtimeOperationState = RuntimeSectionOperationState.failed(message);
          _gptkImportFailureMessage = message;
      }
      _operationState = finishAppSettingsDialogOperation(
        state: _operationState,
        operation: AppSettingsDialogOperation.importingGptkWine,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);
    final isSaving = _isOperationRunning(
      AppSettingsDialogOperation.savingSettings,
    );

    return AlertDialog(
      key: const ValueKey('app-settings-dialog'),
      backgroundColor: colors.dialogBackground,
      title: Center(child: Text(localizations.konyakSettings)),
      scrollable: true,
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSettingsSection(
              title: localizations.general,
              children: [
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-terminate-wine-switch',
                  ),
                  label: localizations.terminateWineProcessesWhenKonyakCloses,
                  value: _settings.terminateWineProcessesOnClose,
                  onChanged: isSaving
                      ? null
                      : (value) => _save(
                          _settings.withTerminateWineProcessesOnClose(value),
                        ),
                ),
                AppSettingsAppearanceRow(
                  mode: _settings.appearanceMode,
                  onChanged: isSaving
                      ? null
                      : (mode) => _save(_settings.withAppearanceMode(mode)),
                ),
                AppSettingsLanguageRow(
                  mode: _settings.languageMode,
                  onChanged: isSaving
                      ? null
                      : (mode) => _save(_settings.withLanguageMode(mode)),
                ),
                AppSettingsPathRow(
                  label: localizations.defaultBottlePath,
                  path: _settings.defaultBottlePath,
                  isSaving: isSaving,
                  onBrowse: _browseBottlePath,
                ),
              ],
            ),
            const SizedBox(height: 26),
            AppSettingsSection(
              title: localizations.programs,
              children: [
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-auto-pin-new-programs-switch',
                  ),
                  label: localizations.automaticallyPinNewlyInstalledPrograms,
                  value: _settings.automaticallyPinNewInstalledPrograms,
                  onChanged: isSaving
                      ? null
                      : (value) => _save(
                          _settings.withAutomaticallyPinNewInstalledPrograms(
                            value,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            AppSettingsSection(
              title: localizations.updates,
              children: [
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-check-konyak-updates-switch',
                  ),
                  label: localizations.automaticallyCheckForKonyakUpdates,
                  value: _settings.automaticallyCheckForKonyakUpdates,
                  onChanged: isSaving
                      ? null
                      : (value) => _save(
                          _settings.withAutomaticallyCheckForKonyakUpdates(
                            value,
                          ),
                        ),
                ),
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-check-wine-updates-switch',
                  ),
                  label: localizations.automaticallyCheckForKonyakWineUpdates,
                  value: _settings.automaticallyCheckForWineUpdates,
                  onChanged: isSaving
                      ? null
                      : (value) => _save(
                          _settings.withAutomaticallyCheckForWineUpdates(value),
                        ),
                ),
              ],
            ),
            if (showsRuntimeSection(widget.platform)) ...[
              const SizedBox(height: 26),
              AppSettingsRuntimeSection(
                title: localizedRuntimeSectionTitle(
                  widget.platform,
                  localizations,
                ),
                platform: runtimeSectionPlatform(widget.platform),
                runtimes: _runtimes,
                operationState: _runtimeOperationState,
                dialogOperationState: _operationState,
                onInstallRuntime: widget.onInstallRuntime == null
                    ? null
                    : _installRuntime,
                onInstallGptkWine: widget.onInstallGptkWine == null
                    ? null
                    : _installGptkWine,
                onOpenGptkPage: widget.onOpenGptkPage,
                gptkImportVersion: _gptkImportVersion,
                gptkImportFailureMessage: _gptkImportFailureMessage,
                onGptkImportVersionChanged: (version) {
                  setState(() {
                    _gptkImportVersion = version;
                    _gptkImportFailureMessage = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.close),
        ),
      ],
    );
  }

  bool _isOperationRunning(AppSettingsDialogOperation operation) {
    return isAppSettingsDialogOperationRunning(
      state: _operationState,
      operation: operation,
    );
  }
}

String localizedRuntimeSectionTitle(
  KonyakPlatform platform,
  KonyakLocalizations localizations,
) {
  return platform.isMacOS
      ? localizations.macosRuntime
      : localizations.linuxRuntime;
}
