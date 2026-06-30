import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/wine_process_close_cleanup_state.dart';

void main() {
  test('models close cleanup requests explicitly', () {
    const initial = WineProcessCloseCleanupState.notRequested();

    expect(hasRequestedWineProcessCloseCleanup(initial), isFalse);
    expect(shouldRequestWineProcessCloseCleanup(initial), isTrue);

    final requested = requestWineProcessCloseCleanup(initial);

    expect(requested, const WineProcessCloseCleanupState.requested());
    expect(hasRequestedWineProcessCloseCleanup(requested), isTrue);
    expect(shouldRequestWineProcessCloseCleanup(requested), isFalse);
    expect(
      requestWineProcessCloseCleanup(requested),
      const WineProcessCloseCleanupState.requested(),
    );
  });
}
