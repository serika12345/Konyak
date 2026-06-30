import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_list_load_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleListLoadState with _$BottleListLoadState {
  const factory BottleListLoadState.loading() = BottleListLoading;

  const factory BottleListLoadState.loaded() = BottleListLoaded;

  const factory BottleListLoadState.failed(String message) =
      BottleListLoadFailed;
}

bool isBottleListLoading(BottleListLoadState state) {
  return switch (state) {
    BottleListLoading() => true,
    BottleListLoaded() => false,
    BottleListLoadFailed() => false,
  };
}
