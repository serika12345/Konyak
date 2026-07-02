import 'package:freezed_annotation/freezed_annotation.dart';

part 'confirmation_decision.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ConfirmationDecision with _$ConfirmationDecision {
  const factory ConfirmationDecision.confirmed() = ConfirmedDialogDecision;

  const factory ConfirmationDecision.cancelled() = CancelledDialogDecision;
}
