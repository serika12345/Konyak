import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/bottles/bottle_action_availability.dart';
import 'package:konyak/src/app/programs/pinned_program_context_menu.dart';

void main() {
  test('models dismissed pinned program context menus explicitly', () {
    expect(
      pinnedProgramContextMenuDecisionFromNullable(null),
      const PinnedProgramContextMenuDecision.cancelled(),
    );
    expect(
      pinnedProgramContextMenuDecisionFromNullable(
        PinnedProgramContextMenuAction.run,
      ),
      const PinnedProgramContextMenuDecision.select(
        PinnedProgramContextMenuAction.run,
      ),
    );
  });

  test('builds pinned program context menu actions from availability', () {
    final actions = pinnedProgramContextMenuActionsFromAvailability(
      runProgramPathAction: ProgramPathActionAvailability.available((_, _) {}),
      configurePinnedProgramAction:
          const PinnedProgramActionAvailability.unavailable(),
      unpinProgramAction: PinnedProgramActionAvailability.available((_, _) {}),
      renamePinnedProgramAction:
          const PinnedProgramActionAvailability.unavailable(),
      openPinnedProgramLocationAction:
          PinnedProgramActionAvailability.available((_, _) {}),
    );

    expect(actions, <PinnedProgramContextMenuAction>[
      PinnedProgramContextMenuAction.run,
      PinnedProgramContextMenuAction.unpin,
      PinnedProgramContextMenuAction.showInFinder,
    ]);
  });
}
