import 'package:freezed_annotation/freezed_annotation.dart';

import '../runtimes/runtime_summary.dart';

part 'known_runtimes_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class KnownRuntimesState with _$KnownRuntimesState {
  const KnownRuntimesState._();

  const factory KnownRuntimesState.pending() = _KnownRuntimesPending;

  factory KnownRuntimesState.loaded(List<RuntimeSummary> runtimes) {
    return KnownRuntimesState._loaded(List.unmodifiable(runtimes));
  }

  const factory KnownRuntimesState._loaded(List<RuntimeSummary> runtimes) =
      _KnownRuntimesLoaded;

  List<RuntimeSummary> get runtimes {
    return switch (this) {
      _KnownRuntimesPending() => const <RuntimeSummary>[],
      _KnownRuntimesLoaded(:final runtimes) => runtimes,
    };
  }

  bool get isLoaded {
    return switch (this) {
      _KnownRuntimesPending() => false,
      _KnownRuntimesLoaded() => true,
    };
  }
}
