import 'package:freezed_annotation/freezed_annotation.dart';

import '../app/home/bottle_list_load_state.dart';
import '../app/utils/bottle_lists.dart';
import '../bottles/bottle_summary.dart';

part 'home_bottle_list_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class HomeBottleListState with _$HomeBottleListState {
  const HomeBottleListState._();

  factory HomeBottleListState.loading({
    Iterable<BottleSummary> bottles = const <BottleSummary>[],
  }) {
    return HomeBottleListState._loading(List.unmodifiable(bottles));
  }

  const factory HomeBottleListState._loading(List<BottleSummary> bottles) =
      LoadingHomeBottleListState;

  factory HomeBottleListState.loaded(Iterable<BottleSummary> bottles) {
    return HomeBottleListState._loaded(List.unmodifiable(bottles));
  }

  const factory HomeBottleListState._loaded(List<BottleSummary> bottles) =
      LoadedHomeBottleListState;

  factory HomeBottleListState.failed({
    required String message,
    Iterable<BottleSummary> bottles = const <BottleSummary>[],
  }) {
    return HomeBottleListState._failed(
      message: message,
      bottles: List.unmodifiable(bottles),
    );
  }

  const factory HomeBottleListState._failed({
    required String message,
    required List<BottleSummary> bottles,
  }) = FailedHomeBottleListState;
}

HomeBottleListState startLoadingHomeBottleList(HomeBottleListState state) {
  return HomeBottleListState.loading(bottles: homeBottleListBottles(state));
}

HomeBottleListState loadHomeBottleList(Iterable<BottleSummary> bottles) {
  return HomeBottleListState.loaded(bottles);
}

HomeBottleListState failHomeBottleListLoad({
  required HomeBottleListState state,
  required String message,
}) {
  return HomeBottleListState.failed(
    message: message,
    bottles: homeBottleListBottles(state),
  );
}

HomeBottleListState storeHomeBottle({
  required HomeBottleListState state,
  required BottleSummary bottle,
  String? oldBottleId,
}) {
  final bottles = homeBottleListBottles(state);
  return HomeBottleListState.loaded(
    oldBottleId == null
        ? upsertBottle(bottles, bottle)
        : replaceBottle(bottles, oldBottleId: oldBottleId, bottle: bottle),
  );
}

HomeBottleListState removeHomeBottle({
  required HomeBottleListState state,
  required String bottleId,
}) {
  return HomeBottleListState.loaded(
    removeBottle(homeBottleListBottles(state), bottleId),
  );
}

List<BottleSummary> homeBottleListBottles(HomeBottleListState state) {
  return switch (state) {
    LoadingHomeBottleListState(:final bottles) => bottles,
    LoadedHomeBottleListState(:final bottles) => bottles,
    FailedHomeBottleListState(:final bottles) => bottles,
  };
}

BottleListLoadState homeBottleListLoadState(HomeBottleListState state) {
  return switch (state) {
    LoadingHomeBottleListState() => const BottleListLoadState.loading(),
    LoadedHomeBottleListState() => const BottleListLoadState.loaded(),
    FailedHomeBottleListState(:final message) => BottleListLoadState.failed(
      message,
    ),
  };
}
