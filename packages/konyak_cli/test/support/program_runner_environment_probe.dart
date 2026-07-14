import 'dart:io';

import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/io/program_io_services.dart';

void main() {
  final request = ProgramRunRequest(
    bottleId: BottleId('probe'),
    programPath: ProgramPath('/usr/bin/env'),
    runnerKind: RunnerKind('environmentProbe'),
    executable: ProgramExecutable('/usr/bin/env'),
    arguments: ProgramRunArguments(const []),
    environment: const ProgramRunEnvironment.empty(),
    logPath: ProgramLogPath('/tmp/konyak-program-runner-environment-probe.log'),
    createLogFile: false,
  );
  final result = const DartIoProgramRunner().run(request);

  switch (result) {
    case ProgramRunCompleted(:final processExitCode, :final stdout)
        when processExitCode == 0 && !_containsReservedProfileValues(stdout):
      return;
    case ProgramRunCompleted(:final processExitCode):
      stderr.writeln(
        'Unexpected probe result: exit=$processExitCode or reserved '
        'environment variable was present.',
      );
    case ProgramRunFailed(:final message):
      stderr.writeln(message);
  }
  exitCode = 1;
}

bool _containsReservedProfileValues(String environment) {
  final prefixes = <String>{
    '${konyakChildProcessRulesEnvironmentVariable.toUpperCase()}=',
    '${wineWaitChildPipeIgnoreEnvironmentVariable.toUpperCase()}=',
  };
  return environment
      .split('\n')
      .any((line) => prefixes.any(line.toUpperCase().startsWith));
}
