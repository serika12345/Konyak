part of '../../konyak_cli.dart';

Option<String> _bottleLocationPath({
  required BottleRecord bottle,
  required String location,
}) {
  final normalized = location.trim().toLowerCase();
  return switch (normalized) {
    'root' => Option.of(bottle.path.value),
    'c-drive' => Option.of(_joinPath(bottle.path.value, const ['drive_c'])),
    _ => const Option.none(),
  };
}

String _programLocationPath(String programPath) {
  final normalized = _normalizeFilesystemPath(programPath);
  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return normalized;
  }

  return normalized.substring(0, separator);
}
