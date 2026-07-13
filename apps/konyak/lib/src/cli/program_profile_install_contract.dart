import 'konyak_cli_program_result_types.dart';

const programProfileInstallSchemaVersion = 1;

sealed class ProgramProfileInstallParseResult {
  const ProgramProfileInstallParseResult();
}

final class ParsedProgramProfileInstall
    extends ProgramProfileInstallParseResult {
  const ParsedProgramProfileInstall(this.profile);

  final ProgramProfileSummary profile;
}

final class ProgramProfileInstallCommandFailure
    extends ProgramProfileInstallParseResult {
  const ProgramProfileInstallCommandFailure(this.message);

  final String message;
}

final class ProgramProfileInstallParseFailure
    extends ProgramProfileInstallParseResult {
  const ProgramProfileInstallParseFailure(this.message);

  final String message;
}

enum ProgramProfileInstallStage {
  preflight,
  download,
  verification,
  installer,
  resourceCleanup,
  dependency,
  managedProgram,
  persistence,
}

sealed class ProgramProfileInstallDependencyContext {
  const ProgramProfileInstallDependencyContext();
}

final class NoProgramProfileInstallDependency
    extends ProgramProfileInstallDependencyContext {
  const NoProgramProfileInstallDependency();
}

final class ProgramProfileInstallDependency
    extends ProgramProfileInstallDependencyContext {
  const ProgramProfileInstallDependency({
    required this.index,
    required this.verb,
  });

  final int index;
  final String verb;
}

sealed class ProgramProfileInstallProgress {
  const ProgramProfileInstallProgress({
    required this.stage,
    required this.dependency,
  });

  final ProgramProfileInstallStage stage;
  final ProgramProfileInstallDependencyContext dependency;
}

final class StartedProgramProfileInstallStage
    extends ProgramProfileInstallProgress {
  const StartedProgramProfileInstallStage({
    required super.stage,
    required super.dependency,
  });
}

final class CompletedProgramProfileInstallStage
    extends ProgramProfileInstallProgress {
  const CompletedProgramProfileInstallStage({
    required super.stage,
    required super.dependency,
  });
}

final class FailedProgramProfileInstallStage
    extends ProgramProfileInstallProgress {
  const FailedProgramProfileInstallStage({
    required super.stage,
    required super.dependency,
    required this.code,
  });

  final String code;
}

sealed class ProgramProfileInstallProgressParseResult {
  const ProgramProfileInstallProgressParseResult();
}

final class ParsedProgramProfileInstallProgress
    extends ProgramProfileInstallProgressParseResult {
  const ParsedProgramProfileInstallProgress(this.progress);

  final ProgramProfileInstallProgress progress;
}

final class InvalidProgramProfileInstallProgress
    extends ProgramProfileInstallProgressParseResult {
  const InvalidProgramProfileInstallProgress();
}

sealed class ProgramProfileInstallProgressObservation {
  const ProgramProfileInstallProgressObservation();
}

final class IgnoreProgramProfileInstallProgress
    extends ProgramProfileInstallProgressObservation {
  const IgnoreProgramProfileInstallProgress();
}

final class NotifyProgramProfileInstallProgress
    extends ProgramProfileInstallProgressObservation {
  const NotifyProgramProfileInstallProgress(this.onProgress);

  final void Function(ProgramProfileInstallProgress progress) onProgress;
}
