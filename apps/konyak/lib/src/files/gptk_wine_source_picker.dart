import 'package:file_selector/file_selector.dart';

import 'file_path_pick_result.dart';

abstract interface class GptkWineSourcePicker {
  Future<FilePathPickResult> pickSourcePath();
}

final class FileSelectorGptkWineSourcePicker implements GptkWineSourcePicker {
  const FileSelectorGptkWineSourcePicker();

  @override
  Future<FilePathPickResult> pickSourcePath() async {
    final dmg = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Game Porting Toolkit DMG',
          extensions: ['dmg'],
          uniformTypeIdentifiers: ['com.apple.disk-image'],
        ),
      ],
    );
    return filePathPickResultFromNullable(dmg?.path);
  }
}
