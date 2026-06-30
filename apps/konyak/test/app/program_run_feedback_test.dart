import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/utils/program_run_feedback.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';
import 'package:konyak/src/runs/program_run_summary.dart';

void main() {
  test('omits feedback for all successful runner completions', () {
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'wine'))),
      const ProgramRunFeedback.none(),
    );
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'macosWine'))),
      const ProgramRunFeedback.none(),
    );
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'winetricks'))),
      const ProgramRunFeedback.none(),
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'macosWinetricks')),
      ),
      const ProgramRunFeedback.none(),
    );
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'terminal'))),
      const ProgramRunFeedback.none(),
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'macosTerminal')),
      ),
      const ProgramRunFeedback.none(),
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'linuxTerminal')),
      ),
      const ProgramRunFeedback.none(),
    );
  });

  test('keeps feedback for abnormal exits', () {
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'wine', processExitCode: 1)),
      ),
      const ProgramRunFeedback.message('wine exited with code 1'),
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(
          _run(runnerKind: 'macosTerminal', processExitCode: 1),
        ),
      ),
      const ProgramRunFeedback.message('macosTerminal exited with code 1'),
    );
  });

  test('keeps feedback for program launch failures', () {
    expect(
      programRunFeedback(
        FailedProgramRun(
          bottleId: 'steam',
          programPath: '/downloads/setup.exe',
          message: 'wine not found',
          runnerKind: 'wine',
          executable: 'wine',
          argv: const ['wine', '/downloads/setup.exe'],
          logPath: '/bottles/steam/logs/latest.log',
        ),
      ),
      const ProgramRunFeedback.message('wine not found (wine: wine)'),
    );
  });
}

ProgramRunSummary _run({required String runnerKind, int processExitCode = 0}) {
  return ProgramRunSummary(
    bottleId: 'steam',
    programPath: '/downloads/setup.exe',
    runnerKind: runnerKind,
    executable: 'wine',
    argv: const ['wine', '/downloads/setup.exe'],
    logPath: '/bottles/steam/logs/latest.log',
    processExitCode: processExitCode,
  );
}
