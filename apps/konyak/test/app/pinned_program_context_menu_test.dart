import 'package:flutter_test/flutter_test.dart';
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
}
