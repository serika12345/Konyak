import 'package:file_selector/file_selector.dart';

import 'file_path_pick_result.dart';

abstract interface class InstallProfileManifestPicker {
  Future<FilePathPickResult> pickProfileToImport();

  Future<FilePathPickResult> pickProfileExportPath({
    required String suggestedName,
  });
}

final class FileSelectorInstallProfileManifestPicker
    implements InstallProfileManifestPicker {
  const FileSelectorInstallProfileManifestPicker();

  static const _profileTypes = [
    XTypeGroup(label: 'Konyak profile manifests', extensions: ['json']),
    XTypeGroup(label: 'All files'),
  ];

  @override
  Future<FilePathPickResult> pickProfileToImport() async {
    final file = await openFile(
      acceptedTypeGroups: _profileTypes,
      confirmButtonText: 'Import',
    );

    return filePathPickResultFromNullable(file?.path);
  }

  @override
  Future<FilePathPickResult> pickProfileExportPath({
    required String suggestedName,
  }) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: _profileTypes,
      suggestedName: suggestedName,
      confirmButtonText: 'Export',
      canCreateDirectories: true,
    );

    return filePathPickResultFromNullable(location?.path);
  }
}
