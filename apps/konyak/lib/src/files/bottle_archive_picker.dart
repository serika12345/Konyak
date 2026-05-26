import 'package:file_selector/file_selector.dart';

abstract interface class BottleArchivePicker {
  Future<String?> pickArchiveToImport();

  Future<String?> pickArchiveExportPath({required String suggestedName});
}

final class FileSelectorBottleArchivePicker implements BottleArchivePicker {
  const FileSelectorBottleArchivePicker();

  static const _archiveTypes = [
    XTypeGroup(label: 'Konyak bottle archives', extensions: ['tar']),
    XTypeGroup(label: 'All files'),
  ];

  @override
  Future<String?> pickArchiveToImport() async {
    final file = await openFile(
      acceptedTypeGroups: _archiveTypes,
      confirmButtonText: 'Import',
    );

    return file?.path;
  }

  @override
  Future<String?> pickArchiveExportPath({required String suggestedName}) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: _archiveTypes,
      suggestedName: suggestedName,
      confirmButtonText: 'Export',
      canCreateDirectories: true,
    );

    return location?.path;
  }
}
