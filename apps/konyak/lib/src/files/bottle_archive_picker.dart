import 'package:file_selector/file_selector.dart';

import 'file_path_pick_result.dart';

abstract interface class BottleArchivePicker {
  Future<FilePathPickResult> pickArchiveToImport();

  Future<FilePathPickResult> pickArchiveExportPath({
    required String suggestedName,
  });
}

final class FileSelectorBottleArchivePicker implements BottleArchivePicker {
  const FileSelectorBottleArchivePicker();

  static const _archiveTypes = [
    XTypeGroup(label: 'Konyak bottle archives', extensions: ['tar']),
    XTypeGroup(label: 'All files'),
  ];

  @override
  Future<FilePathPickResult> pickArchiveToImport() async {
    final file = await openFile(
      acceptedTypeGroups: _archiveTypes,
      confirmButtonText: 'Import',
    );

    return filePathPickResultFromNullable(file?.path);
  }

  @override
  Future<FilePathPickResult> pickArchiveExportPath({
    required String suggestedName,
  }) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: _archiveTypes,
      suggestedName: suggestedName,
      confirmButtonText: 'Export',
      canCreateDirectories: true,
    );

    return filePathPickResultFromNullable(location?.path);
  }
}
