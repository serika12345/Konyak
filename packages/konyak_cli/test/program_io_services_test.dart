import 'package:konyak_cli/src/io/program_io_services.dart';

import 'support/cli_contract_full_helpers.dart';

void main() {
  test('program runner clears inherited profile-only environment', () {
    final result = Process.runSync(
      Platform.resolvedExecutable,
      const ['run', 'test/support/program_runner_environment_probe.dart'],
      environment: <String, String>{
        ...Platform.environment,
        konyakChildProcessRulesEnvironmentVariable.toLowerCase():
            'unvalidated-rule',
        wineWaitChildPipeIgnoreEnvironmentVariable.toLowerCase():
            'unvalidated.exe',
      },
      includeParentEnvironment: false,
      runInShell: false,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test(
    'launchOnly program runs return without waiting for inherited stderr',
    () async {
      final temp = Directory.systemTemp.createTempSync('konyak-launch-only-');
      addTearDown(() {
        final pidFile = File('${temp.path}/child.pid');
        if (pidFile.existsSync()) {
          Process.runSync('kill', <String>[pidFile.readAsStringSync()]);
        }
        temp.deleteSync(recursive: true);
      });

      final script = File('${temp.path}/spawn-child.sh');
      final marker = File('${temp.path}/started');
      final pidFile = File('${temp.path}/child.pid');
      script.writeAsStringSync('''
#!/usr/bin/env bash
printf started > "\$1"
( sleep 20 >&2 ) &
printf "%s" "\$!" > "\$2"
exit 0
''');
      final chmod = Process.runSync('chmod', <String>['755', script.path]);
      expect(chmod.exitCode, 0);

      final request = ProgramRunRequest(
        bottleId: BottleId('bottle'),
        programPath: ProgramPath(script.path),
        runnerKind: RunnerKind('testRunner'),
        executable: ProgramExecutable(script.path),
        arguments: ProgramRunArguments(<String>[marker.path, pidFile.path]),
        environment: const ProgramRunEnvironment.empty(),
        logPath: ProgramLogPath('${temp.path}/launch.log'),
        completionPolicy: ProgramRunCompletionPolicy.launchOnly,
      );

      final stopwatch = Stopwatch()..start();
      final result = const DartIoProgramRunner().run(request);
      stopwatch.stop();

      expect(result, isA<ProgramRunCompleted>());
      expect((result as ProgramRunCompleted).processExitCode, 0);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(await _eventuallyExists(marker), isTrue);
      expect(await _eventuallyExists(pidFile), isTrue);
    },
  );

  test(
    'direct-exit async runs do not wait for descendant-held stderr',
    () async {
      final temp = Directory.systemTemp.createTempSync('konyak-direct-exit-');
      addTearDown(() {
        final pidFile = File('${temp.path}/child.pid');
        if (pidFile.existsSync()) {
          Process.runSync('kill', <String>[pidFile.readAsStringSync()]);
        }
        temp.deleteSync(recursive: true);
      });

      final script = File('${temp.path}/spawn-child.sh');
      final pidFile = File('${temp.path}/child.pid');
      script.writeAsStringSync('''
#!/usr/bin/env bash
printf "installer stdout\\n"
printf "installer stderr\\n" >&2
( sleep 20 >&2 ) &
printf "%s" "\$!" > "\$1"
exit 0
''');
      final chmod = Process.runSync('chmod', <String>['755', script.path]);
      expect(chmod.exitCode, 0);

      final request = ProgramRunRequest(
        bottleId: BottleId('bottle'),
        programPath: ProgramPath(script.path),
        runnerKind: RunnerKind('testRunner'),
        executable: ProgramExecutable(script.path),
        arguments: ProgramRunArguments(<String>[pidFile.path]),
        environment: const ProgramRunEnvironment.empty(),
        logPath: ProgramLogPath('${temp.path}/direct-exit.log'),
      );

      final stopwatch = Stopwatch()..start();
      final result = await const DartIoAsyncProgramRunner(
        outputCompletionPolicy:
            AsyncProgramOutputCompletionPolicy.directProcessExit,
      ).run(request);
      stopwatch.stop();

      expect(result, isA<ProgramRunCompleted>());
      final completed = result as ProgramRunCompleted;
      expect(completed.processExitCode, 0);
      expect(completed.stdout, contains('installer stdout'));
      expect(completed.stderr, contains('installer stderr'));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(await _eventuallyExists(pidFile), isTrue);
    },
  );
}

Future<bool> _eventuallyExists(File file) async {
  for (final _ in Iterable<void>.generate(20)) {
    if (file.existsSync()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return false;
}
