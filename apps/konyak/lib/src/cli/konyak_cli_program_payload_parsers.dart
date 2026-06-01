part of 'konyak_cli_client.dart';

BottleProgramListLoadResult _parseBottleProgramListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle program list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle program list failed.',
      diagnostic: '',
    );
  }

  final bottlePrograms = decoded['bottlePrograms'];
  if (bottlePrograms is! Map<String, Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Missing bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final bottleId = bottlePrograms['bottleId'];
  final programs = bottlePrograms['programs'];
  if (bottleId is! String || programs is! List<Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Invalid bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final parsedPrograms = <BottleProgramSummary>[];
  for (final program in programs) {
    if (program is! Map<String, Object?>) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final id = program['id'];
    final name = program['name'];
    final path = program['path'];
    final source = program['source'];
    if (id is! String ||
        name is! String ||
        path is! String ||
        source is! String) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final metadata = _parseProgramMetadata(program['metadata']);

    parsedPrograms.add(
      BottleProgramSummary(
        id: id,
        name: name,
        path: path,
        source: source,
        metadata: metadata,
      ),
    );
  }

  return LoadedBottlePrograms(
    bottleId: bottleId,
    programs: List.unmodifiable(parsedPrograms),
  );
}
