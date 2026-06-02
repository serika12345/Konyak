part of '../konyak_cli.dart';

abstract interface class FileStatusProbe {
  bool exists(String path);
}

abstract interface class RuntimeStackVersionProbe {
  String? versionFor({
    required String runtimeRoot,
    required String componentId,
  });
}

class DartIoFileStatusProbe implements FileStatusProbe {
  const DartIoFileStatusProbe();

  @override
  bool exists(String path) {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }
}

class DartIoRuntimeStackVersionProbe implements RuntimeStackVersionProbe {
  const DartIoRuntimeStackVersionProbe();

  @override
  String? versionFor({
    required String runtimeRoot,
    required String componentId,
  }) {
    final manifest = File(
      _joinPath(runtimeRoot, const [runtimeStackManifestFileName]),
    );
    if (!manifest.existsSync()) {
      return null;
    }

    try {
      final decoded = jsonDecode(manifest.readAsStringSync());
      return _runtimeStackComponentVersion(decoded, componentId);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
