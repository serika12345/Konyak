part of '../../konyak_cli.dart';

void _writeLinuxExternalProgramDesktopLauncher({
  required String launcherPath,
  required String launcherContents,
}) {
  final launcherDirectory = File(launcherPath).parent
    ..createSync(recursive: true);
  File(_joinPath(launcherDirectory.path, [_baseName(launcherPath)]))
    ..createSync(recursive: true)
    ..writeAsStringSync(launcherContents);
}

void _recordExternalProgramLaunch({
  required BottleRecord bottle,
  required String programPath,
}) {
  try {
    final launchIndexFile = File(
      _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
    );

    final existingEntries = <Map<String, Object?>>[];
    if (launchIndexFile.existsSync()) {
      final decoded = jsonDecode(launchIndexFile.readAsStringSync());
      final parsedEntries = _externalProgramLaunchEntriesFromDecoded(
        decoded,
        programPath: programPath,
      );
      parsedEntries.match(
        () => throw const FormatException('Invalid launch index payload.'),
        existingEntries.addAll,
      );
    }

    launchIndexFile.parent.createSync(recursive: true);
    launchIndexFile.writeAsStringSync(
      jsonEncode(
        _externalProgramLaunchIndexPayload(
          existingEntries: existingEntries,
          programPath: programPath,
        ),
      ),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  } on TypeError {
    return;
  }
}
