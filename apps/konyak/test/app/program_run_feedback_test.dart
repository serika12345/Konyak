import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/utils/program_run_feedback.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';
import 'package:konyak/src/runs/program_run_summary.dart';

void main() {
  test('omits feedback for all successful runner completions', () {
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'wine'))),
      isNull,
    );
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'macosWine'))),
      isNull,
    );
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'winetricks'))),
      isNull,
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'macosWinetricks')),
      ),
      isNull,
    );
    expect(
      programRunFeedback(CompletedProgramRun(_run(runnerKind: 'terminal'))),
      isNull,
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'macosTerminal')),
      ),
      isNull,
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'linuxTerminal')),
      ),
      isNull,
    );
  });

  test('keeps feedback for abnormal exits', () {
    expect(
      programRunFeedback(
        CompletedProgramRun(_run(runnerKind: 'wine', processExitCode: 1)),
      ),
      'wine exited with code 1',
    );
    expect(
      programRunFeedback(
        CompletedProgramRun(
          _run(runnerKind: 'macosTerminal', processExitCode: 1),
        ),
      ),
      'macosTerminal exited with code 1',
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
      'wine not found (wine: wine)',
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
