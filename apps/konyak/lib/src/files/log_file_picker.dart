import 'package:file_selector/file_selector.dart';

abstract interface class LogFilePicker {
  Future<String?> pickLogFilePath({
    String? initialDirectory,
    String? suggestedName,
  });
}

final class FileSelectorLogFilePicker implements LogFilePicker {
  const FileSelectorLogFilePicker();

  @override
  Future<String?> pickLogFilePath({
    String? initialDirectory,
    String? suggestedName,
  }) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Log files', extensions: ['log', 'cxlog', 'txt']),
      ],
      initialDirectory: initialDirectory,
      suggestedName: suggestedName,
      canCreateDirectories: true,
    );

    return location?.path;
  }
}
