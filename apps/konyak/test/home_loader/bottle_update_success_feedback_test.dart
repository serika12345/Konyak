import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/home_loader/bottle_update_success_feedback.dart';

void main() {
  test('models silent bottle update success feedback explicitly', () {
    expect(switch (const BottleUpdateSuccessFeedback.silent()) {
      SilentBottleUpdateSuccessFeedback() => true,
      MessageBottleUpdateSuccessFeedback() => false,
    }, isTrue);
  });

  test('resolves bottle update success feedback into explicit notices', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');

    expect(switch (bottleUpdateSuccessNotice(
      feedback: const BottleUpdateSuccessFeedback.silent(),
      bottle: bottle,
    )) {
      NoBottleUpdateSuccessNotice() => true,
      MessageBottleUpdateSuccessNotice() => false,
    }, isTrue);

    expect(switch (bottleUpdateSuccessNotice(
      feedback: BottleUpdateSuccessFeedback.message(
        (bottle) => 'Updated ${bottle.name}',
      ),
      bottle: bottle,
    )) {
      MessageBottleUpdateSuccessNotice(:final message) => message,
      NoBottleUpdateSuccessNotice() => '',
    }, 'Updated Steam');
  });
}

BottleSummary _bottle({required String id, required String name}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
  );
}
