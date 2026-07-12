import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../dialogs/bottle_tools_dialog.dart';
import '../widgets/konyak_bottom_button.dart';
import 'bottle_action_availability.dart';
import 'bottle_action_target.dart';
import 'bottle_tool_action.dart';

class ProgramConfigurationBottomBar extends StatelessWidget {
  const ProgramConfigurationBottomBar({
    super.key,
    required this.platform,
    required this.bottle,
    required this.program,
    required this.openPinnedProgramLocationAction,
    required this.runProgramPathAction,
  });

  final KonyakPlatform platform;
  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final PinnedProgramActionAvailability openPinnedProgramLocationAction;
  final ProgramPathActionAvailability runProgramPathAction;

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
            onPressed: _targetActionCallback(
              resolvePinnedProgramAction(
                bottle: bottle,
                program: program,
                action: openPinnedProgramLocationAction,
              ),
            ),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.runEllipsis,
            onPressed: _targetActionCallback(
              resolveProgramPathAction(
                bottle: bottle,
                program: program,
                action: runProgramPathAction,
              ),
            ),
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
    required this.toolsAction,
  });

  final BottleSummary bottle;
  final BottleToolsActionAvailability toolsAction;

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
            toolsAction: toolsAction,
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
    required this.runProgramAction,
    required this.showProfileManagerAction,
    required this.toolsAction,
    required this.showWinetricksAction,
  });

  final BottleActionTarget target;
  final BottleSummaryActionAvailability runProgramAction;
  final BottleSummaryActionAvailability showProfileManagerAction;
  final BottleToolsActionAvailability toolsAction;
  final BottleSummaryActionAvailability showWinetricksAction;

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
          _BottleToolsButton(target: target, toolsAction: toolsAction),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.profileManager,
            onPressed: _targetActionCallback(
              resolveBottleTargetAction(
                target: target,
                action: showProfileManagerAction,
              ),
            ),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.winetricks,
            onPressed: _targetActionCallback(
              resolveBottleTargetAction(
                target: target,
                action: showWinetricksAction,
              ),
            ),
          ),
          const SizedBox(width: 6),
          KonyakBottomButton(
            label: localizations.run,
            onPressed: _targetActionCallback(
              resolveBottleTargetAction(
                target: target,
                action: runProgramAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleToolsButton extends StatelessWidget {
  const _BottleToolsButton({required this.target, required this.toolsAction});

  final BottleActionTarget target;
  final BottleToolsActionAvailability toolsAction;

  @override
  Widget build(BuildContext context) {
    final targetAction = resolveBottleToolsTargetAction(
      target: target,
      actions: toolsAction,
    );

    return KonyakBottomButton(
      label: KonyakLocalizations.of(context).tools,
      onPressed: switch (targetAction) {
        EnabledBottleToolsTargetActionAvailability() => () => _showBottleTools(
          context,
          targetAction,
        ),
        DisabledBottleToolsTargetActionAvailability() => null,
      },
    );
  }

  Future<void> _showBottleTools(
    BuildContext context,
    EnabledBottleToolsTargetActionAvailability targetAction,
  ) async {
    final action = await showDialog<BottleToolAction>(
      context: context,
      builder: (context) => BottleToolsDialog(
        bottleName: targetAction.bottle.name,
        availableKinds: availableBottleToolActionKinds(targetAction.actions),
      ),
    );
    if (!context.mounted || action == null) {
      return;
    }

    final dispatch = resolveBottleToolActionDispatch(
      bottle: targetAction.bottle,
      actions: targetAction.actions,
      action: action,
    );
    switch (dispatch) {
      case AvailableBottleToolActionDispatch(:final invoke):
        invoke();
      case UnavailableBottleToolActionDispatch():
        return;
    }
  }
}

VoidCallback? _targetActionCallback(BottleTargetActionAvailability action) {
  return switch (action) {
    EnabledBottleTargetActionAvailability(:final invoke) => invoke,
    DisabledBottleTargetActionAvailability() => null,
  };
}
