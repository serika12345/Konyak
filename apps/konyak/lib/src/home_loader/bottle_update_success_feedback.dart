import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottles/bottle_summary.dart';

part 'bottle_update_success_feedback.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleUpdateSuccessFeedback with _$BottleUpdateSuccessFeedback {
  const factory BottleUpdateSuccessFeedback.silent() =
      SilentBottleUpdateSuccessFeedback;

  const factory BottleUpdateSuccessFeedback.message(
    String Function(BottleSummary bottle) message,
  ) = MessageBottleUpdateSuccessFeedback;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleUpdateSuccessNotice with _$BottleUpdateSuccessNotice {
  const factory BottleUpdateSuccessNotice.none() = NoBottleUpdateSuccessNotice;

  const factory BottleUpdateSuccessNotice.message(String message) =
      MessageBottleUpdateSuccessNotice;
}

BottleUpdateSuccessNotice bottleUpdateSuccessNotice({
  required BottleUpdateSuccessFeedback feedback,
  required BottleSummary bottle,
}) {
  return switch (feedback) {
    SilentBottleUpdateSuccessFeedback() =>
      const BottleUpdateSuccessNotice.none(),
    MessageBottleUpdateSuccessFeedback(:final message) =>
      BottleUpdateSuccessNotice.message(message(bottle)),
  };
}
