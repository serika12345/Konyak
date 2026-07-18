import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/install_profile_manifest_editor.dart';
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

  test('parses profile source capabilities and canonical manifest', () {
    final payload = _installProfilePayload(componentId: 'component');
    final profile = payload['installProfile']! as Map<String, Object?>;
    profile['profileSourceKind'] = 'user';
    profile['manifest'] = <String, Object?>{
      r'$schema': 'https://konyak.app/schemas/profile-v1.schema.json',
      'schemaVersion': 1,
      'id': 'synthetic',
      'name': 'Synthetic',
      'profileVersion': 4,
      'compatibilityProfile': <String, Object?>{
        'id': 'synthetic',
        'profileVersion': 4,
      },
    };
    payload['installProfiles'] = <Object?>[
      <String, Object?>{
        'id': 'synthetic',
        'name': 'Synthetic',
        'profileVersion': 1,
        'profileSourceKind': 'user',
        'profileDigest': 'a' * 64,
        'canEdit': true,
        'canDelete': true,
      },
    ];

    final inspected = parseInstallProfileInspectPayload(jsonEncode(payload));
    final listed = parseInstallProfileListPayload(jsonEncode(payload));

    expect(inspected, isA<InspectedInstallProfile>());
    expect(
      (inspected as InspectedInstallProfile).profile.manifestJson,
      contains(r'"$schema"'),
    );
    expect(listed, isA<LoadedInstallProfiles>());
    final summary = (listed as LoadedInstallProfiles).profiles.single;
    expect(summary.profileSourceKind, 'user');
    expect(summary.canEdit, isTrue);
    expect(summary.canDelete, isTrue);

    final duplicated = duplicateInstallProfileManifest(inspected.profile);
    expect(duplicated, isA<DuplicatedInstallProfileManifest>());
    final duplicateJson =
        jsonDecode(
              (duplicated as DuplicatedInstallProfileManifest).manifestJson,
            )
            as Map<String, Object?>;
    expect(duplicateJson['id'], 'synthetic-copy');
    expect(duplicateJson['profileVersion'], 1);
    expect(
      (duplicateJson['compatibilityProfile'] as Map<String, Object?>)['id'],
      'synthetic-copy',
    );
  });

  test('parses profile mutation successes and validation failures', () {
    final profilePayload =
        _installProfilePayload(componentId: 'component')['installProfile']!
            as Map<String, Object?>;
    profilePayload['profileSourceKind'] = 'user';
    final imported = parseInstallProfileMutationPayload(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'installProfileMutation': <String, Object?>{
          'operation': 'import',
          'installProfile': profilePayload,
        },
      }),
    );
    final deleted = parseInstallProfileMutationPayload(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'installProfileMutation': <String, Object?>{
          'operation': 'delete',
          'profileId': 'synthetic',
          'profileDigest': 'a' * 64,
        },
      }),
    );
    final invalid = parseInstallProfileMutationPayload(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'error': <String, Object?>{
          'code': 'invalidProfile',
          'message': 'The profile manifest is invalid.',
          'validationErrors': <Object?>[
            <String, Object?>{
              'path': '/profileVersion',
              'message': 'Must be at least 1.',
            },
          ],
        },
      }),
    );

    expect(imported, isA<ImportedInstallProfile>());
    expect(deleted, isA<DeletedInstallProfile>());
    expect(invalid, isA<InstallProfileMutationLoadFailure>());
    expect(
      (invalid as InstallProfileMutationLoadFailure).message,
      contains('/profileVersion: Must be at least 1.'),
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
