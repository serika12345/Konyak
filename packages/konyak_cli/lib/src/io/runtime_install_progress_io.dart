import 'dart:convert';

import '../domain/runtime/runtime_package_installation.dart';
import '../shared/model_constants.dart';

Map<String, Object?> runtimeInstallProgressJson(
  RuntimeInstallProgress progress,
) {
  return <String, Object?>{
    'stage': progress.stage.value,
    'message': progress.message,
    'fraction': progress.fraction.value,
  };
}

abstract interface class RuntimeInstallProgressSink {
  void emit(RuntimeInstallProgress progress);
}

final class JsonRuntimeInstallProgressSink
    implements RuntimeInstallProgressSink {
  const JsonRuntimeInstallProgressSink(this.output);

  final StringSink output;

  @override
  void emit(RuntimeInstallProgress progress) {
    output.writeln(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'runtimeInstallProgress': runtimeInstallProgressJson(progress),
      }),
    );
  }
}
