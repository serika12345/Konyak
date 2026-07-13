import 'dart:async';
import 'dart:io';

import 'package:konyak_cli/src/cli/cli_default_runner.dart';
import 'package:konyak_cli/src/io/program_profile_install_progress_io.dart';
import 'package:konyak_cli/src/io/runtime_install_progress_io.dart';

Future<void> main(List<String> arguments) async {
  final result = await runCliStreamingWithDefaultIo(
    arguments,
    runtimeInstallProgressSink: JsonRuntimeInstallProgressSink(stdout),
    programProfileInstallProgressSink: JsonProgramProfileInstallProgressSink(
      stdout,
    ),
  );

  if (result.stdout.isNotEmpty) {
    stdout.writeln(result.stdout);
  }

  if (result.stderr.isNotEmpty) {
    stderr.write(result.stderr);
  }

  exitCode = result.exitCode;
}
