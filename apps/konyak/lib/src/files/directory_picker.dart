import 'package:file_selector/file_selector.dart';

import 'file_path_pick_result.dart';

abstract interface class DirectoryPicker {
  Future<FilePathPickResult> pickDirectoryPath();
}

final class FileSelectorDirectoryPicker implements DirectoryPicker {
  const FileSelectorDirectoryPicker();

  @override
  Future<FilePathPickResult> pickDirectoryPath() async {
    final path = await getDirectoryPath();
    return filePathPickResultFromNullable(path);
  }
}
