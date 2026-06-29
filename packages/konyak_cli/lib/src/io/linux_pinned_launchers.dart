import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/linux/linux_integration.dart';
import '../platform/macos/macos_pinned_launcher_templates.dart';
import '../repository/repository_exceptions.dart';
import '../shared/common_helpers.dart';
import 'linux_file_association_io.dart';
import 'macos_pinned_launcher_manifest_io.dart';
import 'macos_pinned_launcher_manifests.dart';
import 'macos_pinned_launchers.dart';
import 'wine_process_metadata.dart';

const linuxPinnedLauncherManifestFileName = 'konyak-launcher.json';
const linuxPinnedLauncherExecutableName = 'launch';
const linuxPinnedLauncherDesktopEntryPrefix = 'app.konyak.Konyak.pinned.';

class LinuxPinnedProgramLauncherCommand {
  LinuxPinnedProgramLauncherCommand({
    required this.executable,
    required List<String> arguments,
    required this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final Option<String> workingDirectory;
}

void synchronizePinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  synchronizeMacosPinnedProgramLaunchers(
    hostPlatform: hostPlatform,
    environment: environment,
    bottles: bottles,
  );
  synchronizeLinuxPinnedProgramLaunchers(
    hostPlatform: hostPlatform,
    environment: environment,
    bottles: bottles,
  );
}

void synchronizeLinuxPinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  final hostEnvironment = HostEnvironment(environment);
  if (hostPlatform != KonyakHostPlatform.linux) {
    return;
  }

  linuxPinnedProgramLauncherCommand(hostEnvironment).match<void>(() {}, (
    launcherCommand,
  ) {
    try {
      final desiredLaunchers = <PinnedProgramLauncherWrite>[
        for (final bottle in bottles)
          for (final program in bottle.pinnedPrograms)
            PinnedProgramLauncherWrite(
              displayName: linuxPinnedProgramDisplayName(program.name.value),
              iconPath: program.iconPath.map((value) => value.value),
              manifest: PinnedProgramLauncherManifest(
                launcherId: ProgramLauncherId(
                  pinnedProgramLauncherId(
                    bottleId: bottle.id.value,
                    programPath: program.path.value,
                  ),
                ),
                bottleId: bottle.id,
                programPath: program.path,
                programName: program.name,
              ),
            ),
      ];
      final desiredLauncherIds = <String>{
        for (final launcher in desiredLaunchers)
          launcher.manifest.launcherId.value,
      };
      final wroteAny = desiredLaunchers.fold(
        false,
        (changed, launcher) =>
            writeLinuxPinnedProgramLauncher(
              environment: hostEnvironment,
              launcherCommand: launcherCommand,
              displayName: launcher.displayName,
              iconPath: launcher.iconPath.match(() => null, (value) => value),
              manifest: launcher.manifest,
            ) ||
            changed,
      );
      final removedAny = deleteStaleLinuxPinnedProgramLaunchers(
        environment: hostEnvironment,
        desiredLauncherIds: desiredLauncherIds,
      );
      final changed = wroteAny || removedAny;
      if (!changed) {
        return;
      }
      refreshLinuxDesktopIntegrationCaches(
        applicationsPath: linuxApplicationsHome(hostEnvironment),
        iconThemePath: null,
      );
    } on FileSystemException {
      return;
    } on ProcessException {
      return;
    } on BottleRepositoryException {
      return;
    }
  });
}

final class PinnedProgramLauncherWrite {
  const PinnedProgramLauncherWrite({
    required this.displayName,
    required this.iconPath,
    required this.manifest,
  });

  final String displayName;
  final Option<String> iconPath;
  final PinnedProgramLauncherManifest manifest;
}

Option<LinuxPinnedProgramLauncherCommand> linuxPinnedProgramLauncherCommand(
  HostEnvironment environment,
) {
  return environment
      .nonEmptyValue('KONYAK_APPIMAGE_PATH')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE')
            .match(
              () => environment
                  .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_CLI')
                  .match(
                    () => environment
                        .nonEmptyValue('KONYAK_BUNDLE_RESOURCES')
                        .match(() => const Option.none(), (bundleResources) {
                          final cliExecutable = joinPath(
                            bundleResources,
                            const ['konyak-cli'],
                          );
                          if (!File(cliExecutable).existsSync()) {
                            return const Option.none();
                          }

                          return Option.of(
                            LinuxPinnedProgramLauncherCommand(
                              executable: cliExecutable,
                              arguments: const <String>[],
                              workingDirectory: const Option.none(),
                            ),
                          );
                        }),
                    (override) => Option.of(
                      LinuxPinnedProgramLauncherCommand(
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
                    (developmentArguments) => LinuxPinnedProgramLauncherCommand(
                      executable: developmentExecutable,
                      arguments: developmentArguments,
                      workingDirectory: environment.nonEmptyValue(
                        'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY',
                      ),
                    ),
                  ),
            ),
        (appImage) => Option.of(
          LinuxPinnedProgramLauncherCommand(
            executable: appImage,
            arguments: const <String>['--konyak-cli'],
            workingDirectory: const Option.none(),
          ),
        ),
      );
}

bool writeLinuxPinnedProgramLauncher({
  required HostEnvironment environment,
  required LinuxPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
  required PinnedProgramLauncherManifest manifest,
}) {
  final launcherDirectoryPath = linuxPinnedProgramLauncherDirectoryPath(
    environment: environment,
    launcherId: manifest.launcherId.value,
  );
  final executablePath = joinPath(launcherDirectoryPath, const [
    linuxPinnedLauncherExecutableName,
  ]);
  final manifestPath = joinPath(launcherDirectoryPath, const [
    linuxPinnedLauncherManifestFileName,
  ]);
  final desktopEntryPath = linuxPinnedProgramDesktopEntryPath(
    environment: environment,
    launcherId: manifest.launcherId.value,
  );

  Directory(launcherDirectoryPath).createSync(recursive: true);
  final manifestChanged = writeTextFileIfChanged(
    manifestPath,
    jsonEncode(pinnedProgramLauncherManifestJson(manifest)),
  );
  final executableChanged = writeTextFileIfChanged(
    executablePath,
    linuxPinnedProgramLauncherScript(launcherCommand),
  );
  final executableChmodResult = Process.runSync('chmod', <String>[
    '755',
    executablePath,
  ], runInShell: false);
  if (executableChmodResult.exitCode != 0) {
    throw FileSystemException(
      'Unable to mark launcher executable.',
      executablePath,
    );
  }

  final desktopEntryChanged = writeTextFileIfChanged(
    desktopEntryPath,
    linuxPinnedProgramDesktopEntry(
      displayName: displayName,
      executablePath: executablePath,
      iconPath: iconPath,
      programPath: manifest.programPath.value,
    ),
  );

  return manifestChanged || executableChanged || desktopEntryChanged;
}

bool deleteStaleLinuxPinnedProgramLaunchers({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  final desktopEntriesDeleted = deleteStaleLinuxPinnedProgramDesktopEntries(
    environment: environment,
    desiredLauncherIds: desiredLauncherIds,
  );
  final launcherDirectoriesDeleted =
      deleteStaleLinuxPinnedProgramLauncherDirectories(
        environment: environment,
        desiredLauncherIds: desiredLauncherIds,
      );

  return desktopEntriesDeleted || launcherDirectoriesDeleted;
}

bool deleteStaleLinuxPinnedProgramDesktopEntries({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  final applicationsDirectory = Directory(linuxApplicationsHome(environment));
  if (!applicationsDirectory.existsSync()) {
    return false;
  }

  return applicationsDirectory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((entity) => isLinuxPinnedProgramDesktopEntryPath(entity.path))
      .where((entity) {
        final launcherId = linuxPinnedProgramLauncherIdFromDesktopEntryPath(
          entity.path,
        );
        return launcherId != null && !desiredLauncherIds.contains(launcherId);
      })
      .map((entity) {
        entity.deleteSync();
        return true;
      })
      .fold(false, (deletedAny, deleted) => deletedAny || deleted);
}

bool deleteStaleLinuxPinnedProgramLauncherDirectories({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  final launcherRoot = Directory(linuxPinnedProgramLauncherRoot(environment));
  if (!launcherRoot.existsSync()) {
    return false;
  }

  return launcherRoot
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((entity) => !desiredLauncherIds.contains(baseName(entity.path)))
      .where((entity) {
        final manifest = readPinnedProgramLauncherManifest(
          joinPath(entity.path, const [linuxPinnedLauncherManifestFileName]),
        );
        return manifest.match(() => false, (_) => true);
      })
      .map((entity) {
        entity.deleteSync(recursive: true);
        return true;
      })
      .fold(false, (deletedAny, deleted) => deletedAny || deleted);
}

String linuxPinnedProgramLauncherRoot(HostEnvironment environment) {
  return joinPath(linuxDataHome(environment), const [
    'konyak',
    'launchers',
    'linux-pinned',
  ]);
}

String linuxPinnedProgramLauncherDirectoryPath({
  required HostEnvironment environment,
  required String launcherId,
}) {
  return joinPath(linuxPinnedProgramLauncherRoot(environment), [launcherId]);
}

String linuxPinnedProgramDesktopEntryPath({
  required HostEnvironment environment,
  required String launcherId,
}) {
  return joinPath(linuxApplicationsHome(environment), [
    '$linuxPinnedLauncherDesktopEntryPrefix$launcherId.desktop',
  ]);
}

bool isLinuxPinnedProgramDesktopEntryPath(String path) {
  final fileName = baseName(path);
  return fileName.startsWith(linuxPinnedLauncherDesktopEntryPrefix) &&
      fileName.endsWith('.desktop');
}

String? linuxPinnedProgramLauncherIdFromDesktopEntryPath(String path) {
  final fileName = baseName(path);
  if (!fileName.startsWith(linuxPinnedLauncherDesktopEntryPrefix) ||
      !fileName.endsWith('.desktop')) {
    return null;
  }

  return fileName.substring(
    linuxPinnedLauncherDesktopEntryPrefix.length,
    fileName.length - '.desktop'.length,
  );
}

String linuxPinnedProgramDisplayName(String name) {
  final normalized = name.trim();
  return normalized.isEmpty ? 'Konyak Program' : normalized;
}

String linuxPinnedProgramDesktopEntry({
  required String displayName,
  required String executablePath,
  required String? iconPath,
  required String programPath,
}) {
  final iconValue = iconPath == null || iconPath.trim().isEmpty
      ? 'app.konyak.Konyak'
      : linuxDesktopEntryText(iconPath);
  return <String>[
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=${linuxDesktopEntryText(displayName)}',
    'Exec=${desktopEntryQuote(executablePath)}',
    'Icon=$iconValue',
    'StartupWMClass=${linuxDesktopEntryText(normalizedExecutableName(programPath))}',
    'Terminal=false',
    'Categories=Utility;',
    'StartupNotify=true',
    '',
  ].join('\n');
}

String linuxPinnedProgramLauncherScript(
  LinuxPinnedProgramLauncherCommand command,
) {
  final changeDirectory = command.workingDirectory.match(
    () => '',
    (workingDirectory) => 'cd ${posixShellSingleQuote(workingDirectory)}\n',
  );
  final launcherCommand = <String>[
    posixShellSingleQuote(command.executable),
    ...command.arguments.map(posixShellSingleQuote),
    'launch-pinned-program',
    '--manifest',
    r'"$manifest"',
    '--json',
  ].join(' ');

  return '''
#!/bin/sh
set -eu
manifest_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd -P)
manifest="\$manifest_dir/$linuxPinnedLauncherManifestFileName"
${changeDirectory}exec $launcherCommand
''';
}

String linuxDesktopEntryText(String value) {
  return value.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ').trim();
}

bool writeTextFileIfChanged(String path, String contents) {
  final file = File(path);
  if (file.existsSync() && file.readAsStringSync() == contents) {
    return false;
  }

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  return true;
}
