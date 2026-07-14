import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../shared/common_helpers.dart';
import 'external_payload_helpers.dart';

Option<String> wineWindowsPathToHostPath({
  required BottleRecord bottle,
  required String windowsPath,
}) {
  final normalized = windowsPath.trim().replaceAll('\\', '/');
  final hasControlCharacter = RegExp(
    r'[\x00-\x1F\x7F-\x9F]',
  ).hasMatch(windowsPath);
  final hasDotSegment = normalized
      .split('/')
      .any((part) => part == '.' || part == '..');

  return switch (hasControlCharacter || hasDotSegment) {
    true => const Option.none(),
    false =>
      nullableOption(
        RegExp(r'^([A-Za-z]):/(.*)$').firstMatch(normalized),
      ).match(
        () => normalized.startsWith('/')
            ? Option.of(normalized)
            : const Option.none(),
        (driveMatch) => nullableOption(driveMatch.group(1)).flatMap((rawDrive) {
          final drive = rawDrive.toLowerCase();
          final path = nullableOption(
            driveMatch.group(2),
          ).match(() => '', (value) => value);
          final parts = path
              .split('/')
              .where((part) => part.isNotEmpty)
              .toList(growable: false);

          return switch (drive) {
            'c' => Option.of(
              joinPath(bottle.path.value, <String>['drive_c', ...parts]),
            ),
            'z' => Option.of('/${parts.join('/')}'),
            _ => const Option.none(),
          };
        }),
      ),
  };
}
