import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../../runtimes/runtime_summary.dart';
import 'app_settings_dialog_operation_state.dart';
import 'app_settings_rows.dart';
import 'app_settings_runtime_view_model.dart';

class AppSettingsRuntimeSection extends StatelessWidget {
  const AppSettingsRuntimeSection({
    super.key,
    required this.title,
    required this.platform,
    required this.runtimes,
    required this.operationState,
    required this.dialogOperationState,
    required this.onInstallRuntime,
    required this.onInstallGptkWine,
    required this.onOpenGptkPage,
  });

  final String title;
  final String platform;
  final List<RuntimeSummary> runtimes;
  final RuntimeSectionOperationState operationState;
  final AppSettingsDialogOperationState dialogOperationState;
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
    return switch (runtimeState) {
      RuntimeSectionUnavailable()
          when isRuntimeSectionLoading(operationState) =>
        AppSettingsSection(
          title: title,
          children: [
            AppSettingsDetailRow(
              label: localizations.status,
              value: localizations.loading,
            ),
          ],
        ),
      RuntimeSectionUnavailable() => AppSettingsSection(
        title: title,
        children: [
          AppSettingsDetailRow(
            label: localizations.status,
            value: localizations.unavailable,
            detail: runtimeUnavailableDetail(operationState, localizations),
          ),
          if (onInstallRuntime != null)
            _installButtonBlock(localizations.install, localizations),
        ],
      ),
      RuntimeSectionAvailable(
        :final runtime,
        :final stack,
        :final shouldOfferInstall,
        :final installButtonLabel,
      ) =>
        AppSettingsSection(
          title: title,
          children: [
            ...runtimeOperationFailureRows(
              operationState: operationState,
              localizations: localizations,
            ),
            AppSettingsDetailRow(
              label: runtime.name,
              value: runtime.isInstalled == true
                  ? localizations.installed
                  : localizations.notInstalled,
              detail: runtime.distributionKind == null
                  ? null
                  : '${localizations.distribution}: '
                        '${runtime.distributionKind}',
            ),
            AppSettingsDetailRow(
              label: stack.name,
              value: localizedRuntimeStackStatusLabel(
                runtimeStackStatusLabel(stack),
                localizations,
              ),
              detail:
                  '${localizations.compatibility}: '
                  '${stack.compatibilityTarget}',
              trailing: shouldOfferInstall && onInstallRuntime != null
                  ? _installButton(
                      localizedRuntimeInstallButtonLabel(
                        installButtonLabel,
                        localizations,
                      ),
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
        ),
    };
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
    final isInstallingRuntime = isAppSettingsDialogOperationRunning(
      state: dialogOperationState,
      operation: AppSettingsDialogOperation.installingRuntime,
    );
    return FilledButton.icon(
      key: const ValueKey('app-settings-install-runtime-button'),
      onPressed: isInstallingRuntime ? null : onInstallRuntime,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: isInstallingRuntime
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      label: Text(isInstallingRuntime ? localizations.installing : label),
    );
  }

  Widget _gptkInstallPanel(
    RuntimeStackSummary stack,
    KonyakLocalizations localizations,
  ) {
    final isImportingGptkWine = isAppSettingsDialogOperationRunning(
      state: dialogOperationState,
      operation: AppSettingsDialogOperation.importingGptkWine,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.d3dmetalLicenseNotice),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('app-settings-open-gptk-page-button'),
                onPressed: onOpenGptkPage,
                icon: const Icon(Icons.open_in_browser),
                label: Text(localizations.openGptkSource),
              ),
              FilledButton.icon(
                key: const ValueKey('app-settings-install-gptk-wine-button'),
                onPressed: isImportingGptkWine ? null : onInstallGptkWine,
                icon: isImportingGptkWine
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_copy),
                label: Text(
                  isImportingGptkWine
                      ? localizations.importingD3dmetal
                      : localizations.selectGptkDmg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String localizedRuntimeInstallButtonLabel(
  RuntimeInstallButtonLabel label,
  KonyakLocalizations localizations,
) {
  return switch (label) {
    RuntimeInstallButtonLabel.install => localizations.install,
    RuntimeInstallButtonLabel.repair => localizations.repair,
  };
}

String runtimeUnavailableDetail(
  RuntimeSectionOperationState operationState,
  KonyakLocalizations localizations,
) {
  return switch (operationState) {
    RuntimeSectionOperationFailed(:final message) => message,
    RuntimeSectionOperationIdle() =>
      localizations.noManagedRuntimeStackDetected,
    RuntimeSectionLoadingRuntimes() =>
      localizations.noManagedRuntimeStackDetected,
  };
}

List<Widget> runtimeOperationFailureRows({
  required RuntimeSectionOperationState operationState,
  required KonyakLocalizations localizations,
}) {
  return switch (operationState) {
    RuntimeSectionOperationFailed(:final message) => <Widget>[
      AppSettingsDetailRow(
        label: localizations.runtimeInstall,
        value: localizations.failed,
        detail: message,
      ),
    ],
    RuntimeSectionOperationIdle() => const <Widget>[],
    RuntimeSectionLoadingRuntimes() => const <Widget>[],
  };
}

String localizedRuntimeStackStatusLabel(
  RuntimeStackStatusLabel label,
  KonyakLocalizations localizations,
) {
  return switch (label) {
    RuntimeStackStatusLabel.complete => localizations.complete,
    RuntimeStackStatusLabel.incomplete => localizations.incomplete,
    RuntimeStackStatusLabel.partial => localizations.partial,
  };
}

String localizedComponentStatusLabel(
  RuntimeStackComponentSummary component,
  KonyakLocalizations localizations,
) {
  final status = component.isInstalled
      ? localizations.installed
      : localizations.missing;
  return switch (component.version) {
    final String version when version.trim().isNotEmpty => '$status | $version',
    _ => status,
  };
}
