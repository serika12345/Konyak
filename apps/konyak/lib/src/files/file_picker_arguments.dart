import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_picker_arguments.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class FilePickerInitialDirectory with _$FilePickerInitialDirectory {
  const factory FilePickerInitialDirectory.path(String path) =
      UseFilePickerInitialDirectory;

  const factory FilePickerInitialDirectory.inherited() =
      InheritedFilePickerInitialDirectory;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class FilePickerSuggestedName with _$FilePickerSuggestedName {
  const factory FilePickerSuggestedName.name(String name) =
      UseFilePickerSuggestedName;

  const factory FilePickerSuggestedName.inherited() =
      InheritedFilePickerSuggestedName;
}

FilePickerInitialDirectory filePickerInitialDirectoryFromPath(String path) {
  return switch (path.trim()) {
    final directoryPath when directoryPath.isNotEmpty =>
      FilePickerInitialDirectory.path(directoryPath),
    _ => const FilePickerInitialDirectory.inherited(),
  };
}

FilePickerSuggestedName filePickerSuggestedNameFromPath({
  required String path,
  String fallback = '',
}) {
  final normalized = path.trim();
  final candidate = switch (normalized) {
    '' => fallback.trim(),
    _ => switch (normalized.lastIndexOf('/')) {
      -1 => normalized,
      final separator => normalized.substring(separator + 1).trim(),
    },
  };
  return switch (candidate) {
    final name when name.isNotEmpty => FilePickerSuggestedName.name(name),
    _ => const FilePickerSuggestedName.inherited(),
  };
}

String? filePickerInitialDirectoryPath(FilePickerInitialDirectory directory) {
  return switch (directory) {
    UseFilePickerInitialDirectory(:final path) => path,
    InheritedFilePickerInitialDirectory() => null,
  };
}

String? filePickerSuggestedName(FilePickerSuggestedName suggestedName) {
  return switch (suggestedName) {
    UseFilePickerSuggestedName(:final name) => name,
    InheritedFilePickerSuggestedName() => null,
  };
}
