import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/bottles/bottle_action_availability.dart';
import 'package:konyak/src/app/programs/pinned_program_context_menu.dart';

void main() {
  test('models pinned program context menu decisions explicitly', () {
    expect(
      const PinnedProgramContextMenuDecision.cancelled(),
      isA<CancelledPinnedProgramContextMenu>(),
    );
    expect(
      const PinnedProgramContextMenuDecision.select(
        PinnedProgramContextMenuAction.run,
      ),
      isA<SelectedPinnedProgramContextMenuAction>(),
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
