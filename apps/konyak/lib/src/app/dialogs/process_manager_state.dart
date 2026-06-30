import 'package:freezed_annotation/freezed_annotation.dart';

import '../../cli/konyak_cli_wine_process_result_types.dart';

part 'process_manager_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProcessManagerState with _$ProcessManagerState {
  const factory ProcessManagerState.loading() = LoadingProcessManagerState;

  factory ProcessManagerState.loaded(List<WineProcessSummary> processes) {
    return ProcessManagerState._loaded(List.unmodifiable(processes));
  }

  const factory ProcessManagerState._loaded(
    List<WineProcessSummary> processes,
  ) = LoadedProcessManagerState;

  const factory ProcessManagerState.failed(String message) =
      FailedProcessManagerState;
}

ProcessManagerState processManagerStateFromLoadResult(
  WineProcessListLoadResult result,
) {
  return switch (result) {
    LoadedWineProcesses(:final processes) => ProcessManagerState.loaded(
      processes,
    ),
    WineProcessListLoadFailure(:final message) => ProcessManagerState.failed(
      message,
    ),
  };
}

bool isProcessManagerLoading(ProcessManagerState state) {
  return switch (state) {
    LoadingProcessManagerState() => true,
    LoadedProcessManagerState() => false,
    FailedProcessManagerState() => false,
  };
}

ProcessManagerState removeProcessFromManagerState({
  required ProcessManagerState state,
  required String processKey,
}) {
  return switch (state) {
    LoadedProcessManagerState(:final processes) => ProcessManagerState.loaded(
      processes
          .where(
            (candidate) => processManagerProcessKey(candidate) != processKey,
          )
          .toList(growable: false),
    ),
    LoadingProcessManagerState() => state,
    FailedProcessManagerState() => state,
  };
}

String processManagerProcessKey(WineProcessSummary process) {
  return '${process.bottleId}-${process.processId}';
}
