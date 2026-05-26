import 'package:file_selector/file_selector.dart';

abstract interface class ProgramFilePicker {
  Future<String?> pickProgramPath();
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
  Future<String?> pickProgramPath() async {
    final file = await openFile(
      acceptedTypeGroups: windowsProgramFileTypeGroups(),
    );

    return file?.path;
  }
}
