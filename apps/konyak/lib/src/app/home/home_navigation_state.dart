import '../../bottles/bottle_summary.dart';
import '../bottles/bottle_detail.dart';
import '../utils/bottle_lists.dart';

final class KonyakHomeNavigationState {
  const KonyakHomeNavigationState({
    this.selectedBottleId,
    this.detailMode = BottleDetailMode.overview,
    this.selectedProgramPath,
  });

  final String? selectedBottleId;
  final BottleDetailMode detailMode;
  final String? selectedProgramPath;

  BottleSummary? selectedBottleIn(List<BottleSummary> bottles) {
    return findSelectedBottle(bottles, selectedBottleId);
  }

  PinnedProgramSummary? selectedProgramIn(BottleSummary? bottle) {
    return findSelectedProgram(bottle, selectedProgramPath);
  }

  KonyakHomeNavigationState reconcile(List<BottleSummary> bottles) {
    var state = this;
    if (findSelectedBottle(bottles, state.selectedBottleId) == null) {
      final nextBottleId = bottles.isEmpty ? null : bottles.first.id;
      state = KonyakHomeNavigationState(
        selectedBottleId: nextBottleId,
        detailMode: nextBottleId == null
            ? BottleDetailMode.overview
            : state.detailMode,
        selectedProgramPath: nextBottleId == null
            ? null
            : state.selectedProgramPath,
      );
    }

    final selectedBottle = findSelectedBottle(bottles, state.selectedBottleId);
    if (state.detailMode == BottleDetailMode.programConfiguration &&
        findSelectedProgram(selectedBottle, state.selectedProgramPath) ==
            null) {
      return KonyakHomeNavigationState(
        selectedBottleId: state.selectedBottleId,
      );
    }

    return state;
  }

  KonyakHomeNavigationState selectBottle(BottleSummary bottle) {
    return KonyakHomeNavigationState(selectedBottleId: bottle.id);
  }

  KonyakHomeNavigationState showBottleConfiguration(
    BottleSummary bottle, {
    required Iterable<String> lockedBottleIds,
  }) {
    if (lockedBottleIds.contains(bottle.id)) {
      return this;
    }

    return KonyakHomeNavigationState(
      selectedBottleId: bottle.id,
      detailMode: BottleDetailMode.configuration,
    );
  }

  KonyakHomeNavigationState showPinnedProgramConfiguration(
    BottleSummary bottle,
    PinnedProgramSummary program, {
    required Iterable<String> lockedBottleIds,
  }) {
    if (lockedBottleIds.contains(bottle.id)) {
      return this;
    }

    return KonyakHomeNavigationState(
      selectedBottleId: bottle.id,
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgramPath: program.path,
    );
  }

  KonyakHomeNavigationState showBottleOverview({
    required List<BottleSummary> bottles,
    required Iterable<String> lockedBottleIds,
  }) {
    final selectedBottle = findSelectedBottle(bottles, selectedBottleId);
    if (selectedBottle != null && lockedBottleIds.contains(selectedBottle.id)) {
      return this;
    }

    return KonyakHomeNavigationState(selectedBottleId: selectedBottleId);
  }

  @override
  bool operator ==(Object other) {
    return other is KonyakHomeNavigationState &&
        other.selectedBottleId == selectedBottleId &&
        other.detailMode == detailMode &&
        other.selectedProgramPath == selectedProgramPath;
  }

  @override
  int get hashCode {
    return Object.hash(selectedBottleId, detailMode, selectedProgramPath);
  }
}
