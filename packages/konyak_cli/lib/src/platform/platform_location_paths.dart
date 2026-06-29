import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';

Option<String> bottleLocationPath({
  required BottleRecord bottle,
  required BottleLocation location,
}) {
  final normalized = location.value.trim().toLowerCase();
  return switch (normalized) {
    'root' => Option.of(bottle.path.value),
    'c-drive' => Option.of(joinPath(bottle.path.value, const ['drive_c'])),
    _ => const Option.none(),
  };
}

String programLocationPath(ProgramPath programPath) {
  final normalized = normalizeFilesystemPath(programPath.value);
  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return normalized;
  }

  return normalized.substring(0, separator);
}
