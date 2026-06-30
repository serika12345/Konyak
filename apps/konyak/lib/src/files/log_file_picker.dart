import 'package:file_selector/file_selector.dart';

import 'file_path_pick_result.dart';
import 'file_picker_arguments.dart';

abstract interface class LogFilePicker {
  Future<FilePathPickResult> pickLogFilePath({
    FilePickerInitialDirectory initialDirectory =
        const FilePickerInitialDirectory.inherited(),
    FilePickerSuggestedName suggestedName =
        const FilePickerSuggestedName.inherited(),
  });
}

final class FileSelectorLogFilePicker implements LogFilePicker {
  const FileSelectorLogFilePicker();

  @override
  Future<FilePathPickResult> pickLogFilePath({
    FilePickerInitialDirectory initialDirectory =
        const FilePickerInitialDirectory.inherited(),
    FilePickerSuggestedName suggestedName =
        const FilePickerSuggestedName.inherited(),
  }) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Log files', extensions: ['log', 'cxlog', 'txt']),
      ],
      initialDirectory: filePickerInitialDirectoryPath(initialDirectory),
      suggestedName: filePickerSuggestedName(suggestedName),
      canCreateDirectories: true,
    );

    return filePathPickResultFromNullable(location?.path);
  }
}
