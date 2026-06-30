import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';
import '../utils/bottle_lists.dart';
import 'home_contracts.dart';

part 'home_navigation_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class HomeNavigationBottleSelection
    with _$HomeNavigationBottleSelection {
  const factory HomeNavigationBottleSelection.none() = NoHomeNavigationBottle;

  const factory HomeNavigationBottleSelection.selected(String bottleId) =
      SelectedHomeNavigationBottle;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class HomeNavigationProgramSelection
    with _$HomeNavigationProgramSelection {
  const factory HomeNavigationProgramSelection.none() = NoHomeNavigationProgram;

  const factory HomeNavigationProgramSelection.selected(String programPath) =
      SelectedHomeNavigationProgram;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class HomeNavigationBottleResolution
    with _$HomeNavigationBottleResolution {
  const factory HomeNavigationBottleResolution.resolved(BottleSummary bottle) =
      ResolvedHomeNavigationBottle;

  const factory HomeNavigationBottleResolution.missing(String bottleId) =
      MissingHomeNavigationBottle;

  const factory HomeNavigationBottleResolution.unselected() =
      UnselectedHomeNavigationBottle;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class HomeNavigationProgramResolution
    with _$HomeNavigationProgramResolution {
  const factory HomeNavigationProgramResolution.resolved(
    PinnedProgramSummary program,
  ) = ResolvedHomeNavigationProgram;

  const factory HomeNavigationProgramResolution.missing(String programPath) =
      MissingHomeNavigationProgram;

  const factory HomeNavigationProgramResolution.unselected() =
      UnselectedHomeNavigationProgram;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class KonyakHomeNavigationState with _$KonyakHomeNavigationState {
  const KonyakHomeNavigationState._();

  const factory KonyakHomeNavigationState({
    @Default(NoHomeNavigationBottle())
    HomeNavigationBottleSelection selectedBottle,
    @Default(BottleDetailMode.overview) BottleDetailMode detailMode,
    @Default(NoHomeNavigationProgram())
    HomeNavigationProgramSelection selectedProgram,
  }) = _KonyakHomeNavigationState;

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

  KonyakHomeDetailSelection detailSelectionIn(List<BottleSummary> bottles) {
    return switch (_activeBottleIn(bottles)) {
      ResolvedHomeNavigationBottle(:final bottle) => switch (selectedProgramIn(
        bottle,
      )) {
        ResolvedHomeNavigationProgram(:final program) =>
          KonyakHomeDetailSelection.program(bottle: bottle, program: program),
        MissingHomeNavigationProgram() || UnselectedHomeNavigationProgram() =>
          KonyakHomeDetailSelection.bottle(bottle),
      },
      MissingHomeNavigationBottle() || UnselectedHomeNavigationBottle() =>
        const KonyakHomeDetailSelection.none(),
    };
  }

  HomeNavigationBottleSelection sidebarBottleSelectionIn(
    List<BottleSummary> bottles,
  ) {
    return switch (_activeBottleIn(bottles)) {
      ResolvedHomeNavigationBottle(:final bottle) =>
        SelectedHomeNavigationBottle(bottle.id),
      MissingHomeNavigationBottle() ||
      UnselectedHomeNavigationBottle() => const NoHomeNavigationBottle(),
    };
  }

  HomeNavigationBottleResolution _activeBottleIn(List<BottleSummary> bottles) {
    return switch (selectedBottleIn(bottles)) {
      ResolvedHomeNavigationBottle(:final bottle) =>
        ResolvedHomeNavigationBottle(bottle),
      MissingHomeNavigationBottle() ||
      UnselectedHomeNavigationBottle() => switch (bottles) {
        [final bottle, ...] => ResolvedHomeNavigationBottle(bottle),
        _ => const UnselectedHomeNavigationBottle(),
      },
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
}
