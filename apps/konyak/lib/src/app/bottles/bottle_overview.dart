import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../home/bottle_list_load_state.dart';
import '../programs/pinned_programs_section.dart';
import 'bottle_actions.dart';
import 'bottle_empty_states.dart';
import 'bottle_overview_content.dart';

class BottleOverview extends StatelessWidget {
  const BottleOverview({
    super.key,
    required this.platform,
    required this.content,
    required this.onRunProgram,
    required this.onRunProgramPath,
    required this.onPinProgram,
    required this.onConfigurePinnedProgram,
    required this.onUnpinProgram,
    required this.onRenamePinnedProgram,
    required this.onOpenPinnedProgramLocation,
    required this.onShowBottleConfiguration,
    required this.onShowBottlePrograms,
  });

  final KonyakPlatform platform;
  final BottleOverviewContent content;
  final ValueChanged<BottleSummary>? onRunProgram;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final ValueChanged<BottleSummary>? onPinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onConfigurePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onUnpinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onRenamePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;
  final ValueChanged<BottleSummary>? onShowBottleConfiguration;
  final ValueChanged<BottleSummary>? onShowBottlePrograms;

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
                    onPinProgram: onPinProgram ?? onRunProgram,
                    onRunProgramPath: onRunProgramPath,
                    onConfigurePinnedProgram: onConfigurePinnedProgram,
                    onUnpinProgram: onUnpinProgram,
                    onRenamePinnedProgram: onRenamePinnedProgram,
                    onOpenPinnedProgramLocation: onOpenPinnedProgramLocation,
                  ),
                  const Spacer(),
                  SizedBox(
                    key: const ValueKey('bottle-action-panel'),
                    width: double.infinity,
                    child: BottleActionPanel(
                      bottle: bottle,
                      onShowBottleConfiguration: onShowBottleConfiguration,
                      onShowBottlePrograms: onShowBottlePrograms,
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
