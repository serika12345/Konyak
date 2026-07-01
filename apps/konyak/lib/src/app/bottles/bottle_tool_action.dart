import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_tool_action.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleToolAction with _$BottleToolAction {
  const BottleToolAction._();

  const factory BottleToolAction.command(String id) = CommandBottleToolAction;

  const factory BottleToolAction.location(String id) = LocationBottleToolAction;

  BottleToolActionKind get kind {
    return switch (this) {
      CommandBottleToolAction() => BottleToolActionKind.command,
      LocationBottleToolAction() => BottleToolActionKind.location,
    };
  }
}

enum BottleToolActionKind { command, location }
