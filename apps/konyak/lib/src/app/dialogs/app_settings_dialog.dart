import 'package:flutter/material.dart';

import '../../cli/konyak_cli_client.dart';
import '../../files/directory_picker.dart';
import '../../runtimes/runtime_summary.dart';
import '../../settings/app_settings_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../widgets/konyak_toggle.dart';

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
          _runtimes = _upsertRuntime(_runtimes, runtime);
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
          _runtimes = _upsertRuntime(_runtimes, runtime);
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
            _AppSettingsSection(
              title: 'General',
              children: [
                _AppSettingsSwitchRow(
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
                _AppSettingsAppearanceRow(
                  mode: _settings.appearanceMode,
                  onChanged: _isSaving
                      ? null
                      : (mode) =>
                            _save(_settings.copyWith(appearanceMode: mode)),
                ),
                _AppSettingsPathRow(
                  label: 'Default bottle path:',
                  path: _settings.defaultBottlePath,
                  isSaving: _isSaving,
                  onBrowse: _browseBottlePath,
                ),
              ],
            ),
            const SizedBox(height: 26),
            _AppSettingsSection(
              title: 'Updates',
              children: [
                _AppSettingsSwitchRow(
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
                _AppSettingsSwitchRow(
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
            if (_showsRuntimeSection(widget.platform)) ...[
              const SizedBox(height: 26),
              _RuntimeSection(
                title: _runtimeSectionTitle(widget.platform),
                platform: _runtimeSectionPlatform(widget.platform),
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

List<RuntimeSummary> _upsertRuntime(
  List<RuntimeSummary> runtimes,
  RuntimeSummary runtime,
) {
  final updated = <RuntimeSummary>[];
  var replaced = false;
  for (final existingRuntime in runtimes) {
    if (existingRuntime.id == runtime.id) {
      updated.add(runtime);
      replaced = true;
    } else {
      updated.add(existingRuntime);
    }
  }

  if (!replaced) {
    updated.add(runtime);
  }

  return List.unmodifiable(updated);
}

bool _showsRuntimeSection(KonyakPlatform platform) {
  return platform.isMacOS || platform.isLinux;
}

String _runtimeSectionTitle(KonyakPlatform platform) {
  return platform.isMacOS ? 'macOS Runtime' : 'Linux Runtime';
}

String _runtimeSectionPlatform(KonyakPlatform platform) {
  return platform.isMacOS ? 'macos' : 'linux';
}

class _RuntimeSection extends StatelessWidget {
  const _RuntimeSection({
    required this.title,
    required this.platform,
    required this.runtimes,
    required this.loadError,
    required this.isInstalling,
    required this.isInstallingGptkWine,
    required this.onInstallRuntime,
    required this.onInstallGptkWine,
    required this.onOpenGptkPage,
  });

  final String title;
  final String platform;
  final List<RuntimeSummary> runtimes;
  final String? loadError;
  final bool isInstalling;
  final bool isInstallingGptkWine;
  final VoidCallback? onInstallRuntime;
  final VoidCallback? onInstallGptkWine;
  final VoidCallback? onOpenGptkPage;

  @override
  Widget build(BuildContext context) {
    final runtime = runtimes
        .where((runtime) => runtime.platform == platform)
        .fold<RuntimeSummary?>(
          null,
          (selected, runtime) => runtime.stack != null ? runtime : selected,
        );
    final stack = runtime?.stack;

    if (runtime == null || stack == null) {
      return _AppSettingsSection(
        title: title,
        children: [
          _AppSettingsDetailRow(
            label: 'Status',
            value: 'Unavailable',
            detail: loadError ?? 'No managed runtime stack detected.',
          ),
          if (onInstallRuntime != null) _installButtonBlock('Install'),
        ],
      );
    }

    final shouldOfferInstall = runtime.isInstalled != true || !stack.isComplete;
    final installButtonLabel = runtime.isInstalled == true
        ? 'Repair'
        : 'Install';

    return _AppSettingsSection(
      title: title,
      children: [
        if (loadError != null)
          _AppSettingsDetailRow(
            label: 'Runtime install',
            value: 'Failed',
            detail: loadError,
          ),
        _AppSettingsDetailRow(
          label: runtime.name,
          value: runtime.isInstalled == true ? 'Installed' : 'Not installed',
          detail: runtime.distributionKind == null
              ? null
              : 'Distribution: ${runtime.distributionKind}',
        ),
        _AppSettingsDetailRow(
          label: stack.name,
          value: stack.isComplete ? 'Complete' : 'Incomplete',
          detail: 'Compatibility: ${stack.compatibilityTarget}',
          trailing: shouldOfferInstall && onInstallRuntime != null
              ? _installButton(installButtonLabel)
              : null,
        ),
        for (final component in stack.components)
          _AppSettingsDetailRow(
            label: component.name,
            value: _componentStatusLabel(component),
            detail: component.missingPaths.isEmpty
                ? null
                : component.missingPaths.join('\n'),
          ),
        if (platform == 'macos') _gptkInstallPanel(stack),
      ],
    );
  }

  Widget _installButtonBlock(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _installButton(label),
      ),
    );
  }

  Widget _installButton(String label) {
    return FilledButton.icon(
      key: const ValueKey('app-settings-install-runtime-button'),
      onPressed: isInstalling ? null : onInstallRuntime,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: isInstalling
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      label: Text(isInstalling ? 'Installing' : label),
    );
  }

  Widget _gptkInstallPanel(RuntimeStackSummary stack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'D3DMetal is included in Apple Game Porting Toolkit. Konyak does '
            'not bundle or redistribute it. Download a GPTK-compatible Wine '
            'app from the releases page, select the app bundle, and review '
            'Apple License.pdf for commercial use or redistribution.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('app-settings-open-gptk-page-button'),
                onPressed: onOpenGptkPage,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open GPTK releases'),
              ),
              FilledButton.icon(
                key: const ValueKey('app-settings-install-gptk-wine-button'),
                onPressed: isInstallingGptkWine ? null : onInstallGptkWine,
                icon: isInstallingGptkWine
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_copy),
                label: Text(
                  isInstallingGptkWine ? 'Adding GPTK Wine' : 'Select GPTK app',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _componentStatusLabel(RuntimeStackComponentSummary component) {
    final status = component.isInstalled ? 'Installed' : 'Missing';
    if (component.version == null || component.version!.trim().isEmpty) {
      return status;
    }

    return '$status | ${component.version}';
  }
}

class _AppSettingsSection extends StatelessWidget {
  const _AppSettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    color: colors.divider,
                    indent: 14,
                    endIndent: 14,
                  ),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AppSettingsSwitchRow extends StatelessWidget {
  const _AppSettingsSwitchRow({
    required this.switchKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.text, fontSize: 14),
              ),
            ),
            KonyakToggle(key: switchKey, value: value, onChanged: onChanged),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsAppearanceRow extends StatelessWidget {
  const _AppSettingsAppearanceRow({
    required this.mode,
    required this.onChanged,
  });

  final AppAppearanceMode mode;
  final ValueChanged<AppAppearanceMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Appearance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.text, fontSize: 14),
              ),
            ),
            SegmentedButton<AppAppearanceMode>(
              segments: const [
                ButtonSegment<AppAppearanceMode>(
                  value: AppAppearanceMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                  label: Text('Dark'),
                ),
                ButtonSegment<AppAppearanceMode>(
                  value: AppAppearanceMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 16),
                  label: Text('Light'),
                ),
                ButtonSegment<AppAppearanceMode>(
                  value: AppAppearanceMode.system,
                  icon: Icon(Icons.computer_outlined, size: 16),
                  label: Text('System'),
                ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -3,
                ),
                side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.accentText;
                  }
                  return onChanged == null
                      ? colors.buttonDisabledForeground
                      : colors.text;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.accent;
                  }
                  return colors.inputBackground;
                }),
              ),
              onSelectionChanged: onChanged == null
                  ? null
                  : (selection) {
                      final selectedMode = selection.first;
                      if (selectedMode == mode) {
                        return;
                      }
                      onChanged!(selectedMode);
                    },
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsPathRow extends StatelessWidget {
  const _AppSettingsPathRow({
    required this.label,
    required this.path,
    required this.isSaving,
    required this.onBrowse,
  });

  final String label;
  final String path;
  final bool isSaving;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colors.text, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.mutedText, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          TextButton(
            onPressed: isSaving ? null : onBrowse,
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsDetailRow extends StatelessWidget {
  const _AppSettingsDetailRow({
    required this.label,
    required this.value,
    this.detail,
    this.trailing,
  });

  final String label;
  final String value;
  final String? detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colors.text, fontSize: 14)),
                if (detail != null && detail!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    style: TextStyle(color: colors.mutedText, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (trailing == null)
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
                trailing!,
              ],
            ),
        ],
      ),
    );
  }
}
