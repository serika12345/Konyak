import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/bottle_management_dialogs.dart';

void main() {
  test('models delete bottle dialog decisions explicitly', () {
    expect(const DeleteBottleDecision.delete(), isA<DeleteBottleConfirmed>());
    expect(
      const DeleteBottleDecision.cancelled(),
      isA<CancelledDeleteBottleDialog>(),
    );
  });

  test('models rename bottle dialog decisions explicitly', () {
    expect(
      const RenameBottleDecision.rename('Steam'),
      isA<RenameBottleToName>(),
    );
    expect(
      const RenameBottleDecision.cancelled(),
      isA<CancelledRenameBottleDialog>(),
    );
  });

  test('models rename pinned program dialog decisions explicitly', () {
    expect(
      const RenamePinnedProgramDecision.rename('Setup'),
      isA<RenamePinnedProgramToName>(),
    );
    expect(
      const RenamePinnedProgramDecision.cancelled(),
      isA<CancelledRenamePinnedProgramDialog>(),
    );
  });

  test('models move bottle dialog decisions explicitly', () {
    expect(
      const MoveBottleDecision.move('/bottles/steam'),
      isA<MoveBottleToPath>(),
    );
    expect(
      const MoveBottleDecision.cancelled(),
      isA<CancelledMoveBottleDialog>(),
    );
  });
}
