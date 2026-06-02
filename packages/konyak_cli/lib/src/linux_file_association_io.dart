part of '../konyak_cli.dart';

void _writeLinuxFileAssociationFiles({
  required String desktopEntryPath,
  required String desktopEntry,
  required String mimeAppsPath,
}) {
  final desktopEntryFile = File(desktopEntryPath);
  desktopEntryFile.parent.createSync(recursive: true);
  desktopEntryFile.writeAsStringSync(desktopEntry);

  final mimeApps = File(mimeAppsPath);
  mimeApps.parent.createSync(recursive: true);
  mimeApps.writeAsStringSync(
    _linuxMimeAppsWithKonyakDefaults(
      existing: mimeApps.existsSync() ? mimeApps.readAsStringSync() : '',
    ),
  );
}
