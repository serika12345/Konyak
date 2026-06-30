import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_reader.freezed.dart';

abstract interface class LogReader {
  Future<LogReadResult> readLog(String path);
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class LogReadResult with _$LogReadResult {
  const factory LogReadResult.read({required String content}) = ReadLog;

  const factory LogReadResult.failure({required String message}) =
      LogReadFailure;
}
