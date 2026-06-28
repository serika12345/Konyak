part of '../../konyak_cli.dart';

Option<RuntimeSourceManifest> _runtimeStackSourceManifestFromPayload(
  String payload,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const Option.none();
  }

  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return const Option.none();
  }

  final runtimeId = decoded['runtimeId'];
  final stackId = decoded['stackId'];
  final components = decoded['components'];
  if (runtimeId is! String ||
      runtimeId.trim().isEmpty ||
      stackId is! String ||
      stackId.trim().isEmpty ||
      components is! List<dynamic>) {
    return const Option.none();
  }

  final parsedComponents = <RuntimeSourceComponent>[];
  for (final component in components) {
    switch (_runtimeStackSourceComponent(component)) {
      case None():
        return const Option.none();
      case Some<RuntimeSourceComponent>(:final value):
        parsedComponents.add(value);
    }
  }

  if (parsedComponents.isEmpty) {
    return const Option.none();
  }

  return Option.of(
    RuntimeSourceManifest(
      runtimeId: runtimeId,
      stackId: stackId,
      components: parsedComponents,
    ),
  );
}

Option<RuntimeSourceComponent> _runtimeStackSourceComponent(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const Option.none();
  }

  final id = value['id'];
  final version = value['version'];
  final archiveUrl = value['archiveUrl'];
  final sha256 = value['sha256'];

  if (id is! String ||
      id.trim().isEmpty ||
      version is! String ||
      version.trim().isEmpty ||
      archiveUrl is! String ||
      archiveUrl.trim().isEmpty ||
      sha256 is! String ||
      !isSha256Hex(sha256)) {
    return const Option.none();
  }

  return Option.of(
    RuntimeSourceComponent(
      id: id,
      version: version,
      archiveUrl: archiveUrl,
      sha256: sha256,
    ),
  );
}
