import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_validation_support.dart';
import '../domain/shared/domain_value_objects.dart';
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
  Option<RuntimeVersion> versionFor({
    required RuntimeRootPath runtimeRoot,
    required RuntimeComponentId componentId,
  }) {
    final manifest = File(
      joinPath(runtimeRoot.value, const [runtimeStackManifestFileName]),
    );
    if (!manifest.existsSync()) {
      return const Option.none();
    }

    try {
      return Option.fromNullable(
        runtimeStackComponentVersionFromManifestPayload(
          manifest.readAsStringSync(),
          componentId.value,
        ),
      ).map(RuntimeVersion.new);
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
