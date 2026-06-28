import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/linux/linux_integration.dart';
import '../repository/repository_exceptions.dart';
import '../shared/common_helpers.dart';
import 'external_program_launch_records.dart';
import 'linux_external_program_launcher_io.dart';
import 'program_metadata_io.dart';
import 'program_shortcut_metadata_io.dart';
import 'wine_process_metadata.dart';

void recordExternalProgramRun({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = externalProgramRunPath(
    bottle: bottle,
    request: request,
  );
  normalizedProgramPath.match(
    () {},
    (programPath) =>
        recordExternalProgramLaunch(bottle: bottle, programPath: programPath),
  );
}

void synchronizeLinuxDesktopLauncherForProgramRun({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required BottleRecord bottle,
  required ProgramRunRequest request,
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  LinuxExternalProgramLauncherDiagnosticSink? diagnosticSink,
}) {
  if (hostPlatform != KonyakHostPlatform.linux ||
      request.runnerKind.value != 'wine') {
    return;
  }
  final hostEnvironment = HostEnvironment(environment);

  final normalizedProgramPath = externalProgramRunPath(
    bottle: bottle,
    request: request,
  );
  normalizedProgramPath.match(() {}, (programPath) {
    try {
      recordExternalProgramLaunch(bottle: bottle, programPath: programPath);
      final launcherPath = linuxExternalProgramLauncherPath(
        environment: hostEnvironment,
        bottleId: bottle.id.value,
        programPath: programPath,
      );
      final metadata = programMetadataExtractor.extract(
        bottle: bottle,
        programPath: metadataProgramPath(
          bottle: bottle,
          programPath: programPath,
        ),
      );
      final launcherContents = linuxExternalProgramDesktopEntry(
        bottle: bottle,
        request: request,
        launcherName: linuxExternalProgramLauncherName(
          programPath: programPath,
          metadata: metadata,
        ),
        iconPath: metadata
            .flatMap((programMetadata) => programMetadata.iconPath)
            .map((iconPath) => iconPath.value)
            .toNullable(),
      );
      writeLinuxExternalProgramDesktopLauncher(
        launcherPath: launcherPath,
        launcherContents: launcherContents,
      );
    } on FileSystemException catch (error) {
      diagnosticSink?.emit(
        LinuxExternalProgramLauncherSyncFailure.fileSystem(
          bottleId: bottle.id.value,
          programPath: programPath,
          message: error.message,
        ),
      );
      return;
    } on BottleRepositoryException catch (error) {
      diagnosticSink?.emit(
        LinuxExternalProgramLauncherSyncFailure.bottleRepository(
          bottleId: bottle.id.value,
          programPath: programPath,
          message: error.message,
        ),
      );
      return;
    } on StateError catch (error) {
      diagnosticSink?.emit(
        LinuxExternalProgramLauncherSyncFailure.invalidState(
          bottleId: bottle.id.value,
          programPath: programPath,
          message: error.message,
        ),
      );
      return;
    }
  });
}

abstract interface class LinuxExternalProgramLauncherDiagnosticSink {
  void emit(LinuxExternalProgramLauncherSyncFailure failure);
}

enum LinuxExternalProgramLauncherSyncFailureKind {
  fileSystem,
  bottleRepository,
  invalidState,
}

final class LinuxExternalProgramLauncherSyncFailure {
  const LinuxExternalProgramLauncherSyncFailure._({
    required this.kind,
    required this.bottleId,
    required this.programPath,
    required this.message,
  });

  factory LinuxExternalProgramLauncherSyncFailure.fileSystem({
    required String bottleId,
    required String programPath,
    required String message,
  }) {
    return LinuxExternalProgramLauncherSyncFailure._(
      kind: LinuxExternalProgramLauncherSyncFailureKind.fileSystem,
      bottleId: bottleId,
      programPath: programPath,
      message: message,
    );
  }

  factory LinuxExternalProgramLauncherSyncFailure.bottleRepository({
    required String bottleId,
    required String programPath,
    required String message,
  }) {
    return LinuxExternalProgramLauncherSyncFailure._(
      kind: LinuxExternalProgramLauncherSyncFailureKind.bottleRepository,
      bottleId: bottleId,
      programPath: programPath,
      message: message,
    );
  }

  factory LinuxExternalProgramLauncherSyncFailure.invalidState({
    required String bottleId,
    required String programPath,
    required String message,
  }) {
    return LinuxExternalProgramLauncherSyncFailure._(
      kind: LinuxExternalProgramLauncherSyncFailureKind.invalidState,
      bottleId: bottleId,
      programPath: programPath,
      message: message,
    );
  }

  final LinuxExternalProgramLauncherSyncFailureKind kind;
  final String bottleId;
  final String programPath;
  final String message;
}

String linuxExternalProgramLauncherName({
  required String programPath,
  required Option<ProgramMetadataRecord> metadata,
}) {
  return metadata.match(() => baseName(programPath), (programMetadata) {
    return presentMetadataValue(programMetadata.productName)
        .alt(() => presentMetadataValue(programMetadata.fileDescription))
        .getOrElse(() => baseName(programPath));
  });
}

Option<String> presentMetadataValue(Option<StringDomainValueObject> value) {
  return value.map((item) => item.value.trim());
}

String linuxExternalProgramLauncherPath({
  required HostEnvironment environment,
  required String bottleId,
  required String programPath,
}) {
  final digest = sha1.convert(utf8.encode('$bottleId:$programPath')).toString();
  return joinPath(linuxApplicationsHome(environment), <String>[
    'konyak',
    'konyak-$bottleId-${digest.substring(0, 12)}.desktop',
  ]);
}

String linuxExternalProgramDesktopEntry({
  required BottleRecord bottle,
  required ProgramRunRequest request,
  required String launcherName,
  required String? iconPath,
}) {
  final lines = <String>[
    '[Desktop Entry]',
    'Type=Application',
    'Name=$launcherName',
    'Exec=${linuxDesktopEntryExec(request: request, bottle: bottle)}',
    'NoDisplay=true',
    'StartupNotify=true',
    'StartupWMClass=${normalizedExecutableName(request.programPath.value)}',
    'Path=${parentDirectory(request.programPath.value).match(() => bottle.path.value, (value) => value)}',
  ];

  if (iconPath != null && iconPath.trim().isNotEmpty) {
    lines.add('Icon=$iconPath');
  }

  return '${lines.join('\n')}\n';
}

String linuxDesktopEntryExec({
  required ProgramRunRequest request,
  required BottleRecord bottle,
}) {
  final arguments = request.arguments.map(desktopEntryQuote).join(' ');
  final buffer = StringBuffer(
    'env "WINEPREFIX=${bottle.path.value}" ${desktopEntryQuote(request.executable.value)}',
  );
  if (arguments.isNotEmpty) {
    buffer.write(' ');
    buffer.write(arguments);
  }

  return buffer.toString();
}
