import 'package:file_selector/file_selector.dart';

abstract interface class GptkWineSourcePicker {
  Future<String?> pickSourcePath();
}

final class FileSelectorGptkWineSourcePicker implements GptkWineSourcePicker {
  const FileSelectorGptkWineSourcePicker();

  @override
  Future<String?> pickSourcePath() async {
    final dmg = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Game Porting Toolkit DMG',
          extensions: ['dmg'],
          uniformTypeIdentifiers: ['com.apple.disk-image'],
        ),
      ],
    );
    return dmg?.path;
  }
}
