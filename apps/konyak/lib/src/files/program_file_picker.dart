import 'package:file_selector/file_selector.dart';

abstract interface class ProgramFilePicker {
  Future<String?> pickProgramPath({String? initialDirectory});
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
  Future<String?> pickProgramPath({String? initialDirectory}) async {
    final file = await openFile(
      initialDirectory: initialDirectory,
      acceptedTypeGroups: windowsProgramFileTypeGroups(),
    );

    return file?.path;
  }
}
