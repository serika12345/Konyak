import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../platform/macos/macos_pinned_launcher_templates.dart';
import '../shared/common_helpers.dart';
import 'app_update_paths.dart';
import 'macos_pinned_launcher_bundle_io.dart';
import 'macos_pinned_launcher_cleanup.dart';
import 'macos_pinned_launcher_manifests.dart';

const macosPinnedLauncherManifestFileName = 'konyak-launcher.json';
const macosPinnedLauncherExecutableName = 'konyak-launcher';

class MacosPinnedProgramLauncherCommand {
  MacosPinnedProgramLauncherCommand({
    required this.executable,
    required List<String> arguments,
    required this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final Option<String> workingDirectory;
}

void synchronizeMacosPinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  final hostEnvironment = HostEnvironment(environment);
  if (hostPlatform != KonyakHostPlatform.macos) {
    return;
  }

  macosPinnedProgramLaunchersHome(hostEnvironment).match<void>(() {}, (
    launcherHome,
  ) {
    macosPinnedProgramLauncherCommand(hostEnvironment).match<void>(() {}, (
      launcherCommand,
    ) {
      try {
        final desiredLauncherIds = <String>{};
        final desiredLauncherPaths = <String, String>{};
        final usedDisplayNames = <String>{};
        final usedBundleNames = unmanagedMacosLauncherBundleNames(launcherHome);
        for (final bottle in bottles) {
          for (final program in bottle.pinnedPrograms) {
            final launcherId = pinnedProgramLauncherId(
              bottleId: bottle.id.value,
              programPath: program.path.value,
            );
            final displayName = uniqueMacosLauncherDisplayName(
              program.name.value,
              usedDisplayNames: usedDisplayNames,
              usedBundleNames: usedBundleNames,
            );
            final bundlePath = joinPath(launcherHome, [
              macosLauncherBundleName(displayName),
            ]);
            desiredLauncherIds.add(launcherId);
            desiredLauncherPaths[launcherId] = normalizeFilesystemPath(
              bundlePath,
            );
            writeMacosPinnedProgramLauncher(
              bundlePath: bundlePath,
              launcherCommand: launcherCommand,
              displayName: displayName,
              iconPath: program.iconPath
                  .map((value) => value.value)
                  .toNullable(),
              manifest: PinnedProgramLauncherManifest(
                launcherId: launcherId,
                bottleId: bottle.id.value,
                programPath: program.path.value,
                programName: program.name.value,
              ),
            );
          }
        }

        deleteStaleMacosPinnedProgramLaunchers(
          launcherHome: launcherHome,
          desiredLauncherIds: desiredLauncherIds,
          desiredLauncherPaths: desiredLauncherPaths,
        );
      } on FileSystemException {
        return;
      } on ProcessException {
        return;
      }
    });
  });
}

Option<String> macosPinnedProgramLaunchersHome(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_MACOS_PINNED_LAUNCHERS_HOME')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .map((home) => joinPath(home, const ['Applications', 'Konyak'])),
        Option.of,
      );
}

Option<MacosPinnedProgramLauncherCommand> macosPinnedProgramLauncherCommand(
  HostEnvironment environment,
) {
  return environment
      .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_CLI')
            .match(
              () => macosAppBundlePath(environment).flatMap((bundlePath) {
                final cliExecutable = joinPath(bundlePath, const [
                  'Contents',
                  'Resources',
                  'konyak-cli',
                ]);
                if (!File(cliExecutable).existsSync()) {
                  return const Option.none();
                }

                return Option.of(
                  MacosPinnedProgramLauncherCommand(
                    executable: cliExecutable,
                    arguments: const <String>[],
                    workingDirectory: const Option.none(),
                  ),
                );
              }),
              (override) => Option.of(
                MacosPinnedProgramLauncherCommand(
                  executable: override,
                  arguments: const <String>[],
                  workingDirectory: const Option.none(),
                ),
              ),
            ),
        (developmentExecutable) =>
            pinnedProgramLauncherArguments(
              environment['KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON'],
            ).map(
              (developmentArguments) => MacosPinnedProgramLauncherCommand(
                executable: developmentExecutable,
                arguments: developmentArguments,
                workingDirectory: environment.nonEmptyValue(
                  'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY',
                ),
              ),
            ),
      );
}

Option<List<String>> pinnedProgramLauncherArguments(Option<String> value) {
  return value.match(() => Option<List<String>>.of(const <String>[]), (raw) {
    if (raw.trim().isEmpty) {
      return Option<List<String>>.of(const <String>[]);
    }

    return decodePinnedProgramLauncherArgumentsJson(raw).match(
      () => const Option.none(),
      (decoded) => switch (decoded) {
        final List<Object?> values => (() {
          final arguments = values.whereType<String>().toList(growable: false);
          if (arguments.length != values.length) {
            return const Option<List<String>>.none();
          }

          return Option<List<String>>.of(List<String>.unmodifiable(arguments));
        })(),
        _ => const Option.none(),
      },
    );
  });
}

Option<Object?> decodePinnedProgramLauncherArgumentsJson(String raw) {
  try {
    return Option<Object?>.of(jsonDecode(raw));
  } on FormatException {
    return const Option.none();
  }
}

String pinnedProgramLauncherId({
  required String bottleId,
  required String programPath,
}) {
  return sha256
      .convert(
        utf8.encode('$bottleId\u0000${normalizeFilesystemPath(programPath)}'),
      )
      .toString()
      .substring(0, 16);
}

MacosPinnedProgramLauncherBundlePlan macosPinnedProgramLauncherBundlePlan({
  required String bundlePath,
  required MacosPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconFileName,
  required PinnedProgramLauncherManifest manifest,
}) {
  final contentsPath = joinPath(bundlePath, const ['Contents']);
  final macosPath = joinPath(contentsPath, const ['MacOS']);
  final resourcesPath = joinPath(contentsPath, const ['Resources']);
  final executablePath = joinPath(macosPath, const [
    macosPinnedLauncherExecutableName,
  ]);
  final manifestPath = joinPath(resourcesPath, const [
    macosPinnedLauncherManifestFileName,
  ]);

  return MacosPinnedProgramLauncherBundlePlan(
    infoPlistPath: joinPath(contentsPath, const ['Info.plist']),
    manifestPath: manifestPath,
    executablePath: executablePath,
    infoPlist: macosPinnedProgramInfoPlist(
      manifest: manifest,
      displayName: displayName,
      iconFileName: iconFileName,
    ),
    manifestJson: jsonEncode(pinnedProgramLauncherManifestJson(manifest)),
    launcherScript: macosPinnedProgramLauncherScript(launcherCommand),
  );
}
