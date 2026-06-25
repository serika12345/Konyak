import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
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
    final localizations = KonyakLocalizations.of(context);
    final runtimeState = resolveRuntimeSectionState(
      runtimes: runtimes,
      platform: platform,
    );
    final runtime = runtimeState.runtime;
    final stack = runtimeState.stack;

    if (isLoading && (runtime == null || stack == null)) {
      return AppSettingsSection(
        title: localizations.text(title),
        children: [
          AppSettingsDetailRow(
            label: localizations.text('Status'),
            value: localizations.text('Loading'),
          ),
        ],
      );
    }

    if (runtime == null || stack == null) {
      return AppSettingsSection(
        title: localizations.text(title),
        children: [
          AppSettingsDetailRow(
            label: localizations.text('Status'),
            value: localizations.text('Unavailable'),
            detail:
                loadError ??
                localizations.text('No managed runtime stack detected.'),
          ),
          if (onInstallRuntime != null)
            _installButtonBlock(localizations.text('Install'), localizations),
        ],
      );
    }

    return AppSettingsSection(
      title: localizations.text(title),
      children: [
        if (loadError != null)
          AppSettingsDetailRow(
            label: localizations.text('Runtime install'),
            value: localizations.text('Failed'),
            detail: loadError,
          ),
        AppSettingsDetailRow(
          label: runtime.name,
          value: runtime.isInstalled == true
              ? localizations.text('Installed')
              : localizations.text('Not installed'),
          detail: runtime.distributionKind == null
              ? null
              : '${localizations.text('Distribution')}: ${runtime.distributionKind}',
        ),
        AppSettingsDetailRow(
          label: stack.name,
          value: localizations.text(runtimeStackStatusLabel(stack)),
          detail:
              '${localizations.text('Compatibility')}: ${stack.compatibilityTarget}',
          trailing: runtimeState.shouldOfferInstall && onInstallRuntime != null
              ? _installButton(
                  localizations.text(runtimeState.installButtonLabel),
                  localizations,
                )
              : null,
        ),
        for (final component in stack.components)
          AppSettingsDetailRow(
            label: component.name,
            value: localizedComponentStatusLabel(component, localizations),
          ),
        if (platform == 'macos') _gptkInstallPanel(stack, localizations),
      ],
    );
  }

  Widget _installButtonBlock(String label, KonyakLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _installButton(label, localizations),
      ),
    );
  }

  Widget _installButton(String label, KonyakLocalizations localizations) {
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
      label: Text(isInstalling ? localizations.text('Installing') : label),
    );
  }

  Widget _gptkInstallPanel(
    RuntimeStackSummary stack,
    KonyakLocalizations localizations,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.text(
              'D3DMetal is included in Apple Game Porting Toolkit. Konyak does not bundle or redistribute it. Download the GPTK DMG from Apple Developer, select the DMG, and review Apple License.pdf for commercial use or redistribution.',
            ),
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
                label: Text(localizations.text('Open GPTK Source')),
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
                  isInstallingGptkWine
                      ? localizations.text('Importing D3DMetal')
                      : localizations.text('Select GPTK DMG'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String localizedComponentStatusLabel(
  RuntimeStackComponentSummary component,
  KonyakLocalizations localizations,
) {
  final status = component.isInstalled
      ? localizations.text('Installed')
      : localizations.text('Missing');
  if (component.version == null || component.version!.trim().isEmpty) {
    return status;
  }

  return '$status | ${component.version}';
}
