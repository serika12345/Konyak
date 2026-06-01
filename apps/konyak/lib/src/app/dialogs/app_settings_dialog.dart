import 'package:flutter/material.dart';

import '../../cli/konyak_cli_client.dart';
import '../../files/directory_picker.dart';
import '../../runtimes/runtime_summary.dart';
import '../../settings/app_settings_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import 'app_settings_rows.dart';
import 'app_settings_runtime_section.dart';

class AppSettingsDialog extends StatefulWidget {
  const AppSettingsDialog({
    super.key,
    required this.platform,
    required this.initialSettings,
    required this.directoryPicker,
    this.runtimes = const <RuntimeSummary>[],
    this.runtimeLoadError,
    this.onInstallRuntime,
    this.onInstallGptkWine,
    this.onOpenGptkPage,
    required this.onSettingsChanged,
  });

  final KonyakPlatform platform;
  final AppSettingsSummary initialSettings;
  final DirectoryPicker directoryPicker;
  final List<RuntimeSummary> runtimes;
  final String? runtimeLoadError;
  final Future<RuntimeInstallLoadResult> Function()? onInstallRuntime;
  final Future<RuntimeInstallLoadResult> Function()? onInstallGptkWine;
  final Future<void> Function()? onOpenGptkPage;
  final Future<AppSettingsSummary?> Function(AppSettingsSummary settings)
  onSettingsChanged;

  @override
  State<AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<AppSettingsDialog> {
  late AppSettingsSummary _settings = widget.initialSettings;
  late List<RuntimeSummary> _runtimes = widget.runtimes;
  late String? _runtimeLoadError = widget.runtimeLoadError;
  bool _isSaving = false;
  bool _isInstallingRuntime = false;
  bool _isInstallingGptkWine = false;

  Future<void> _save(AppSettingsSummary settings) async {
    final previousSettings = _settings;
    setState(() {
      _settings = settings;
      _isSaving = true;
    });

    final savedSettings = await widget.onSettingsChanged(settings);

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = savedSettings ?? previousSettings;
      _isSaving = false;
    });
  }

  Future<void> _browseBottlePath() async {
    final path = await widget.directoryPicker.pickDirectoryPath();
    if (path == null || path.trim().isEmpty) {
      return;
    }

    await _save(_settings.copyWith(defaultBottlePath: path));
  }

  Future<void> _installRuntime() async {
    final installRuntime = widget.onInstallRuntime;
    if (installRuntime == null || _isInstallingRuntime) {
      return;
    }

    setState(() {
      _isInstallingRuntime = true;
      _runtimeLoadError = null;
    });

    final result = await installRuntime();

    if (!mounted) {
      return;
    }

    setState(() {
      switch (result) {
        case InstalledRuntime(:final runtime):
          _runtimes = upsertRuntime(_runtimes, runtime);
          _runtimeLoadError = null;
        case RuntimeInstallLoadFailure(:final message):
          _runtimeLoadError = message;
      }
      _isInstallingRuntime = false;
    });
  }

  Future<void> _installGptkWine() async {
    final installGptkWine = widget.onInstallGptkWine;
    if (installGptkWine == null || _isInstallingGptkWine) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace Wine Runtime?'),
        content: const Text(
          'Importing GPTK-compatible Wine replaces the current macOS Wine '
          'runtime. Existing bottles are kept, but running Wine processes '
          'should be stopped before continuing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('app-settings-confirm-gptk-wine-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace Wine'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isInstallingGptkWine = true;
      _runtimeLoadError = null;
    });

    final result = await installGptkWine();

    if (!mounted) {
      return;
    }

    setState(() {
      switch (result) {
        case InstalledRuntime(:final runtime):
          _runtimes = upsertRuntime(_runtimes, runtime);
          _runtimeLoadError = null;
        case RuntimeInstallLoadFailure(:final message):
          _runtimeLoadError = message;
      }
      _isInstallingGptkWine = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      title: const Center(child: Text('Konyak Settings')),
      scrollable: true,
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSettingsSection(
              title: 'General',
              children: [
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-terminate-wine-switch',
                  ),
                  label: 'Terminate Wine processes when Konyak closes',
                  value: _settings.terminateWineProcessesOnClose,
                  onChanged: _isSaving
                      ? null
                      : (value) => _save(
                          _settings.copyWith(
                            terminateWineProcessesOnClose: value,
                          ),
                        ),
                ),
                AppSettingsAppearanceRow(
                  mode: _settings.appearanceMode,
                  onChanged: _isSaving
                      ? null
                      : (mode) =>
                            _save(_settings.copyWith(appearanceMode: mode)),
                ),
                AppSettingsPathRow(
                  label: 'Default bottle path:',
                  path: _settings.defaultBottlePath,
                  isSaving: _isSaving,
                  onBrowse: _browseBottlePath,
                ),
              ],
            ),
            const SizedBox(height: 26),
            AppSettingsSection(
              title: 'Updates',
              children: [
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-check-konyak-updates-switch',
                  ),
                  label: 'Automatically check for Konyak updates',
                  value: _settings.automaticallyCheckForKonyakUpdates,
                  onChanged: _isSaving
                      ? null
                      : (value) => _save(
                          _settings.copyWith(
                            automaticallyCheckForKonyakUpdates: value,
                          ),
                        ),
                ),
                AppSettingsSwitchRow(
                  switchKey: const ValueKey(
                    'app-settings-check-wine-updates-switch',
                  ),
                  label: 'Automatically check for Konyak Wine updates',
                  value: _settings.automaticallyCheckForWineUpdates,
                  onChanged: _isSaving
                      ? null
                      : (value) => _save(
                          _settings.copyWith(
                            automaticallyCheckForWineUpdates: value,
                          ),
                        ),
                ),
              ],
            ),
            if (showsRuntimeSection(widget.platform)) ...[
              const SizedBox(height: 26),
              AppSettingsRuntimeSection(
                title: runtimeSectionTitle(widget.platform),
                platform: runtimeSectionPlatform(widget.platform),
                runtimes: _runtimes,
                loadError: _runtimeLoadError,
                isInstalling: _isInstallingRuntime,
                isInstallingGptkWine: _isInstallingGptkWine,
                onInstallRuntime: widget.onInstallRuntime == null
                    ? null
                    : _installRuntime,
                onInstallGptkWine: widget.onInstallGptkWine == null
                    ? null
                    : _installGptkWine,
                onOpenGptkPage: widget.onOpenGptkPage,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
