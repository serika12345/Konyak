import 'package:freezed_annotation/freezed_annotation.dart';

part 'wine_process_close_cleanup_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class WineProcessCloseCleanupState with _$WineProcessCloseCleanupState {
  const factory WineProcessCloseCleanupState.notRequested() =
      WineProcessCloseCleanupNotRequested;

  const factory WineProcessCloseCleanupState.requested() =
      WineProcessCloseCleanupRequested;
}

bool shouldRequestWineProcessCloseCleanup(WineProcessCloseCleanupState state) {
  return switch (state) {
    WineProcessCloseCleanupNotRequested() => true,
    WineProcessCloseCleanupRequested() => false,
  };
}

bool hasRequestedWineProcessCloseCleanup(WineProcessCloseCleanupState state) {
  return switch (state) {
    WineProcessCloseCleanupNotRequested() => false,
    WineProcessCloseCleanupRequested() => true,
  };
}

WineProcessCloseCleanupState requestWineProcessCloseCleanup(
  WineProcessCloseCleanupState state,
) {
  return switch (state) {
    WineProcessCloseCleanupNotRequested() =>
      const WineProcessCloseCleanupState.requested(),
    WineProcessCloseCleanupRequested() => state,
  };
}
