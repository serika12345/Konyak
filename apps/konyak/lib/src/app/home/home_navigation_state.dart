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
    return switch (selectedBottleId) {
      final bottleId? => switch (findBottleById(bottles, bottleId)) {
        BottleSelectionFound(:final bottle) => bottle,
        BottleSelectionMissing() => null,
      },
      null => null,
    };
  }

  PinnedProgramSummary? selectedProgramIn(BottleSummary? bottle) {
    return switch ((bottle, selectedProgramPath)) {
      (final selectedBottle?, final programPath?) =>
        switch (findPinnedProgramByPath(selectedBottle, programPath)) {
          PinnedProgramSelectionFound(:final program) => program,
          PinnedProgramSelectionMissing() => null,
        },
      _ => null,
    };
  }

  KonyakHomeNavigationState reconcile(List<BottleSummary> bottles) {
    final reconciledBottle = _reconcileBottleSelection(bottles);
    return switch (reconciledBottle.detailMode) {
      BottleDetailMode.programConfiguration
          when reconciledBottle.selectedProgramIn(
                reconciledBottle.selectedBottleIn(bottles),
              ) ==
              null =>
        KonyakHomeNavigationState(
          selectedBottleId: reconciledBottle.selectedBottleId,
        ),
      _ => reconciledBottle,
    };
  }

  KonyakHomeNavigationState _reconcileBottleSelection(
    List<BottleSummary> bottles,
  ) {
    return switch (selectedBottleId) {
      final bottleId? => switch (findBottleById(bottles, bottleId)) {
        BottleSelectionFound() => this,
        BottleSelectionMissing() => _selectFirstAvailableBottle(bottles),
      },
      null => _selectFirstAvailableBottle(bottles),
    };
  }

  KonyakHomeNavigationState _selectFirstAvailableBottle(
    List<BottleSummary> bottles,
  ) {
    return switch (bottles) {
      [final bottle, ...] => KonyakHomeNavigationState(
        selectedBottleId: bottle.id,
        detailMode: detailMode,
        selectedProgramPath: selectedProgramPath,
      ),
      _ => const KonyakHomeNavigationState(),
    };
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
    final isSelectedBottleLocked = switch (selectedBottleId) {
      final bottleId? => switch (findBottleById(bottles, bottleId)) {
        BottleSelectionFound(:final bottle) => lockedBottleIds.contains(
          bottle.id,
        ),
        BottleSelectionMissing() => false,
      },
      null => false,
    };
    if (isSelectedBottleLocked) {
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
