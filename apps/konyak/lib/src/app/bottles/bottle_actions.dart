import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import 'bottle_action_availability.dart';

class BottleActionPanel extends StatelessWidget {
  const BottleActionPanel({
    super.key,
    required this.bottle,
    required this.showBottleConfigurationAction,
    required this.showBottleProgramsAction,
  });

  final BottleSummary bottle;
  final BottleSummaryActionAvailability showBottleConfigurationAction;
  final BottleSummaryActionAvailability showBottleProgramsAction;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 75),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottleActionPanelRow(
            icon: Icons.list,
            label: localizations.installedPrograms,
            onTap: _actionPanelCallback(
              resolveBottleSummaryAction(
                bottle: bottle,
                action: showBottleProgramsAction,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colors.actionTrailingIcon,
              size: 20,
            ),
          ),
          Divider(height: 1, color: colors.divider, indent: 14),
          _BottleActionPanelRow(
            icon: Icons.settings_outlined,
            label: localizations.bottleConfiguration,
            onTap: _actionPanelCallback(
              resolveBottleSummaryAction(
                bottle: bottle,
                action: showBottleConfigurationAction,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colors.actionTrailingIcon,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

VoidCallback? _actionPanelCallback(BottleTargetActionAvailability action) {
  return switch (action) {
    EnabledBottleTargetActionAvailability(:final invoke) => invoke,
    DisabledBottleTargetActionAvailability() => null,
  };
}

class _BottleActionPanelRow extends StatelessWidget {
  const _BottleActionPanelRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 37,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: colors.mutedText, size: 17),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.mutedText, fontSize: 14),
                ),
              ),
              trailing,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
