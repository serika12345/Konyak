part of '../konyak_cli.dart';

ProgramSettingsRecord _readProgramSettingsJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const ProgramSettingsRecord();
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final settings = ProgramSettingsRecord.fromJson(decoded);
  if (settings == null) {
    throw const FormatException('Program settings contain an invalid record.');
  }

  return settings;
}

void _writeProgramSettingsJson({
  required String path,
  required ProgramSettingsRecord settings,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(settings.toJson()),
  );
}

BottleRecord _readBottleMetadata(String bottlePath) {
  final metadata = File(_joinPath(bottlePath, const ['metadata.json']));
  final decoded = jsonDecode(metadata.readAsStringSync());

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Bottle metadata must be an object.');
  }

  if (decoded['schemaVersion'] != cliSchemaVersion) {
    throw const FormatException('Unsupported bottle metadata schema version.');
  }

  final bottle = BottleRecord.fromJson(decoded['bottle']);
  if (bottle == null) {
    throw const FormatException('Bottle metadata contains an invalid record.');
  }

  return bottle;
}

void _writeBottleMetadata(BottleRecord bottle) {
  final metadata = File(_joinPath(bottle.path, const ['metadata.json']));
  metadata.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'bottle': bottle.toJson(),
    }),
  );
}
