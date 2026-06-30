import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../dialogs/bottle_tools_dialog.dart';
import '../widgets/konyak_bottom_button.dart';
import 'bottle_action_target.dart';

class ProgramConfigurationBottomBar extends StatelessWidget {
  const ProgramConfigurationBottomBar({
    super.key,
    required this.platform,
    required this.bottle,
    required this.program,
    required this.onOpenPinnedProgramLocation,
    required this.onRunProgramPath,
  });

  final KonyakPlatform platform;
  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

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
            label: localizedShowInFileManagerLabel(localizations, platform),
            onPressed: onOpenPinnedProgramLocation == null
                ? null
                : () => onOpenPinnedProgramLocation!(bottle, program),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.runEllipsis,
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
    required this.onOpenBottleLocation,
  });

  final BottleSummary bottle;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;
  final void Function(BottleSummary bottle, String location)?
  onOpenBottleLocation;

  @override
  Widget build(BuildContext context) {
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
          _BottleToolsButton(
            target: BottleActionTarget.bottle(bottle),
            onRunBottleCommand: onRunBottleCommand,
            onOpenBottleLocation: onOpenBottleLocation,
          ),
        ],
      ),
    );
  }
}

class KonyakBottomBar extends StatelessWidget {
  const KonyakBottomBar({
    super.key,
    required this.target,
    required this.onRunProgram,
    required this.onRunBottleCommand,
    required this.onShowWinetricks,
    required this.onOpenBottleLocation,
  });

  final BottleActionTarget target;
  final ValueChanged<BottleSummary>? onRunProgram;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;
  final ValueChanged<BottleSummary>? onShowWinetricks;
  final void Function(BottleSummary bottle, String location)?
  onOpenBottleLocation;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

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
          _BottleToolsButton(
            target: target,
            onRunBottleCommand: onRunBottleCommand,
            onOpenBottleLocation: onOpenBottleLocation,
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.winetricks,
            onPressed: _targetAction(target, onShowWinetricks),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.run,
            onPressed: _targetAction(target, onRunProgram),
          ),
        ],
      ),
    );
  }
}

class _BottleToolsButton extends StatelessWidget {
  const _BottleToolsButton({
    required this.target,
    required this.onRunBottleCommand,
    required this.onOpenBottleLocation,
  });

  final BottleActionTarget target;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;
  final void Function(BottleSummary bottle, String location)?
  onOpenBottleLocation;

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onRunBottleCommand != null || onOpenBottleLocation != null;

    return KonyakBottomButton(
      label: KonyakLocalizations.of(context).tools,
      onPressed: switch (target) {
        SelectedBottleActionTarget(:final bottle) when hasActions =>
          () => _showBottleTools(context, bottle),
        NoBottleActionTarget() || SelectedBottleActionTarget() => null,
      },
    );
  }

  Future<void> _showBottleTools(
    BuildContext context,
    BottleSummary bottle,
  ) async {
    final action = await showDialog<BottleToolAction>(
      context: context,
      builder: (context) => BottleToolsDialog(bottleName: bottle.name),
    );
    if (!context.mounted || action == null) {
      return;
    }

    switch (action.kind) {
      case BottleToolActionKind.command:
        onRunBottleCommand?.call(bottle, action.id);
      case BottleToolActionKind.location:
        onOpenBottleLocation?.call(bottle, action.id);
    }
  }
}

VoidCallback? _targetAction(
  BottleActionTarget target,
  ValueChanged<BottleSummary>? action,
) {
  return switch (target) {
    SelectedBottleActionTarget(:final bottle) when action != null =>
      () => action(bottle),
    NoBottleActionTarget() || SelectedBottleActionTarget() => null,
  };
}
