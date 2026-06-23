part of '../../konyak_cli.dart';

void _writeLinuxFileAssociationFiles({
  required String desktopEntryPath,
  required String desktopEntry,
  required String? iconSourcePath,
  required String? iconTargetPath,
  required String? iconThemePath,
  required String mimeAppsPath,
}) {
  final desktopEntryFile = File(desktopEntryPath);
  desktopEntryFile.parent.createSync(recursive: true);
  desktopEntryFile.writeAsStringSync(desktopEntry);

  if (iconSourcePath != null && iconTargetPath != null) {
    final iconFile = File(iconTargetPath);
    iconFile.parent.createSync(recursive: true);
    File(iconSourcePath).copySync(iconTargetPath);
  }

  final mimeApps = File(mimeAppsPath);
  mimeApps.parent.createSync(recursive: true);
  mimeApps.writeAsStringSync(
    _linuxMimeAppsWithKonyakDefaults(
      existing: mimeApps.existsSync() ? mimeApps.readAsStringSync() : '',
    ),
  );

  _refreshLinuxDesktopIntegrationCaches(
    applicationsPath: desktopEntryFile.parent.path,
    iconThemePath: iconThemePath,
  );
}

void _refreshLinuxDesktopIntegrationCaches({
  required String applicationsPath,
  required String? iconThemePath,
}) {
  _runBestEffortLinuxDesktopCacheCommand('update-desktop-database', [
    applicationsPath,
  ]);

  if (iconThemePath != null) {
    _runBestEffortLinuxDesktopCacheCommand('gtk-update-icon-cache', [
      '-q',
      iconThemePath,
    ]);
  }
}

void _runBestEffortLinuxDesktopCacheCommand(
  String executable,
  List<String> arguments,
) {
  try {
    Process.runSync(executable, arguments);
  } on ProcessException {
    return;
  }
}
