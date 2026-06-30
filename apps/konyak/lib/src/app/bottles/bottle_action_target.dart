import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';

part 'bottle_action_target.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleActionTarget with _$BottleActionTarget {
  const factory BottleActionTarget.none() = NoBottleActionTarget;

  const factory BottleActionTarget.bottle(BottleSummary bottle) =
      SelectedBottleActionTarget;
}
