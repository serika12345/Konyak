import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_program_payload_parsers.dart';
import 'package:konyak/src/cli/program_profile_install_contract.dart';

void main() {
  test('parses versioned program profile install progress', () {
    final parsed = parseProgramProfileInstallProgressPayload(
      '{"schemaVersion":1,"programProfileInstallProgress":'
      '{"stage":"dependency","state":"started",'
      '"dependencyIndex":1,"dependencyVerb":"corefonts"}}',
    );

    expect(parsed, isA<ParsedProgramProfileInstallProgress>());
    final progress = (parsed as ParsedProgramProfileInstallProgress).progress;
    expect(progress, isA<StartedProgramProfileInstallStage>());
    expect(progress.stage, ProgramProfileInstallStage.dependency);
    expect(progress.dependency, isA<ProgramProfileInstallDependency>());
    final dependency = progress.dependency as ProgramProfileInstallDependency;
    expect(dependency.index, 1);
    expect(dependency.verb, 'corefonts');
  });

  test('parses failed program profile install progress', () {
    final parsed = parseProgramProfileInstallProgressPayload(
      '{"schemaVersion":1,"programProfileInstallProgress":'
      '{"stage":"installer","state":"failed",'
      '"code":"installerExitNonZero"}}',
    );

    expect(parsed, isA<ParsedProgramProfileInstallProgress>());
    final progress = (parsed as ParsedProgramProfileInstallProgress).progress;
    expect(progress, isA<FailedProgramProfileInstallStage>());
    expect(
      (progress as FailedProgramProfileInstallStage).code,
      'installerExitNonZero',
    );
  });

  test('rejects malformed program profile install progress', () {
    const payloads = <String>[
      '{"schemaVersion":2,"programProfileInstallProgress":'
          '{"stage":"download","state":"started"}}',
      '{"schemaVersion":1,"programProfileInstallProgress":'
          '{"stage":"unknown","state":"started"}}',
      '{"schemaVersion":1,"programProfileInstallProgress":'
          '{"stage":"download","state":"failed"}}',
      '{"schemaVersion":1,"programProfileInstallProgress":'
          '{"stage":"dependency","state":"started",'
          '"dependencyIndex":0}}',
    ];

    for (final payload in payloads) {
      expect(
        parseProgramProfileInstallProgressPayload(payload),
        isA<InvalidProgramProfileInstallProgress>(),
      );
    }
  });
}
