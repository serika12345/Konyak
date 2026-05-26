import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';

class BottleActionPanel extends StatelessWidget {
  const BottleActionPanel({
    super.key,
    required this.bottle,
    required this.onShowBottleConfiguration,
    required this.onShowBottlePrograms,
  });

  final BottleSummary bottle;
  final ValueChanged<BottleSummary>? onShowBottleConfiguration;
  final ValueChanged<BottleSummary>? onShowBottlePrograms;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

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
            label: 'Installed Programs',
            onTap: onShowBottlePrograms == null
                ? null
                : () => onShowBottlePrograms!(bottle),
            trailing: Icon(
              Icons.chevron_right,
              color: colors.actionTrailingIcon,
              size: 20,
            ),
          ),
          Divider(height: 1, color: colors.divider, indent: 14),
          _BottleActionPanelRow(
            icon: Icons.settings_outlined,
            label: 'Bottle Configuration',
            onTap: onShowBottleConfiguration == null
                ? null
                : () => onShowBottleConfiguration!(bottle),
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
