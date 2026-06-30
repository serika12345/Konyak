import '../../bottles/bottle_summary.dart';
import '../bottles/bottle_detail.dart';
import '../utils/bottle_lists.dart';

sealed class HomeNavigationBottleSelection {
  const HomeNavigationBottleSelection();
}

final class NoHomeNavigationBottle extends HomeNavigationBottleSelection {
  const NoHomeNavigationBottle();

  @override
  bool operator ==(Object other) {
    return other is NoHomeNavigationBottle;
  }

  @override
  int get hashCode {
    return 1;
  }
}

final class SelectedHomeNavigationBottle extends HomeNavigationBottleSelection {
  const SelectedHomeNavigationBottle(this.bottleId);

  final String bottleId;

  @override
  bool operator ==(Object other) {
    return other is SelectedHomeNavigationBottle && other.bottleId == bottleId;
  }

  @override
  int get hashCode {
    return Object.hash(SelectedHomeNavigationBottle, bottleId);
  }
}

sealed class HomeNavigationProgramSelection {
  const HomeNavigationProgramSelection();
}

final class NoHomeNavigationProgram extends HomeNavigationProgramSelection {
  const NoHomeNavigationProgram();

  @override
  bool operator ==(Object other) {
    return other is NoHomeNavigationProgram;
  }

  @override
  int get hashCode {
    return 2;
  }
}

final class SelectedHomeNavigationProgram
    extends HomeNavigationProgramSelection {
  const SelectedHomeNavigationProgram(this.programPath);

  final String programPath;

  @override
  bool operator ==(Object other) {
    return other is SelectedHomeNavigationProgram &&
        other.programPath == programPath;
  }

  @override
  int get hashCode {
    return Object.hash(SelectedHomeNavigationProgram, programPath);
  }
}

sealed class HomeNavigationBottleResolution {
  const HomeNavigationBottleResolution();
}

final class ResolvedHomeNavigationBottle
    extends HomeNavigationBottleResolution {
  const ResolvedHomeNavigationBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingHomeNavigationBottle extends HomeNavigationBottleResolution {
  const MissingHomeNavigationBottle(this.bottleId);

  final String bottleId;
}

final class UnselectedHomeNavigationBottle
    extends HomeNavigationBottleResolution {
  const UnselectedHomeNavigationBottle();
}

sealed class HomeNavigationProgramResolution {
  const HomeNavigationProgramResolution();
}

final class ResolvedHomeNavigationProgram
    extends HomeNavigationProgramResolution {
  const ResolvedHomeNavigationProgram(this.program);

  final PinnedProgramSummary program;
}

final class MissingHomeNavigationProgram
    extends HomeNavigationProgramResolution {
  const MissingHomeNavigationProgram(this.programPath);

  final String programPath;
}

final class UnselectedHomeNavigationProgram
    extends HomeNavigationProgramResolution {
  const UnselectedHomeNavigationProgram();
}

final class KonyakHomeNavigationState {
  const KonyakHomeNavigationState({
    this.selectedBottle = const NoHomeNavigationBottle(),
    this.detailMode = BottleDetailMode.overview,
    this.selectedProgram = const NoHomeNavigationProgram(),
  });

  final HomeNavigationBottleSelection selectedBottle;
  final BottleDetailMode detailMode;
  final HomeNavigationProgramSelection selectedProgram;

  HomeNavigationBottleResolution selectedBottleIn(List<BottleSummary> bottles) {
    return switch (selectedBottle) {
      SelectedHomeNavigationBottle(:final bottleId) => switch (findBottleById(
        bottles,
        bottleId,
      )) {
        BottleSelectionFound(:final bottle) => ResolvedHomeNavigationBottle(
          bottle,
        ),
        BottleSelectionMissing() => MissingHomeNavigationBottle(bottleId),
      },
      NoHomeNavigationBottle() => const UnselectedHomeNavigationBottle(),
    };
  }

  HomeNavigationProgramResolution selectedProgramIn(BottleSummary bottle) {
    return switch (selectedProgram) {
      SelectedHomeNavigationProgram(:final programPath) =>
        switch (findPinnedProgramByPath(bottle, programPath)) {
          PinnedProgramSelectionFound(:final program) =>
            ResolvedHomeNavigationProgram(program),
          PinnedProgramSelectionMissing() => MissingHomeNavigationProgram(
            programPath,
          ),
        },
      NoHomeNavigationProgram() => const UnselectedHomeNavigationProgram(),
    };
  }

  KonyakHomeNavigationState reconcile(List<BottleSummary> bottles) {
    final reconciledBottle = _reconcileBottleSelection(bottles);
    return switch (reconciledBottle.detailMode) {
      BottleDetailMode.programConfiguration
          when !reconciledBottle._selectedProgramExistsIn(bottles) =>
        KonyakHomeNavigationState(
          selectedBottle: reconciledBottle.selectedBottle,
        ),
      _ => reconciledBottle,
    };
  }

  KonyakHomeNavigationState _reconcileBottleSelection(
    List<BottleSummary> bottles,
  ) {
    return switch (selectedBottle) {
      SelectedHomeNavigationBottle(:final bottleId) => switch (findBottleById(
        bottles,
        bottleId,
      )) {
        BottleSelectionFound() => this,
        BottleSelectionMissing() => _selectFirstAvailableBottle(bottles),
      },
      NoHomeNavigationBottle() => _selectFirstAvailableBottle(bottles),
    };
  }

  KonyakHomeNavigationState _selectFirstAvailableBottle(
    List<BottleSummary> bottles,
  ) {
    return switch (bottles) {
      [final bottle, ...] => KonyakHomeNavigationState(
        selectedBottle: SelectedHomeNavigationBottle(bottle.id),
        detailMode: detailMode,
        selectedProgram: selectedProgram,
      ),
      _ => const KonyakHomeNavigationState(),
    };
  }

  bool _selectedProgramExistsIn(List<BottleSummary> bottles) {
    return switch ((selectedBottle, selectedProgram)) {
      (
        SelectedHomeNavigationBottle(:final bottleId),
        SelectedHomeNavigationProgram(:final programPath),
      ) =>
        switch (findBottleById(bottles, bottleId)) {
          BottleSelectionFound(:final bottle) =>
            switch (findPinnedProgramByPath(bottle, programPath)) {
              PinnedProgramSelectionFound() => true,
              PinnedProgramSelectionMissing() => false,
            },
          BottleSelectionMissing() => false,
        },
      _ => false,
    };
  }

  KonyakHomeNavigationState selectBottle(BottleSummary bottle) {
    return KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle(bottle.id),
    );
  }

  KonyakHomeNavigationState showBottleConfiguration(
    BottleSummary bottle, {
    required Iterable<String> lockedBottleIds,
  }) {
    if (lockedBottleIds.contains(bottle.id)) {
      return this;
    }

    return KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle(bottle.id),
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
      selectedBottle: SelectedHomeNavigationBottle(bottle.id),
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgram: SelectedHomeNavigationProgram(program.path),
    );
  }

  KonyakHomeNavigationState showBottleOverview({
    required List<BottleSummary> bottles,
    required Iterable<String> lockedBottleIds,
  }) {
    final isSelectedBottleLocked = switch (selectedBottle) {
      SelectedHomeNavigationBottle(:final bottleId) => switch (findBottleById(
        bottles,
        bottleId,
      )) {
        BottleSelectionFound(:final bottle) => lockedBottleIds.contains(
          bottle.id,
        ),
        BottleSelectionMissing() => false,
      },
      NoHomeNavigationBottle() => false,
    };
    if (isSelectedBottleLocked) {
      return this;
    }

    return KonyakHomeNavigationState(selectedBottle: selectedBottle);
  }

  @override
  bool operator ==(Object other) {
    return other is KonyakHomeNavigationState &&
        other.selectedBottle == selectedBottle &&
        other.detailMode == detailMode &&
        other.selectedProgram == selectedProgram;
  }

  @override
  int get hashCode {
    return Object.hash(selectedBottle, detailMode, selectedProgram);
  }
}
