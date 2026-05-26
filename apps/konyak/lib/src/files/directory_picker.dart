import 'package:file_selector/file_selector.dart';

abstract interface class DirectoryPicker {
  Future<String?> pickDirectoryPath();
}

final class FileSelectorDirectoryPicker implements DirectoryPicker {
  const FileSelectorDirectoryPicker();

  @override
  Future<String?> pickDirectoryPath() {
    return getDirectoryPath();
  }
}
