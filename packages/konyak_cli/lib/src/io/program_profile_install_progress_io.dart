import 'dart:convert';

import '../domain/program/program_profile_install_models.dart';
import '../shared/model_constants.dart';

Map<String, Object?> programProfileInstallProgressJson(
  ProgramProfileInstallProgress progress,
) {
  return <String, Object?>{
    'stage': progress.stage.value,
    'state': switch (progress) {
      ProgramProfileInstallStageStarted() => 'started',
      ProgramProfileInstallStageCompleted() => 'completed',
      ProgramProfileInstallStageFailed() => 'failed',
    },
    ...progress.dependencyIndex.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'dependencyIndex': value},
    ),
    ...progress.dependencyVerb.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'dependencyVerb': value.value},
    ),
    if (progress case ProgramProfileInstallStageFailed(:final code))
      'code': code,
  };
}

final class JsonProgramProfileInstallProgressSink
    implements ProgramProfileInstallProgressSink {
  const JsonProgramProfileInstallProgressSink(this.output);

  final StringSink output;

  @override
  void report(ProgramProfileInstallProgress progress) {
    output.writeln(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'programProfileInstallProgress': programProfileInstallProgressJson(
          progress,
        ),
      }),
    );
  }
}
