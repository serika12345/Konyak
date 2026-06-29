import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../domain/shared/domain_value_objects.dart';
import '../repository/repository_exceptions.dart';
import '../shared/common_helpers.dart';

String programSettingsJsonPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  return joinPath(bottle.path.value, [
    'program-settings',
    programSettingsFileName(programPath, extension: 'json'),
  ]);
}

String programSettingsFileName(
  String programPath, {
  required String extension,
}) {
  final normalized = programPath.trim().replaceAll(RegExp(r'[\\/]+$'), '');
  final lastSlash = normalized.lastIndexOf('/');
  final lastBackslash = normalized.lastIndexOf(r'\');
  final separator = max(lastSlash, lastBackslash);
  final rawName = separator == -1
      ? normalized
      : normalized.substring(separator + 1);
  final safeName = rawName.replaceAll(RegExp(r'[/\\:]'), '_').trim();
  if (safeName.isEmpty) {
    throw const BottleRepositoryException(
      'Program path cannot form a settings file name.',
    );
  }

  return '$safeName.$extension';
}

String programSettingsKey({
  required String bottleId,
  required String programPath,
}) {
  return '$bottleId:${normalizeFilesystemPath(programPath)}';
}

String appSettingsJsonPath(String configHome) {
  return joinPath(configHome, const ['settings.json']);
}

BottleRecord bottleFromCreateRequest(
  BottleCreateRequest request,
  String dataHome, {
  Option<String> bottleDirectory = const Option.none(),
}) {
  final id = bottleIdFromName(request.name.value);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory.match(
    () => joinPath(dataHome, const ['bottles']),
    (value) => value,
  );
  return BottleRecord(
    id: id,
    name: request.name.value,
    path: joinPath(directory, [id]),
    windowsVersion: request.windowsVersion.value,
  );
}

BottleRecord renamedMemoryBottle({
  required BottleRecord bottle,
  required String name,
  required String dataHome,
}) {
  return renamedFileBottle(bottle: bottle, name: name, dataHome: dataHome);
}

BottleRecord renamedFileBottle({
  required BottleRecord bottle,
  required String name,
  required String dataHome,
  Option<String> bottleDirectory = const Option.none(),
}) {
  final id = bottleIdFromName(name);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory.match(
    () => joinPath(dataHome, const ['bottles']),
    (value) => value,
  );
  return bottle.copyWith(
    id: BottleId(id),
    name: BottleName(name),
    path: BottlePath(joinPath(directory, [id])),
  );
}

final bottleIdLetterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

String bottleIdFromName(String name) {
  final state = name.trim().toLowerCase().runes.fold(
    (id: '', lastWasSeparator: false),
    (state, rune) {
      final character = String.fromCharCode(rune);
      if (bottleIdLetterOrNumber.hasMatch(character)) {
        return (id: '${state.id}$character', lastWasSeparator: false);
      }

      if (state.id.isNotEmpty && !state.lastWasSeparator) {
        return (id: '${state.id}-', lastWasSeparator: true);
      }

      return state;
    },
  );
  final id = state.id;
  return id.endsWith('-') ? id.substring(0, id.length - 1) : id;
}

String resolveDataHome(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_DATA_HOME')
      .match(
        () => environment
            .nonEmptyValue('XDG_DATA_HOME')
            .match(
              () => environment
                  .nonEmptyValue('HOME')
                  .match(
                    () => throw const BottleRepositoryException(
                      'Unable to resolve Konyak data directory.',
                    ),
                    (home) =>
                        joinPath(home, const ['.local', 'share', 'konyak']),
                  ),
              (xdgDataHome) => joinPath(xdgDataHome, const ['konyak']),
            ),
        (override) => override,
      );
}

String resolveBottleDataHome(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  return environment
      .nonEmptyValue('KONYAK_DATA_HOME')
      .match(
        () => switch (hostPlatform) {
          KonyakHostPlatform.macos => konyakApplicationSupportFolder(
            environment,
          ),
          KonyakHostPlatform.linux => resolveDataHome(environment),
        },
        (override) => override,
      );
}

String resolveConfigHome(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  return environment
      .nonEmptyValue('KONYAK_CONFIG_HOME')
      .match(
        () => switch (hostPlatform) {
          KonyakHostPlatform.macos =>
            environment
                .nonEmptyValue('HOME')
                .match(
                  () => throw const AppSettingsRepositoryException(
                    'Unable to resolve Konyak config directory.',
                  ),
                  (home) => joinPath(home, const [
                    'Library',
                    'Application Support',
                    'Konyak',
                  ]),
                ),
          KonyakHostPlatform.linux =>
            environment
                .nonEmptyValue('XDG_CONFIG_HOME')
                .match(
                  () => environment
                      .nonEmptyValue('HOME')
                      .match(
                        () => throw const AppSettingsRepositoryException(
                          'Unable to resolve Konyak config directory.',
                        ),
                        (home) => joinPath(home, const ['.config', 'konyak']),
                      ),
                  (xdgConfigHome) => joinPath(xdgConfigHome, const ['konyak']),
                ),
        },
        (override) => override,
      );
}

String defaultBottlePath(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  return environment
      .nonEmptyValue('KONYAK_DEFAULT_BOTTLE_PATH')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_DATA_HOME')
            .match(
              () => switch (hostPlatform) {
                KonyakHostPlatform.macos => joinPath(
                  resolveBottleDataHome(
                    environment,
                    hostPlatform: hostPlatform,
                  ),
                  const ['Bottles'],
                ),
                KonyakHostPlatform.linux => joinPath(
                  resolveDataHome(environment),
                  const ['bottles'],
                ),
              },
              (dataHome) => joinPath(dataHome, const ['bottles']),
            ),
        (override) => override,
      );
}

bool hasBottleAtPath(
  Iterable<BottleRecord> bottles,
  String path, {
  required String exceptId,
}) {
  final normalizedPath = normalizeFilesystemPath(path);
  return bottles.any(
    (bottle) =>
        bottle.id.value != exceptId &&
        normalizeFilesystemPath(bottle.path.value) == normalizedPath,
  );
}
