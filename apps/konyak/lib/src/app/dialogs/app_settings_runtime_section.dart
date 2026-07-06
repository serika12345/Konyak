import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../../runtimes/gptk_import_version.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_constants.dart';
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
    required this.gptkImportVersion,
    required this.gptkImportFailureMessage,
    required this.onGptkImportVersionChanged,
  });

  final String title;
  final String platform;
  final List<RuntimeSummary> runtimes;
  final RuntimeSectionOperationState operationState;
  final AppSettingsDialogOperationState dialogOperationState;
  final VoidCallback? onInstallRuntime;
  final VoidCallback? onInstallGptkWine;
  final VoidCallback? onOpenGptkPage;
  final GptkImportVersion gptkImportVersion;
  final String? gptkImportFailureMessage;
  final ValueChanged<GptkImportVersion> onGptkImportVersionChanged;

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
            if (platform == 'macos')
              _gptkInstallPanel(context, stack, localizations),
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
    BuildContext context,
    RuntimeStackSummary stack,
    KonyakLocalizations localizations,
  ) {
    final colors = KonyakThemeColors.of(context);
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
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.gptkInstalledVersion,
                  style: TextStyle(color: colors.mutedText, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                installedGptkD3DMetalVersionLabel(stack, localizations),
                key: const ValueKey(
                  'app-settings-installed-gptk-version-value',
                ),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (gptkImportFailureMessage case final message?
              when message.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    key: const ValueKey(
                      'app-settings-gptk-import-error-message',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(localizations.gptkImportVersion),
          const SizedBox(height: 8),
          SegmentedButton<GptkImportVersion>(
            key: const ValueKey('app-settings-gptk-version-selector'),
            selected: <GptkImportVersion>{gptkImportVersion},
            showSelectedIcon: false,
            onSelectionChanged: isImportingGptkWine
                ? null
                : (selection) {
                    onGptkImportVersionChanged(selection.single);
                  },
            segments: [
              ButtonSegment<GptkImportVersion>(
                value: GptkImportVersion.auto,
                label: Text(
                  localizations.auto,
                  key: const ValueKey('app-settings-gptk-version-auto'),
                ),
              ),
              ButtonSegment<GptkImportVersion>(
                value: GptkImportVersion.gptk3,
                label: Text(
                  localizations.gptkImportVersionGptkThree,
                  key: const ValueKey('app-settings-gptk-version-3'),
                ),
              ),
              ButtonSegment<GptkImportVersion>(
                value: GptkImportVersion.gptk4,
                label: Text(
                  localizations.gptkImportVersionGptkFour,
                  key: const ValueKey('app-settings-gptk-version-4'),
                ),
              ),
            ],
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

String installedGptkD3DMetalVersionLabel(
  RuntimeStackSummary stack,
  KonyakLocalizations localizations,
) {
  final matchingComponents = stack.components.where(
    (component) => component.id == 'gptk-d3dmetal',
  );
  if (matchingComponents.isEmpty) {
    return localizations.notInstalled;
  }

  final component = matchingComponents.first;
  if (!component.isInstalled) {
    return localizations.notInstalled;
  }

  final version = component.version?.trim();
  if (version == null ||
      version.isEmpty ||
      version.toLowerCase() == 'user-provided') {
    return localizations.installed;
  }

  return version;
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
