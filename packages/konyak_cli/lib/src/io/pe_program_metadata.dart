import '../domain/program/program_catalog_models.dart';

String uniqueProgramId({
  required String baseId,
  required List<BottleProgramRecord> existing,
}) {
  final fallbackBaseId = baseId.isEmpty ? 'program' : baseId;
  if (existing.every((program) => program.id.value != fallbackBaseId)) {
    return fallbackBaseId;
  }

  return uniqueProgramIdWithSuffix(
    baseId: fallbackBaseId,
    existing: existing,
    suffix: 2,
  );
}

String uniqueProgramIdWithSuffix({
  required String baseId,
  required List<BottleProgramRecord> existing,
  required int suffix,
}) {
  final candidate = '$baseId-$suffix';
  return existing.any((program) => program.id.value == candidate)
      ? uniqueProgramIdWithSuffix(
          baseId: baseId,
          existing: existing,
          suffix: suffix + 1,
        )
      : candidate;
}
