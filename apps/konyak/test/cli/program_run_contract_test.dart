import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/program_run_contract.dart';

void main() {
  test('parses a valid program run payload', () {
    final result = parseProgramRunPayload('''
      {
        "schemaVersion": 1,
        "run": {
          "bottleId": "steam",
          "programPath": "/downloads/setup.exe",
          "runnerKind": "wine",
          "executable": "wine",
          "workingDirectory": null,
          "argv": ["wine", "/downloads/setup.exe"],
          "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
          "processExitCode": 0
        }
      }
      ''');

    expect(result, isA<ParsedProgramRun>());
    final parsed = result as ParsedProgramRun;
    expect(parsed.run.bottleId, 'steam');
    expect(parsed.run.programPath, '/downloads/setup.exe');
    expect(parsed.run.runnerKind, 'wine');
    expect(parsed.run.executable, 'wine');
    expect(parsed.run.workingDirectory, isNull);
    expect(parsed.run.argv, const ['wine', '/downloads/setup.exe']);
    expect(parsed.run.processExitCode, 0);
  });

  test('parses an unsupported program type error', () {
    final result = parseProgramRunPayload('''
      {
        "schemaVersion": 1,
        "error": {
          "code": "unsupportedProgramType",
          "message": "Program type is not supported.",
          "programPath": "/downloads/readme.txt"
        }
      }
      ''');

    expect(result, isA<ProgramRunUnsupportedProgramType>());
    final unsupported = result as ProgramRunUnsupportedProgramType;
    expect(unsupported.programPath, '/downloads/readme.txt');
    expect(unsupported.message, 'Program type is not supported.');
  });

  test('parses a machine-readable bottle not-found error', () {
    final result = parseProgramRunPayload('''
      {
        "schemaVersion": 1,
        "error": {
          "code": "bottleNotFound",
          "message": "Bottle not found.",
          "bottleId": "missing"
        }
      }
      ''');

    expect(result, isA<ProgramRunBottleNotFound>());
    final notFound = result as ProgramRunBottleNotFound;
    expect(notFound.bottleId, 'missing');
    expect(notFound.message, 'Bottle not found.');
  });

  test('parses a machine-readable program runner failure', () {
    final result = parseProgramRunPayload('''
      {
        "schemaVersion": 1,
        "error": {
          "code": "programRunFailed",
          "message": "Runner executable `wine` was not found.",
          "bottleId": "steam",
          "programPath": "/downloads/setup.exe",
          "runnerKind": "wine",
          "executable": "wine",
          "workingDirectory": null,
          "argv": ["wine", "/downloads/setup.exe"],
          "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log"
        }
      }
      ''');

    expect(result, isA<ProgramRunExecutionFailure>());
    final failure = result as ProgramRunExecutionFailure;
    expect(failure.bottleId, 'steam');
    expect(failure.programPath, '/downloads/setup.exe');
    expect(failure.runnerKind, 'wine');
    expect(failure.executable, 'wine');
    expect(failure.workingDirectory, isNull);
    expect(failure.argv, const ['wine', '/downloads/setup.exe']);
    expect(
      failure.logPath,
      '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
    );
    expect(failure.message, 'Runner executable `wine` was not found.');
  });

  test('rejects unsupported schema versions', () {
    final result = parseProgramRunPayload(
      '{"schemaVersion":2,"run":{"bottleId":"steam"}}',
    );

    expect(result, isA<ProgramRunParseFailure>());
  });

  test('rejects invalid argv records', () {
    final result = parseProgramRunPayload('''
      {
        "schemaVersion": 1,
        "run": {
          "bottleId": "steam",
          "programPath": "/downloads/setup.exe",
          "runnerKind": "wine",
          "argv": ["wine", 42],
          "logPath": "/tmp/latest.log",
          "processExitCode": 0
        }
      }
      ''');

    expect(result, isA<ProgramRunParseFailure>());
  });
}
