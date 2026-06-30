import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/run_program_dialog.dart';
import 'package:konyak/src/cli/konyak_cli_program_commands.dart';
import 'package:konyak/src/cli/konyak_cli_program_result_types.dart';

void main() {
  test('models dismissed run program dialogs explicitly', () {
    final runDecision = const RunProgramDialogDecision.run(
      programPath: '/downloads/setup.exe',
      settings: NoProgramRunSettings(),
    );

    expect(
      runProgramDialogDecisionFromNullable(null),
      const RunProgramDialogDecision.cancelled(),
    );
    expect(runProgramDialogDecisionFromNullable(runDecision), runDecision);
  });

  test('maps loaded graphics backend hints to explicit UI state', () {
    final hints = ProgramGraphicsBackendHintsSummary(
      programPath: '/games/setup.exe',
      hostPlatform: 'macos',
      signals: const <ProgramGraphicsBackendSignalSummary>[],
      suggestions: const <ProgramGraphicsBackendSuggestionSummary>[],
    );
    final state = runProgramGraphicsBackendHintStateFromLoadResult(
      LoadedGraphicsBackendHints(hints),
    );

    expect(switch (state) {
      LoadedRunProgramGraphicsBackendHint(:final hints) => hints.hostPlatform,
      NoRunProgramGraphicsBackendHint() ||
      LoadingRunProgramGraphicsBackendHint() ||
      FailedRunProgramGraphicsBackendHint() => '',
    }, 'macos');
  });

  test('maps failed graphics backend hints to explicit UI state', () {
    final state = runProgramGraphicsBackendHintStateFromLoadResult(
      const GraphicsBackendHintsLoadFailure(
        exitCode: 1,
        message: 'not a PE file',
        diagnostic: '',
      ),
    );

    expect(switch (state) {
      FailedRunProgramGraphicsBackendHint(:final message) => message,
      NoRunProgramGraphicsBackendHint() ||
      LoadingRunProgramGraphicsBackendHint() ||
      LoadedRunProgramGraphicsBackendHint() => '',
    }, 'not a PE file');
  });
}
