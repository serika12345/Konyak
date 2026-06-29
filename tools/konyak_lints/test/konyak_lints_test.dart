import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('konyak custom lint fixtures', () {
    test(
      'invalid fixture reports policy violations',
      () async {
        final fixture = _fixtureDirectory('invalid');
        await _dart(fixture, const ['pub', 'get']);

        final result = await _dart(fixture, const ['run', 'custom_lint']);
        final output = _combinedOutput(result);

        expect(result.exitCode, isNot(0), reason: output);
        expect(
          output,
          contains('lib/src/domain/dart_io_boundary_violation.dart'),
        );
        expect(output, contains('lib/src/domain/file_type_violation.dart'));
        expect(output, contains('lib/src/domain/platform_violation.dart'));
        expect(output, contains('lib/src/domain/process_violation.dart'));
        expect(
          output,
          contains('lib/src/domain/serialization_boundary_violation.dart'),
        );
        expect(
          output,
          contains('lib/src/io/to_nullable_boundary_violation.dart'),
        );
        for (final rule in const [
          'konyak_no_domain_io',
          'konyak_no_nullable_sentinel_flow',
          'konyak_no_domain_reassignment',
          'konyak_no_domain_var_declaration',
          'konyak_no_domain_increment',
          'konyak_no_domain_nested_conditional',
          'konyak_no_domain_parameter_mutation',
          'konyak_no_domain_part_of_root',
          'konyak_no_handwritten_part',
          'konyak_no_null_literal_outside_boundary',
          'konyak_no_nullable_bridge_outside_boundary',
          'konyak_no_nullable_type_outside_boundary',
          'konyak_no_to_nullable',
          'konyak_no_result_failure_to_option_none',
        ]) {
          expect(output, contains(rule));
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('valid fixture passes', () async {
      final fixture = _fixtureDirectory('valid');
      await _dart(fixture, const ['pub', 'get']);

      final result = await _dart(fixture, const ['run', 'custom_lint']);
      final output = _combinedOutput(result);

      expect(result.exitCode, 0, reason: output);
      expect(output, isNot(contains('konyak_no_')));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

Directory _fixtureDirectory(String name) {
  return Directory(
    _joinPath([
      Directory.current.path,
      'test',
      'fixtures',
      name,
      'packages',
      'konyak_cli',
    ]),
  );
}

Future<ProcessResult> _dart(
  Directory workingDirectory,
  List<String> arguments,
) {
  return Process.run(
    Platform.resolvedExecutable,
    arguments,
    workingDirectory: workingDirectory.path,
    runInShell: false,
  );
}

String _combinedOutput(ProcessResult result) {
  return '${result.stdout}\n${result.stderr}';
}

String _joinPath(Iterable<String> components) {
  return components.join(Platform.pathSeparator);
}
