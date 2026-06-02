part of '../../konyak_cli.dart';

void _mergeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return;
  }

  try {
    componentVersions.addAll(
      _runtimeStackComponentVersions(jsonDecode(manifest.readAsStringSync())),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  }
}

void _writeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  if (componentVersions.isEmpty) {
    return;
  }

  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  manifest.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schemaVersion': runtimeStackSchemaVersion,
      'components': componentVersions,
    }),
  );
}

void _upsertRuntimeStackComponentVersion({
  required Directory runtimeRoot,
  required String componentId,
  required String version,
}) {
  final componentVersions = <String, String>{};
  _mergeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
  componentVersions[componentId] = version;
  _writeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
}
