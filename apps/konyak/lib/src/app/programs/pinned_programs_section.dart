import 'package:flutter/material.dart';
import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import '../bottles/bottle_action_availability.dart';
import 'pin_program_action.dart';
import 'pinned_program_tile.dart';

class PinnedProgramsSection extends StatelessWidget {
  const PinnedProgramsSection({
    super.key,
    required this.platform,
    required this.bottle,
    required this.pinProgramAction,
    required this.runProgramPathAction,
    required this.configurePinnedProgramAction,
    required this.unpinProgramAction,
    required this.renamePinnedProgramAction,
    required this.openPinnedProgramLocationAction,
  });

  final KonyakPlatform platform;
  final BottleSummary bottle;
  final BottleSummaryActionAvailability pinProgramAction;
  final ProgramPathActionAvailability runProgramPathAction;
  final PinnedProgramActionAvailability configurePinnedProgramAction;
  final PinnedProgramActionAvailability unpinProgramAction;
  final PinnedProgramActionAvailability renamePinnedProgramAction;
  final PinnedProgramActionAvailability openPinnedProgramLocationAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final program in bottle.pinnedPrograms)
          PinnedProgramTile(
            platform: platform,
            bottle: bottle,
            program: program,
            runProgramPathAction: runProgramPathAction,
            configurePinnedProgramAction: configurePinnedProgramAction,
            unpinProgramAction: unpinProgramAction,
            renamePinnedProgramAction: renamePinnedProgramAction,
            openPinnedProgramLocationAction: openPinnedProgramLocationAction,
          ),
        PinProgramAction(bottle: bottle, pinProgramAction: pinProgramAction),
      ],
    );
  }
}
