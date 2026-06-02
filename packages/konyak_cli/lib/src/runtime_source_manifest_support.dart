part of '../konyak_cli.dart';

RuntimeSourceManifest? _runtimeStackSourceManifestFromPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return null;
  }

  final runtimeId = decoded['runtimeId'];
  final stackId = decoded['stackId'];
  final components = decoded['components'];
  if (runtimeId is! String ||
      runtimeId.trim().isEmpty ||
      stackId is! String ||
      stackId.trim().isEmpty ||
      components is! List<dynamic>) {
    return null;
  }

  final parsedComponents = <RuntimeSourceComponent>[];
  for (final component in components) {
    final parsedComponent = _runtimeStackSourceComponent(component);
    if (parsedComponent == null) {
      return null;
    }
    parsedComponents.add(parsedComponent);
  }

  if (parsedComponents.isEmpty) {
    return null;
  }

  return RuntimeSourceManifest(
    runtimeId: runtimeId,
    stackId: stackId,
    components: parsedComponents,
  );
}

RuntimeSourceComponent? _runtimeStackSourceComponent(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
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
      !_isSha256Hex(sha256)) {
    return null;
  }

  return RuntimeSourceComponent(
    id: id,
    version: version,
    archiveUrl: archiveUrl,
    sha256: sha256,
  );
}
