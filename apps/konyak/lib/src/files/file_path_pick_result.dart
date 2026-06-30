import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_path_pick_result.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class FilePathPickResult with _$FilePathPickResult {
  const factory FilePathPickResult.picked(String path) = PickedFilePath;

  const factory FilePathPickResult.cancelled() = CancelledFilePathPick;
}

FilePathPickResult filePathPickResultFromNullable(String? path) {
  return switch (path) {
    final String value when value.trim().isNotEmpty =>
      FilePathPickResult.picked(value),
    _ => const FilePathPickResult.cancelled(),
  };
}
