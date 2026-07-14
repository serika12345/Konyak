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
    ...progress.actionIndex.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'actionIndex': value},
    ),
    ...progress.actionKind.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'actionKind': value.value},
    ),
    ...progress.actionId.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'actionId': value.value},
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
