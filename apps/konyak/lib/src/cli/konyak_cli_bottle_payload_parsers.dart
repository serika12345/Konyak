part of 'konyak_cli_client.dart';

sealed class _BottleDeleteParseResult {
  const _BottleDeleteParseResult();
}

BottleArchiveExportLoadResult _parseBottleArchiveExportPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle archive export payload.',
      diagnostic: '',
    );
  }

  final archive = decoded['bottleArchive'];
  if (archive is! Map<String, Object?>) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Missing bottleArchive payload.',
      diagnostic: '',
    );
  }

  final bottleId = archive['bottleId'];
  final archivePath = archive['archivePath'];
  if (bottleId is! String || archivePath is! String) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Invalid bottleArchive payload.',
      diagnostic: '',
    );
  }

  return ExportedBottleArchive(bottleId: bottleId, archivePath: archivePath);
}

final class _ParsedBottleDelete extends _BottleDeleteParseResult {
  const _ParsedBottleDelete(this.bottle);

  final BottleSummary bottle;
}

final class _BottleDeleteNotFound extends _BottleDeleteParseResult {
  const _BottleDeleteNotFound({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class _BottleDeleteParseFailure extends _BottleDeleteParseResult {
  const _BottleDeleteParseFailure(this.message);

  final String message;
}

_BottleDeleteParseResult _parseBottleDeletePayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload must be an object.',
    );
  }

  if (decoded['schemaVersion'] != 1) {
    return const _BottleDeleteParseFailure(
      'Unsupported bottle delete schema version.',
    );
  }

  final notFound = _parseBottleDeleteNotFound(decoded['error']);
  if (notFound != null) {
    return notFound;
  }

  final bottle = parseBottleSummary(decoded['deletedBottle']);
  if (bottle == null) {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload contains an invalid bottle record.',
    );
  }

  return _ParsedBottleDelete(bottle);
}

_BottleDeleteNotFound? _parseBottleDeleteNotFound(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleNotFound' || message is! String || bottleId is! String) {
    return null;
  }

  return _BottleDeleteNotFound(bottleId: bottleId, message: message);
}

BottleLocationOpenResult _parseBottleLocationOpenPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleLocationOpenFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Unsupported bottle location open payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleLocationOpenFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle location open failed.',
      diagnostic: '',
    );
  }

  final openedLocation = decoded['openedLocation'];
  if (openedLocation is! Map<String, Object?>) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Missing openedLocation payload.',
      diagnostic: '',
    );
  }

  final bottleId = openedLocation['bottleId'];
  final location = openedLocation['location'];
  final path = openedLocation['path'];
  if (bottleId is! String || location is! String || path is! String) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Invalid openedLocation payload.',
      diagnostic: '',
    );
  }

  return OpenedBottleLocation(
    bottleId: bottleId,
    location: location,
    path: path,
  );
}

ProgramLocationOpenResult _parseProgramLocationOpenPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramLocationOpenFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Unsupported program location open payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return ProgramLocationOpenFailure(
      exitCode: 0,
      message: message is String ? message : 'Program location open failed.',
      diagnostic: '',
    );
  }

  final openedLocation = decoded['openedProgramLocation'];
  if (openedLocation is! Map<String, Object?>) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Missing openedProgramLocation payload.',
      diagnostic: '',
    );
  }

  final bottleId = openedLocation['bottleId'];
  final programPath = openedLocation['programPath'];
  final path = openedLocation['path'];
  if (bottleId is! String || programPath is! String || path is! String) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Invalid openedProgramLocation payload.',
      diagnostic: '',
    );
  }

  return OpenedProgramLocation(
    bottleId: bottleId,
    programPath: programPath,
    path: path,
  );
}
