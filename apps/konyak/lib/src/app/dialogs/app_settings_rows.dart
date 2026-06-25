import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../../settings/app_settings_summary.dart';
import '../app_constants.dart';
import '../widgets/konyak_toggle.dart';

class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

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

class AppSettingsSwitchRow extends StatelessWidget {
  const AppSettingsSwitchRow({
    super.key,
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

class AppSettingsAppearanceRow extends StatelessWidget {
  const AppSettingsAppearanceRow({
    super.key,
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
                KonyakLocalizations.of(context).appearance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.text, fontSize: 14),
              ),
            ),
            SegmentedButton<AppAppearanceMode>(
              segments: [
                ButtonSegment<AppAppearanceMode>(
                  value: AppAppearanceMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined, size: 16),
                  label: Text(KonyakLocalizations.of(context).dark),
                ),
                ButtonSegment<AppAppearanceMode>(
                  value: AppAppearanceMode.light,
                  icon: const Icon(Icons.light_mode_outlined, size: 16),
                  label: Text(KonyakLocalizations.of(context).light),
                ),
                ButtonSegment<AppAppearanceMode>(
                  value: AppAppearanceMode.system,
                  icon: const Icon(Icons.computer_outlined, size: 16),
                  label: Text(KonyakLocalizations.of(context).system),
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

class AppSettingsLanguageRow extends StatelessWidget {
  const AppSettingsLanguageRow({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final AppLanguageMode mode;
  final ValueChanged<AppLanguageMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.language,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.text, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<AppLanguageMode>(
                key: const ValueKey('app-settings-language-selector'),
                segments: [
                  ButtonSegment<AppLanguageMode>(
                    value: AppLanguageMode.system,
                    label: Text(
                      _languageModeLabel(localizations, AppLanguageMode.system),
                    ),
                  ),
                  ButtonSegment<AppLanguageMode>(
                    value: AppLanguageMode.english,
                    label: Text(
                      _languageModeLabel(
                        localizations,
                        AppLanguageMode.english,
                      ),
                    ),
                  ),
                  ButtonSegment<AppLanguageMode>(
                    value: AppLanguageMode.japanese,
                    label: Text(
                      _languageModeLabel(
                        localizations,
                        AppLanguageMode.japanese,
                      ),
                    ),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -3,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: colors.border),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

String _languageModeLabel(
  KonyakLocalizations localizations,
  AppLanguageMode mode,
) {
  return switch (mode) {
    AppLanguageMode.system => localizations.systemDefault,
    AppLanguageMode.english => localizations.english,
    AppLanguageMode.japanese => localizations.japanese,
  };
}

class AppSettingsPathRow extends StatelessWidget {
  const AppSettingsPathRow({
    super.key,
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
            child: Text(KonyakLocalizations.of(context).browse),
          ),
        ],
      ),
    );
  }
}

class AppSettingsDetailRow extends StatelessWidget {
  const AppSettingsDetailRow({
    super.key,
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
