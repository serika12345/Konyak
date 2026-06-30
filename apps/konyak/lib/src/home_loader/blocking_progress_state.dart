import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocking_progress_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BlockingProgressState with _$BlockingProgressState {
  const factory BlockingProgressState.hidden() = HiddenBlockingProgress;

  const factory BlockingProgressState.indeterminate(String message) =
      IndeterminateBlockingProgress;

  const factory BlockingProgressState.determinate({
    required String message,
    required double progress,
  }) = DeterminateBlockingProgress;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BlockingProgressMessage with _$BlockingProgressMessage {
  const factory BlockingProgressMessage.none() = NoBlockingProgressMessage;

  const factory BlockingProgressMessage.indeterminate(String message) =
      IndeterminateBlockingProgressMessage;

  const factory BlockingProgressMessage.determinate({
    required String message,
    required double progress,
  }) = DeterminateBlockingProgressMessage;
}

BlockingProgressMessage blockingProgressMessage(BlockingProgressState state) {
  return switch (state) {
    HiddenBlockingProgress() => const BlockingProgressMessage.none(),
    IndeterminateBlockingProgress(:final message) =>
      BlockingProgressMessage.indeterminate(message),
    DeterminateBlockingProgress(:final message, :final progress) =>
      BlockingProgressMessage.determinate(message: message, progress: progress),
  };
}
