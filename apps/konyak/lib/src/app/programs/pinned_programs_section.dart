import 'package:flutter/material.dart';
import '../../bottles/bottle_summary.dart';
import 'pin_program_action.dart';
import 'pinned_program_tile.dart';

class PinnedProgramsSection extends StatelessWidget {
  const PinnedProgramsSection({
    super.key,
    required this.bottle,
    required this.onPinProgram,
    required this.onRunProgramPath,
    required this.onConfigurePinnedProgram,
    required this.onUnpinProgram,
    required this.onRenamePinnedProgram,
    required this.onOpenPinnedProgramLocation,
  });

  final BottleSummary bottle;
  final ValueChanged<BottleSummary>? onPinProgram;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onConfigurePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onUnpinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onRenamePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final program in bottle.pinnedPrograms)
          PinnedProgramTile(
            bottle: bottle,
            program: program,
            onRunProgramPath: onRunProgramPath,
            onConfigurePinnedProgram: onConfigurePinnedProgram,
            onUnpinProgram: onUnpinProgram,
            onRenamePinnedProgram: onRenamePinnedProgram,
            onOpenPinnedProgramLocation: onOpenPinnedProgramLocation,
          ),
        PinProgramAction(bottle: bottle, onPinProgram: onPinProgram),
      ],
    );
  }
}
