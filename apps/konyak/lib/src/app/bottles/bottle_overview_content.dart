import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';
import '../home/bottle_list_load_state.dart';

part 'bottle_overview_content.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleOverviewContent with _$BottleOverviewContent {
  const factory BottleOverviewContent.empty(BottleListLoadState loadState) =
      EmptyBottleOverviewContent;

  const factory BottleOverviewContent.bottle(BottleSummary bottle) =
      SelectedBottleOverviewContent;
}
