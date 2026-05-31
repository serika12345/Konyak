import 'package:file_selector/file_selector.dart';

abstract interface class GptkWineSourcePicker {
  Future<String?> pickSourcePath();
}

final class FileSelectorGptkWineSourcePicker implements GptkWineSourcePicker {
  const FileSelectorGptkWineSourcePicker();

  @override
  Future<String?> pickSourcePath() async {
    final app = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Applications',
          uniformTypeIdentifiers: ['com.apple.application-bundle'],
        ),
      ],
    );
    if (app != null) {
      return app.path;
    }

    return getDirectoryPath();
  }
}
