import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/home/sidebar.dart';

void main() {
  test('models bottle context menu decisions explicitly', () {
    expect(
      const BottleContextMenuDecision.cancelled(),
      isA<CancelledBottleContextMenu>(),
    );
    expect(
      const BottleContextMenuDecision.select(BottleContextMenuAction.rename),
      isA<SelectedBottleContextMenuAction>(),
    );
  });
}
