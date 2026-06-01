part of '../konyak_cli.dart';

String _uniqueProgramId({
  required String baseId,
  required List<BottleProgramRecord> existing,
}) {
  final fallbackBaseId = baseId.isEmpty ? 'program' : baseId;
  if (existing.every((program) => program.id != fallbackBaseId)) {
    return fallbackBaseId;
  }

  var suffix = 2;
  while (existing.any((program) => program.id == '$fallbackBaseId-$suffix')) {
    suffix += 1;
  }

  return '$fallbackBaseId-$suffix';
}
