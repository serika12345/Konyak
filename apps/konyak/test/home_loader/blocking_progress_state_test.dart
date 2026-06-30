import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/blocking_progress_state.dart';

void main() {
  test('models inactive blocking progress explicitly', () {
    expect(
      blockingProgressMessage(const BlockingProgressState.hidden()),
      const NoBlockingProgressMessage(),
    );
  });

  test('models indeterminate blocking progress explicitly', () {
    const state = BlockingProgressState.indeterminate('Installing...');

    expect(
      blockingProgressMessage(state),
      const BlockingProgressMessage.indeterminate('Installing...'),
    );
  });

  test('models determinate blocking progress explicitly', () {
    const state = BlockingProgressState.determinate(
      message: 'Downloading...',
      progress: 0.5,
    );

    expect(
      blockingProgressMessage(state),
      const BlockingProgressMessage.determinate(
        message: 'Downloading...',
        progress: 0.5,
      ),
    );
  });
}
