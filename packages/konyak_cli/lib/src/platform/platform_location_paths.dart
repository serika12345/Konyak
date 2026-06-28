import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../shared/common_helpers.dart';

Option<String> bottleLocationPath({
  required BottleRecord bottle,
  required String location,
}) {
  final normalized = location.trim().toLowerCase();
  return switch (normalized) {
    'root' => Option.of(bottle.path.value),
    'c-drive' => Option.of(joinPath(bottle.path.value, const ['drive_c'])),
    _ => const Option.none(),
  };
}

String programLocationPath(String programPath) {
  final normalized = normalizeFilesystemPath(programPath);
  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return normalized;
  }

  return normalized.substring(0, separator);
}
