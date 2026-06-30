import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';

part 'bottle_lists.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleSelection with _$BottleSelection {
  const factory BottleSelection.found(BottleSummary bottle) =
      BottleSelectionFound;

  const factory BottleSelection.missing(String bottleId) =
      BottleSelectionMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class PinnedProgramSelection with _$PinnedProgramSelection {
  const factory PinnedProgramSelection.found(PinnedProgramSummary program) =
      PinnedProgramSelectionFound;

  const factory PinnedProgramSelection.missing(String programPath) =
      PinnedProgramSelectionMissing;
}

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

BottleSelection findBottleById(List<BottleSummary> bottles, String bottleId) {
  final matchingBottles = bottles
      .where((bottle) => bottle.id == bottleId)
      .take(1)
      .toList(growable: false);
  return switch (matchingBottles) {
    [final bottle] => BottleSelectionFound(bottle),
    _ => BottleSelectionMissing(bottleId),
  };
}

PinnedProgramSelection findPinnedProgramByPath(
  BottleSummary bottle,
  String programPath,
) {
  final matchingPrograms = bottle.pinnedPrograms
      .where((program) => program.path == programPath)
      .take(1)
      .toList(growable: false);
  return switch (matchingPrograms) {
    [final program] => PinnedProgramSelectionFound(program),
    _ => PinnedProgramSelectionMissing(programPath),
  };
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
