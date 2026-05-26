import '../../bottles/bottle_summary.dart';

String programSettingsKey({
  required String bottleId,
  required String programPath,
}) {
  return '$bottleId:${programPath.trim().replaceAll(RegExp(r'/+$'), '')}';
}

List<BottleSummary> upsertBottle(
  List<BottleSummary> bottles,
  BottleSummary bottle,
) {
  final updated = <BottleSummary>[
    for (final existing in bottles)
      if (existing.id != bottle.id) existing,
    bottle,
  ]..sort((left, right) => left.name.compareTo(right.name));

  return List.unmodifiable(updated);
}

List<BottleSummary> removeBottle(List<BottleSummary> bottles, String bottleId) {
  return List.unmodifiable(bottles.where((bottle) => bottle.id != bottleId));
}

List<BottleSummary> replaceBottle(
  List<BottleSummary> bottles, {
  required String oldBottleId,
  required BottleSummary bottle,
}) {
  final updated = <BottleSummary>[
    for (final existing in bottles)
      if (existing.id != oldBottleId && existing.id != bottle.id) existing,
    bottle,
  ]..sort((left, right) => left.name.compareTo(right.name));

  return List.unmodifiable(updated);
}

BottleSummary? findSelectedBottle(
  List<BottleSummary> bottles,
  String? bottleId,
) {
  if (bottleId == null) {
    return null;
  }

  for (final bottle in bottles) {
    if (bottle.id == bottleId) {
      return bottle;
    }
  }

  return null;
}

PinnedProgramSummary? findSelectedProgram(
  BottleSummary? bottle,
  String? programPath,
) {
  if (bottle == null || programPath == null) {
    return null;
  }

  for (final program in bottle.pinnedPrograms) {
    if (program.path == programPath) {
      return program;
    }
  }

  return null;
}

List<BottleSummary> filterBottles({
  required List<BottleSummary> bottles,
  required String searchQuery,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return bottles;
  }

  return List.unmodifiable(
    bottles.where(
      (bottle) => bottle.name.toLowerCase().contains(normalizedQuery),
    ),
  );
}
