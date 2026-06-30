import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/bottle_management_dialogs.dart';

void main() {
  test('models dismissed delete bottle dialogs explicitly', () {
    const deleteDecision = DeleteBottleDecision.delete();

    expect(
      deleteBottleDecisionFromNullable(null),
      const DeleteBottleDecision.cancelled(),
    );
    expect(deleteBottleDecisionFromNullable(deleteDecision), deleteDecision);
  });

  test('models dismissed rename bottle dialogs explicitly', () {
    const renameDecision = RenameBottleDecision.rename('Steam');

    expect(
      renameBottleDecisionFromNullable(null),
      const RenameBottleDecision.cancelled(),
    );
    expect(renameBottleDecisionFromNullable(renameDecision), renameDecision);
  });

  test('models dismissed rename pinned program dialogs explicitly', () {
    const renameDecision = RenamePinnedProgramDecision.rename('Setup');

    expect(
      renamePinnedProgramDecisionFromNullable(null),
      const RenamePinnedProgramDecision.cancelled(),
    );
    expect(
      renamePinnedProgramDecisionFromNullable(renameDecision),
      renameDecision,
    );
  });

  test('models dismissed move bottle dialogs explicitly', () {
    const moveDecision = MoveBottleDecision.move('/bottles/steam');

    expect(
      moveBottleDecisionFromNullable(null),
      const MoveBottleDecision.cancelled(),
    );
    expect(moveBottleDecisionFromNullable(moveDecision), moveDecision);
  });
}
