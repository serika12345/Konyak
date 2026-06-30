import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/app_settings_dialog_operation_state.dart';

void main() {
  test('models concurrent App Settings dialog operations explicitly', () {
    final saving = startAppSettingsDialogOperation(
      state: const AppSettingsDialogOperationState.idle(),
      operation: AppSettingsDialogOperation.savingSettings,
    );

    expect(
      isAppSettingsDialogOperationRunning(
        state: saving,
        operation: AppSettingsDialogOperation.savingSettings,
      ),
      isTrue,
    );
    expect(
      isAppSettingsDialogOperationRunning(
        state: saving,
        operation: AppSettingsDialogOperation.installingRuntime,
      ),
      isFalse,
    );

    final savingAndInstalling = startAppSettingsDialogOperation(
      state: saving,
      operation: AppSettingsDialogOperation.installingRuntime,
    );

    expect(
      isAppSettingsDialogOperationRunning(
        state: savingAndInstalling,
        operation: AppSettingsDialogOperation.savingSettings,
      ),
      isTrue,
    );
    expect(
      isAppSettingsDialogOperationRunning(
        state: savingAndInstalling,
        operation: AppSettingsDialogOperation.installingRuntime,
      ),
      isTrue,
    );

    final installingOnly = finishAppSettingsDialogOperation(
      state: savingAndInstalling,
      operation: AppSettingsDialogOperation.savingSettings,
    );

    expect(
      isAppSettingsDialogOperationRunning(
        state: installingOnly,
        operation: AppSettingsDialogOperation.savingSettings,
      ),
      isFalse,
    );
    expect(
      isAppSettingsDialogOperationRunning(
        state: installingOnly,
        operation: AppSettingsDialogOperation.installingRuntime,
      ),
      isTrue,
    );
    expect(
      finishAppSettingsDialogOperation(
        state: installingOnly,
        operation: AppSettingsDialogOperation.installingRuntime,
      ),
      const AppSettingsDialogOperationState.idle(),
    );
  });
}
