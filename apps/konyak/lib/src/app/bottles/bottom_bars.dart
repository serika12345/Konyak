import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../widgets/konyak_bottom_button.dart';

class ProgramConfigurationBottomBar extends StatelessWidget {
  const ProgramConfigurationBottomBar({
    super.key,
    required this.bottle,
    required this.program,
    required this.onOpenPinnedProgramLocation,
    required this.onRunProgramPath,
  });

  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Container(
      key: const ValueKey('program-configuration-bottom-bar'),
      height: 52,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          KonyakBottomButton(
            label: 'Show in Finder',
            onPressed: onOpenPinnedProgramLocation == null
                ? null
                : () => onOpenPinnedProgramLocation!(bottle, program),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: 'Run...',
            onPressed: onRunProgramPath == null
                ? null
                : () => onRunProgramPath!(bottle, program.path),
          ),
        ],
      ),
    );
  }
}

class BottleConfigurationBottomBar extends StatelessWidget {
  const BottleConfigurationBottomBar({
    super.key,
    required this.bottle,
    required this.onRunBottleCommand,
  });

  final BottleSummary? bottle;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;

  @override
  Widget build(BuildContext context) {
    final activeBottle = bottle;
    final colors = KonyakThemeColors.of(context);

    return Container(
      key: const ValueKey('bottle-configuration-bottom-bar'),
      height: 52,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          KonyakBottomButton(
            label: 'Open Control Panel',
            onPressed: activeBottle == null || onRunBottleCommand == null
                ? null
                : () => onRunBottleCommand!(activeBottle, 'control'),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: 'Open Registry Editor',
            onPressed: activeBottle == null || onRunBottleCommand == null
                ? null
                : () => onRunBottleCommand!(activeBottle, 'regedit'),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: 'Open Wine Configuration',
            onPressed: activeBottle == null || onRunBottleCommand == null
                ? null
                : () => onRunBottleCommand!(activeBottle, 'winecfg'),
          ),
        ],
      ),
    );
  }
}

class KonyakBottomBar extends StatelessWidget {
  const KonyakBottomBar({
    super.key,
    required this.bottle,
    required this.onRunProgram,
    required this.onRunBottleCommand,
    required this.onShowWinetricks,
    required this.onOpenBottleLocation,
  });

  final BottleSummary? bottle;
  final ValueChanged<BottleSummary>? onRunProgram;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;
  final ValueChanged<BottleSummary>? onShowWinetricks;
  final void Function(BottleSummary bottle, String location)?
  onOpenBottleLocation;

  @override
  Widget build(BuildContext context) {
    final activeBottle = bottle;
    final colors = KonyakThemeColors.of(context);

    return Container(
      key: const ValueKey('bottom-bar'),
      height: 52,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          KonyakBottomButton(
            label: 'Open C: Drive',
            onPressed: activeBottle == null || onOpenBottleLocation == null
                ? null
                : () => onOpenBottleLocation!(activeBottle, 'c-drive'),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: 'Terminal',
            onPressed: activeBottle == null || onRunBottleCommand == null
                ? null
                : () => onRunBottleCommand!(activeBottle, 'terminal'),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: 'Winetricks',
            onPressed: activeBottle == null || onShowWinetricks == null
                ? null
                : () => onShowWinetricks!(activeBottle),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: 'Run',
            onPressed: activeBottle == null || onRunProgram == null
                ? null
                : () => onRunProgram!(activeBottle),
          ),
        ],
      ),
    );
  }
}
