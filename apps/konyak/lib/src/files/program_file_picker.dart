import 'package:file_selector/file_selector.dart';

abstract interface class ProgramFilePicker {
  Future<String?> pickProgramPath();
}

final class FileSelectorProgramFilePicker implements ProgramFilePicker {
  const FileSelectorProgramFilePicker();

  @override
  Future<String?> pickProgramPath() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Windows programs',
          extensions: ['exe', 'msi', 'bat', 'cmd', 'lnk'],
        ),
        XTypeGroup(label: 'All files'),
      ],
    );

    return file?.path;
  }
}
