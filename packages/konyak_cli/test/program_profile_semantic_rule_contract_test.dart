import 'dart:convert';
import 'dart:io';

import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

import 'support/install_profile_fixtures.dart';

void main() {
  final semanticRuleCases = <String, void Function()>{
    'pre-install-actions.unique-winetricks-verbs': () => testInstallProfile(
      preInstallActions: [
        PreInstallActionRecord.winetricks(verb: 'corefonts'),
        PreInstallActionRecord.winetricks(verb: 'corefonts'),
      ],
    ),
    'pre-install-actions.unique-native-dll-targets': () => testInstallProfile(
      preInstallActions: [
        _nativeDllAction('first-component'),
        _nativeDllAction('second-component'),
      ],
    ),
    'child-process-rules.non-blank-executable-suffix': () =>
        ChildProcessCompatibilityRule(
          executableSuffix: ' ',
          appendArgumentsIfMissing: const ['--argument'],
        ),
    'child-process-rules.total-argument-limit': () =>
        CompatibilityProfileRecord(
          id: 'too-many-arguments',
          profileVersion: 1,
          childProcessRules: [
            _childProcessRule('first', 33),
            _childProcessRule('second', 32),
          ],
        ),
    'child-process-rules.serialized-length-limit': () =>
        CompatibilityProfileRecord(
          id: 'oversized-rules',
          profileVersion: 1,
          childProcessRules: List<ChildProcessCompatibilityRule>.generate(
            8,
            (_) => ChildProcessCompatibilityRule(
              executableSuffix: 's' * 1024,
              appendArgumentsIfMissing: ['a' * 8192],
            ),
            growable: false,
          ),
        ),
  };

  semanticRuleCases.forEach((ruleId, invalidValue) {
    test('enforces documented semantic rule $ruleId', () {
      expect(invalidValue, throwsArgumentError);
    });
  });

  test('documents every behaviorally tested semantic rule ID', () {
    final schema =
        jsonDecode(File('profiles/profile.schema.json').readAsStringSync())
            as Map<String, Object?>;
    final rules = schema['x-konyak-semanticRules'] as List<Object?>;
    final documentedIds = rules
        .cast<Map<String, Object?>>()
        .map((rule) => rule['id'])
        .cast<String>()
        .toSet();

    expect(documentedIds, semanticRuleCases.keys.toSet());
  });
}

PreInstallActionRecord _nativeDllAction(String componentId) {
  return PreInstallActionRecord.nativeDll(
    componentId: componentId,
    machine: 'x86',
    destination: 'windowsSysWow64',
    targetFileName: 'component.dll',
    resource: NativeDllResourceRecord(
      kind: 'https',
      url: 'https://downloads.example.test/$componentId.dll',
      sha256: 'a' * 64,
      fileName: '$componentId.dll',
    ),
  );
}

ChildProcessCompatibilityRule _childProcessRule(String prefix, int count) {
  return ChildProcessCompatibilityRule(
    executableSuffix: '$prefix-helper.exe',
    appendArgumentsIfMissing: List<String>.generate(
      count,
      (index) => '--$prefix-$index',
      growable: false,
    ),
  );
}
