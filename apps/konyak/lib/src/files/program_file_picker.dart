import 'package:file_selector/file_selector.dart';

import 'file_path_pick_result.dart';
import 'file_picker_arguments.dart';

abstract interface class ProgramFilePicker {
  Future<FilePathPickResult> pickProgramPath({
    FilePickerInitialDirectory initialDirectory =
        const FilePickerInitialDirectory.inherited(),
  });
}

List<XTypeGroup> windowsProgramFileTypeGroups() {
  return const [
    XTypeGroup(
      label: 'Windows programs',
      extensions: ['exe', 'msi', 'bat', 'cmd', 'lnk'],
    ),
  ];
}

final class FileSelectorProgramFilePicker implements ProgramFilePicker {
  const FileSelectorProgramFilePicker();

  @override
  Future<FilePathPickResult> pickProgramPath({
    FilePickerInitialDirectory initialDirectory =
        const FilePickerInitialDirectory.inherited(),
  }) async {
    final file = await openFile(
      initialDirectory: filePickerInitialDirectoryPath(initialDirectory),
      acceptedTypeGroups: windowsProgramFileTypeGroups(),
    );

    return filePathPickResultFromNullable(file?.path);
  }
}
