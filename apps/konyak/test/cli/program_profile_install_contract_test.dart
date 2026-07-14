import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_program_payload_parsers.dart';
import 'package:konyak/src/cli/konyak_cli_program_result_types.dart';
import 'package:konyak/src/cli/program_profile_install_contract.dart';

void main() {
  test('parses versioned program profile install progress', () {
    final parsed = parseProgramProfileInstallProgressPayload(
      '{"schemaVersion":1,"programProfileInstallProgress":'
      '{"stage":"preInstallAction","state":"started",'
      '"actionIndex":1,"actionKind":"winetricks","actionId":"corefonts"}}',
    );

    expect(parsed, isA<ParsedProgramProfileInstallProgress>());
    final progress = (parsed as ParsedProgramProfileInstallProgress).progress;
    expect(progress, isA<StartedProgramProfileInstallStage>());
    expect(progress.stage, ProgramProfileInstallStage.preInstallAction);
    expect(progress.action, isA<ProgramProfileInstallAction>());
    final action = progress.action as ProgramProfileInstallAction;
    expect(action.index, 1);
    expect(action.kind, 'winetricks');
    expect(action.id, 'corefonts');
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
          '{"stage":"preInstallAction","state":"started",'
          '"actionIndex":0,"actionKind":"winetricks"}}',
      '{"schemaVersion":1,"programProfileInstallProgress":'
          '{"stage":"preInstallAction","state":"started",'
          '"actionIndex":64,"actionKind":"winetricks",'
          '"actionId":"corefonts"}}',
      '{"schemaVersion":1,"programProfileInstallProgress":'
          '{"stage":"preInstallAction","state":"started",'
          '"actionIndex":0,"actionKind":"nativeDll",'
          '"actionId":"unsafe/id"}}',
    ];

    for (final payload in payloads) {
      expect(
        parseProgramProfileInstallProgressPayload(payload),
        isA<InvalidProgramProfileInstallProgress>(),
      );
    }
    expect(
      parseProgramProfileInstallProgressPayload(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'programProfileInstallProgress': <String, Object?>{
            'stage': 'preInstallAction',
            'state': 'started',
            'actionIndex': 0,
            'actionKind': 'nativeDll',
            'actionId': 'a' * 129,
          },
        }),
      ),
      isA<InvalidProgramProfileInstallProgress>(),
    );
  });

  for (final (length, accepted) in const <(int, bool)>[
    (128, true),
    (129, false),
  ]) {
    test('${accepted ? 'accepts' : 'rejects'} a $length-character native DLL '
        'component action identifier from CLI JSON', () {
      final result = parseInstallProfileInspectPayload(
        jsonEncode(_installProfilePayload(componentId: 'a' * length)),
      );

      expect(
        result,
        accepted
            ? isA<InspectedInstallProfile>()
            : isA<InstallProfileInspectLoadFailure>(),
      );
    });
  }

  test('rejects duplicate pre-install actions from CLI JSON', () {
    final duplicateVerb = _installProfilePayload(componentId: 'component');
    final installProfile =
        duplicateVerb['installProfile']! as Map<String, Object?>;
    installProfile['preInstallActions'] = <Object?>[
      <String, Object?>{'kind': 'winetricks', 'verb': 'corefonts'},
      <String, Object?>{'kind': 'winetricks', 'verb': 'corefonts'},
    ];
    expect(
      parseInstallProfileInspectPayload(jsonEncode(duplicateVerb)),
      isA<InstallProfileInspectLoadFailure>(),
    );

    final duplicateTarget = _installProfilePayload(componentId: 'first');
    final duplicateTargetProfile =
        duplicateTarget['installProfile']! as Map<String, Object?>;
    final actions =
        duplicateTargetProfile['preInstallActions']! as List<Object?>;
    actions.add(<String, Object?>{
      ...(actions.single as Map<String, Object?>),
      'componentId': 'second',
    });
    expect(
      parseInstallProfileInspectPayload(jsonEncode(duplicateTarget)),
      isA<InstallProfileInspectLoadFailure>(),
    );
  });

  test('rejects malformed native DLL actions from CLI JSON', () {
    final mismatchedDestination = _installProfilePayload(
      componentId: 'component',
    );
    final mismatchedProfile =
        mismatchedDestination['installProfile']! as Map<String, Object?>;
    final mismatchedAction =
        (mismatchedProfile['preInstallActions']! as List<Object?>).single
            as Map<String, Object?>;
    mismatchedAction['destination'] = 'windowsSystem32';
    expect(
      parseInstallProfileInspectPayload(jsonEncode(mismatchedDestination)),
      isA<InstallProfileInspectLoadFailure>(),
    );

    final badDigest = _installProfilePayload(componentId: 'component');
    final badDigestProfile =
        badDigest['installProfile']! as Map<String, Object?>;
    final badDigestAction =
        (badDigestProfile['preInstallActions']! as List<Object?>).single
            as Map<String, Object?>;
    final resource = badDigestAction['resource']! as Map<String, Object?>;
    resource['sha256'] = 'not-a-digest';
    expect(
      parseInstallProfileInspectPayload(jsonEncode(badDigest)),
      isA<InstallProfileInspectLoadFailure>(),
    );
  });
}

Map<String, Object?> _installProfilePayload({required String componentId}) =>
    <String, Object?>{
      'schemaVersion': 1,
      'installProfile': <String, Object?>{
        'id': 'synthetic',
        'name': 'Synthetic',
        'profileVersion': 1,
        'profileSourceKind': 'builtin',
        'profileSourceId': 'synthetic.json',
        'profileDigest': 'a' * 64,
        'summary': 'Synthetic profile.',
        'platforms': <String>['macos'],
        'bottleTemplate': <String, Object?>{'windowsVersion': 'win10'},
        'managedProgramPath': r'C:\Synthetic\Synthetic.exe',
        'installerResource': <String, Object?>{
          'kind': 'https',
          'url': 'https://downloads.example.test/Setup.exe',
          'sha256': 'b' * 64,
          'fileName': 'Setup.exe',
        },
        'preInstallActions': <Object?>[
          <String, Object?>{
            'kind': 'nativeDll',
            'componentId': componentId,
            'machine': 'x86',
            'destination': 'windowsSysWow64',
            'targetFileName': 'component.dll',
            'resource': <String, Object?>{
              'kind': 'https',
              'url': 'https://downloads.example.test/component.dll',
              'sha256': 'c' * 64,
              'fileName': 'component.dll',
            },
          },
        ],
        'runCompletionPolicy': 'launchOnly',
        'compatibilityProfile': <String, Object?>{
          'id': 'synthetic',
          'profileVersion': 1,
          'childProcessRules': <Object?>[],
        },
      },
    };
