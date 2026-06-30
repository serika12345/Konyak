import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/process_manager_state.dart';
import 'package:konyak/src/cli/konyak_cli_wine_process_result_types.dart';

void main() {
  test('maps Wine process load results to explicit process manager state', () {
    final process = _process(processId: '42');
    final loaded = processManagerStateFromLoadResult(
      LoadedWineProcesses(processes: [process]),
    );
    const failed = WineProcessListLoadFailure(
      exitCode: 1,
      message: 'list failed',
      diagnostic: 'stderr',
    );

    expect(
      isProcessManagerLoading(const ProcessManagerState.loading()),
      isTrue,
    );
    expect(isProcessManagerLoading(loaded), isFalse);
    expect(
      processManagerStateFromLoadResult(failed),
      const ProcessManagerState.failed('list failed'),
    );

    switch (loaded) {
      case LoadedProcessManagerState(:final processes):
        expect(processes, [process]);
        expect(processes.clear, throwsUnsupportedError);
      case LoadingProcessManagerState() || FailedProcessManagerState():
        fail('Expected loaded process manager state.');
    }
  });

  test('removes a process from loaded process manager state immutably', () {
    final process = _process(processId: '42');
    final otherProcess = _process(processId: '43');
    final state = ProcessManagerState.loaded([process, otherProcess]);

    final updated = removeProcessFromManagerState(
      state: state,
      processKey: processManagerProcessKey(process),
    );

    switch (updated) {
      case LoadedProcessManagerState(:final processes):
        expect(processes, [otherProcess]);
      case LoadingProcessManagerState() || FailedProcessManagerState():
        fail('Expected loaded process manager state.');
    }
  });
}

WineProcessSummary _process({required String processId}) {
  return WineProcessSummary(
    bottleId: 'steam',
    processId: processId,
    executable: r'C:\Games\game.exe',
  );
}
