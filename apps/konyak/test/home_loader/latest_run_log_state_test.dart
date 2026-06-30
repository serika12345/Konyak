import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/latest_run_log_state.dart';

void main() {
  test('models unavailable latest run logs explicitly', () {
    expect(
      latestRunLogStateFromPath(' '),
      const LatestRunLogState.unavailable(),
    );
  });

  test('models available latest run logs explicitly', () {
    expect(
      latestRunLogStateFromPath('/tmp/latest.log'),
      const LatestRunLogState.available('/tmp/latest.log'),
    );
  });
}
