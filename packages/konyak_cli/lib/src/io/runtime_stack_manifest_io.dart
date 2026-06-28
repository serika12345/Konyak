import 'dart:convert';
import 'dart:io';

import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'runtime_archive_install_support.dart';

void mergeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
  bool overwriteExisting = false,
}) {
  final manifest = File(
    joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return;
  }

  try {
    final archivedVersions = runtimeStackComponentVersions(
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

void writeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  if (componentVersions.isEmpty) {
    return;
  }

  final manifest = File(
    joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  manifest.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schemaVersion': runtimeStackSchemaVersion,
      'components': componentVersions,
    }),
  );
}

void upsertRuntimeStackComponentVersion({
  required Directory runtimeRoot,
  required String componentId,
  required String version,
}) {
  final componentVersions = <String, String>{};
  mergeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
  componentVersions[componentId] = version;
  writeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
}
