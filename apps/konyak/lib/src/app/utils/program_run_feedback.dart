import 'package:freezed_annotation/freezed_annotation.dart';

import '../../cli/konyak_cli_client.dart';
import '../../l10n/konyak_localizations.dart';
import '../../runs/program_run_summary.dart';

part 'program_run_feedback.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramRunFeedback with _$ProgramRunFeedback {
  const factory ProgramRunFeedback.none() = NoProgramRunFeedback;

  const factory ProgramRunFeedback.message(String message) =
      ProgramRunFeedbackMessage;
}

ProgramRunFeedback programRunFeedback(ProgramRunLoadResult result) {
  return switch (result) {
    CompletedProgramRun(:final run) when _isSuccessfulRun(run) =>
      const ProgramRunFeedback.none(),
    CompletedProgramRun(:final run) => ProgramRunFeedback.message(
      '${run.runnerKind} exited with code ${run.processExitCode}',
    ),
    FailedProgramRun(:final message, :final runnerKind, :final executable) =>
      ProgramRunFeedback.message(
        programRunFailureFeedback(
          message: message,
          runnerKind: runnerKind,
          executable: executable,
        ),
      ),
    UnsupportedProgramRun(:final message) ||
    MissingProgramRunBottle(:final message) ||
    ProgramRunLoadFailure(
      :final message,
    ) => ProgramRunFeedback.message(message),
  };
}

bool _isSuccessfulRun(ProgramRunSummary run) {
  return run.processExitCode == 0;
}

bool shouldRefreshBottleAfterCommand(String command) {
  return switch (command.trim().toLowerCase()) {
    'winecfg' || 'regedit' || 'control' || 'uninstaller' => true,
    _ => false,
  };
}

String programRunFailureFeedback({
  required String message,
  required String runnerKind,
  required String executable,
}) {
  return '$message ($runnerKind: $executable)';
}

String localizedLocationLabel(
  String location,
  KonyakLocalizations localizations,
) {
  return switch (location) {
    'c-drive' => localizations.cDrive,
    'root' => localizations.bottleFolder,
    _ => location,
  };
}
