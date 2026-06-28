import 'dart:io';

import 'linux_file_associations.dart';

void writeLinuxFileAssociationFiles({
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
    linuxMimeAppsWithKonyakDefaults(
      existing: mimeApps.existsSync() ? mimeApps.readAsStringSync() : '',
    ),
  );

  refreshLinuxDesktopIntegrationCaches(
    applicationsPath: desktopEntryFile.parent.path,
    iconThemePath: iconThemePath,
  );
}

void refreshLinuxDesktopIntegrationCaches({
  required String applicationsPath,
  required String? iconThemePath,
}) {
  runBestEffortLinuxDesktopCacheCommand('update-desktop-database', [
    applicationsPath,
  ]);

  if (iconThemePath != null) {
    runBestEffortLinuxDesktopCacheCommand('gtk-update-icon-cache', [
      '-q',
      iconThemePath,
    ]);
  }
}

void runBestEffortLinuxDesktopCacheCommand(
  String executable,
  List<String> arguments,
) {
  try {
    Process.runSync(executable, arguments);
  } on ProcessException {
    return;
  }
}
