import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/home_loader_operation_state.dart';

void main() {
  test('models concurrent home-loader operations explicitly', () {
    final showingSettings = startHomeLoaderOperation(
      state: const HomeLoaderOperationState.idle(),
      operation: HomeLoaderOperation.showingSettings,
    );

    expect(
      isHomeLoaderOperationRunning(
        state: showingSettings,
        operation: HomeLoaderOperation.showingSettings,
      ),
      isTrue,
    );
    expect(
      isHomeLoaderOperationRunning(
        state: showingSettings,
        operation: HomeLoaderOperation.checkingKonyakUpdate,
      ),
      isFalse,
    );

    final showingSettingsAndCheckingUpdates = startHomeLoaderOperation(
      state: showingSettings,
      operation: HomeLoaderOperation.checkingKonyakUpdate,
    );

    expect(
      isHomeLoaderOperationRunning(
        state: showingSettingsAndCheckingUpdates,
        operation: HomeLoaderOperation.showingSettings,
      ),
      isTrue,
    );
    expect(
      isHomeLoaderOperationRunning(
        state: showingSettingsAndCheckingUpdates,
        operation: HomeLoaderOperation.checkingKonyakUpdate,
      ),
      isTrue,
    );

    final checkingUpdatesOnly = finishHomeLoaderOperation(
      state: showingSettingsAndCheckingUpdates,
      operation: HomeLoaderOperation.showingSettings,
    );

    expect(
      isHomeLoaderOperationRunning(
        state: checkingUpdatesOnly,
        operation: HomeLoaderOperation.showingSettings,
      ),
      isFalse,
    );
    expect(
      isHomeLoaderOperationRunning(
        state: checkingUpdatesOnly,
        operation: HomeLoaderOperation.checkingKonyakUpdate,
      ),
      isTrue,
    );
    expect(
      finishHomeLoaderOperation(
        state: checkingUpdatesOnly,
        operation: HomeLoaderOperation.checkingKonyakUpdate,
      ),
      const HomeLoaderOperationState.idle(),
    );
  });
}
