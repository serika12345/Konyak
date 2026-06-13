part of '../../konyak_cli.dart';

void _mergeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
  bool overwriteExisting = false,
}) {
  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return;
  }

  try {
    final archivedVersions = _runtimeStackComponentVersions(
      jsonDecode(manifest.readAsStringSync()),
    );
    for (final entry in archivedVersions.entries) {
      if (overwriteExisting) {
        componentVersions[entry.key] = entry.value;
      } else {
        componentVersions.putIfAbsent(entry.key, () => entry.value);
      }
    }
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
