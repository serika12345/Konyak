import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_constants.dart';
import '../app_platform.dart';
import '../home/bottle_list_load_state.dart';
import '../programs/pinned_programs_section.dart';
import 'bottle_action_availability.dart';
import 'bottle_actions.dart';
import 'bottle_empty_states.dart';
import 'bottle_overview_content.dart';

class BottleOverview extends StatelessWidget {
  const BottleOverview({
    super.key,
    required this.platform,
    required this.content,
    required this.runProgramAction,
    required this.runProgramPathAction,
    required this.pinProgramAction,
    required this.configurePinnedProgramAction,
    required this.unpinProgramAction,
    required this.renamePinnedProgramAction,
    required this.openPinnedProgramLocationAction,
    required this.showBottleConfigurationAction,
    required this.showBottleProgramsAction,
  });

  final KonyakPlatform platform;
  final BottleOverviewContent content;
  final BottleSummaryActionAvailability runProgramAction;
  final ProgramPathActionAvailability runProgramPathAction;
  final BottleSummaryActionAvailability pinProgramAction;
  final PinnedProgramActionAvailability configurePinnedProgramAction;
  final PinnedProgramActionAvailability unpinProgramAction;
  final PinnedProgramActionAvailability renamePinnedProgramAction;
  final PinnedProgramActionAvailability openPinnedProgramLocationAction;
  final BottleSummaryActionAvailability showBottleConfigurationAction;
  final BottleSummaryActionAvailability showBottleProgramsAction;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return switch (content) {
      EmptyBottleOverviewContent(:final loadState) => switch (loadState) {
        BottleListLoading() => Center(
          child: CircularProgressIndicator(color: colors.accent),
        ),
        BottleListLoadFailed(:final message) => BottleLoadFailureState(
          message: message,
        ),
        BottleListLoaded() => const EmptyBottleState(),
      },
      SelectedBottleOverviewContent(:final bottle) => LayoutBuilder(
        builder: (context, constraints) {
          final contentHeight = math.max(
            minimumBottleDetailContentHeight,
            constraints.maxHeight - bottleDetailPadding.vertical,
          );

          return Padding(
            padding: bottleDetailPadding,
            child: SizedBox(
              height: contentHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PinnedProgramsSection(
                    platform: platform,
                    bottle: bottle,
                    pinProgramAction: firstAvailableBottleSummaryAction(
                      preferred: pinProgramAction,
                      fallback: runProgramAction,
                    ),
                    runProgramPathAction: runProgramPathAction,
                    configurePinnedProgramAction: configurePinnedProgramAction,
                    unpinProgramAction: unpinProgramAction,
                    renamePinnedProgramAction: renamePinnedProgramAction,
                    openPinnedProgramLocationAction:
                        openPinnedProgramLocationAction,
                  ),
                  const Spacer(),
                  SizedBox(
                    key: const ValueKey('bottle-action-panel'),
                    width: double.infinity,
                    child: BottleActionPanel(
                      bottle: bottle,
                      showBottleConfigurationAction:
                          showBottleConfigurationAction,
                      showBottleProgramsAction: showBottleProgramsAction,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    };
  }
}
