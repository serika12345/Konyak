import 'dart:convert';
import 'dart:io';

import '../domain/bottle/bottle_models.dart';
import '../shared/common_helpers.dart';
import 'external_program_launch_records.dart';

void writeLinuxExternalProgramDesktopLauncher({
  required String launcherPath,
  required String launcherContents,
}) {
  final launcherDirectory = File(launcherPath).parent
    ..createSync(recursive: true);
  File(joinPath(launcherDirectory.path, [baseName(launcherPath)]))
    ..createSync(recursive: true)
    ..writeAsStringSync(launcherContents);
}

void recordExternalProgramLaunch({
  required BottleRecord bottle,
  required String programPath,
}) {
  try {
    final launchIndexFile = File(
      joinPath(bottle.path.value, const [
        'cache',
        'external-program-launches.json',
      ]),
    );

    final existingEntries = <Map<String, Object?>>[];
    if (launchIndexFile.existsSync()) {
      final decoded = jsonDecode(launchIndexFile.readAsStringSync());
      final parsedEntries = externalProgramLaunchEntriesFromDecoded(
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
        externalProgramLaunchIndexPayload(
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
