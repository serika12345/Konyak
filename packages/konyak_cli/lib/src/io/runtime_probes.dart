import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_validation_support.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'runtime_archive_install_support.dart';

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
      joinPath(runtimeRoot, const [runtimeStackManifestFileName]),
    );
    if (!manifest.existsSync()) {
      return const Option.none();
    }

    try {
      return Option.fromNullable(
        runtimeStackComponentVersionFromManifestPayload(
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

String? runtimeStackComponentVersionFromManifestPayload(
  String payload,
  String componentId,
) {
  return runtimeStackComponentVersion(jsonDecode(payload), componentId);
}
