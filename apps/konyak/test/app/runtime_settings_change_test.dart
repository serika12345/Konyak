import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/bottles/runtime_settings_change.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('models unavailable runtime settings changes explicitly', () {
    final action = runtimeSettingsChangeAvailabilityFromNullable(null);

    expect(action, isA<UnavailableRuntimeSettingsChangeAvailability>());
    expect(canChangeRuntimeSettings(action), isFalse);
  });

  test('resolves runtime settings changes without a nullable callback', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final updatedControls = <String>[];
    final action = RuntimeSettingsChangeAvailability.available(
      (_, _, controlKey) => updatedControls.add(controlKey),
    );

    final dispatch = resolveRuntimeSettingsChange(
      bottle: bottle,
      runtimeSettings: bottle.runtimeSettings,
      controlKey: 'dxvk',
      action: action,
    );

    switch (dispatch) {
      case AvailableRuntimeSettingsChangeDispatch(:final invoke):
        invoke();
      case UnavailableRuntimeSettingsChangeDispatch():
        fail('Expected runtime settings change dispatch to be available.');
    }

    expect(updatedControls, <String>['dxvk']);
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
