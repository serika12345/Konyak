part of '../../konyak_cli.dart';

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
  Option<String> versionFor({
    required String runtimeRoot,
    required String componentId,
  }) {
    final manifest = File(
      _joinPath(runtimeRoot, const [runtimeStackManifestFileName]),
    );
    if (!manifest.existsSync()) {
      return const Option.none();
    }

    try {
      return Option.fromNullable(
        _runtimeStackComponentVersionFromManifestPayload(
          manifest.readAsStringSync(),
          componentId,
        ),
      );
    } on FileSystemException {
      return const Option.none();
    } on FormatException {
      return const Option.none();
    }
  }
}

String? _runtimeStackComponentVersionFromManifestPayload(
  String payload,
  String componentId,
) {
  return _runtimeStackComponentVersion(jsonDecode(payload), componentId);
}
