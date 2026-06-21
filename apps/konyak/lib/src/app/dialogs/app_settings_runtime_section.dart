import 'package:flutter/material.dart';

import '../../runtimes/runtime_summary.dart';
import 'app_settings_rows.dart';
import 'app_settings_runtime_view_model.dart';

class AppSettingsRuntimeSection extends StatelessWidget {
  const AppSettingsRuntimeSection({
    super.key,
    required this.title,
    required this.platform,
    required this.runtimes,
    required this.isLoading,
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
  final bool isLoading;
  final String? loadError;
  final bool isInstalling;
  final bool isInstallingGptkWine;
  final VoidCallback? onInstallRuntime;
  final VoidCallback? onInstallGptkWine;
  final VoidCallback? onOpenGptkPage;

  @override
  Widget build(BuildContext context) {
    final runtimeState = resolveRuntimeSectionState(
      runtimes: runtimes,
      platform: platform,
    );
    final runtime = runtimeState.runtime;
    final stack = runtimeState.stack;

    if (isLoading && (runtime == null || stack == null)) {
      return AppSettingsSection(
        title: title,
        children: const [
          AppSettingsDetailRow(label: 'Status', value: 'Loading'),
        ],
      );
    }

    if (runtime == null || stack == null) {
      return AppSettingsSection(
        title: title,
        children: [
          AppSettingsDetailRow(
            label: 'Status',
            value: 'Unavailable',
            detail: loadError ?? 'No managed runtime stack detected.',
          ),
          if (onInstallRuntime != null) _installButtonBlock('Install'),
        ],
      );
    }

    return AppSettingsSection(
      title: title,
      children: [
        if (loadError != null)
          AppSettingsDetailRow(
            label: 'Runtime install',
            value: 'Failed',
            detail: loadError,
          ),
        AppSettingsDetailRow(
          label: runtime.name,
          value: runtime.isInstalled == true ? 'Installed' : 'Not installed',
          detail: runtime.distributionKind == null
              ? null
              : 'Distribution: ${runtime.distributionKind}',
        ),
        AppSettingsDetailRow(
          label: stack.name,
          value: stack.isComplete ? 'Complete' : 'Incomplete',
          detail: 'Compatibility: ${stack.compatibilityTarget}',
          trailing: runtimeState.shouldOfferInstall && onInstallRuntime != null
              ? _installButton(runtimeState.installButtonLabel)
              : null,
        ),
        for (final component in stack.components)
          AppSettingsDetailRow(
            label: component.name,
            value: componentStatusLabel(component),
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
            'not bundle or redistribute it. Download the GPTK DMG from Apple '
            'Developer, select the DMG, and review Apple License.pdf for '
            'commercial use or redistribution.',
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
                label: const Text('Open GPTK Source'),
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
                  isInstallingGptkWine ? 'Adding GPTK Wine' : 'Select GPTK DMG',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
