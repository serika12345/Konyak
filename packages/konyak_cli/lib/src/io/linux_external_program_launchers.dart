part of '../../konyak_cli.dart';

void _recordExternalProgramRun({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = _externalProgramRunPath(
    bottle: bottle,
    request: request,
  );
  normalizedProgramPath.match(
    () {},
    (programPath) =>
        _recordExternalProgramLaunch(bottle: bottle, programPath: programPath),
  );
}

void _synchronizeLinuxDesktopLauncherForProgramRun({
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

  final normalizedProgramPath = _externalProgramRunPath(
    bottle: bottle,
    request: request,
  );
  normalizedProgramPath.match(() {}, (programPath) {
    try {
      _recordExternalProgramLaunch(bottle: bottle, programPath: programPath);
      final launcherPath = _linuxExternalProgramLauncherPath(
        environment: hostEnvironment,
        bottleId: bottle.id.value,
        programPath: programPath,
      );
      final metadata = programMetadataExtractor.extract(
        bottle: bottle,
        programPath: _metadataProgramPath(
          bottle: bottle,
          programPath: programPath,
        ),
      );
      final launcherContents = _linuxExternalProgramDesktopEntry(
        bottle: bottle,
        request: request,
        launcherName: _linuxExternalProgramLauncherName(
          programPath: programPath,
          metadata: metadata,
        ),
        iconPath: metadata.match(
          () => null,
          (programMetadata) => programMetadata.iconPath.toNullable()?.value,
        ),
      );
      _writeLinuxExternalProgramDesktopLauncher(
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

String _linuxExternalProgramLauncherName({
  required String programPath,
  required Option<ProgramMetadataRecord> metadata,
}) {
  return metadata.match(() => _baseName(programPath), (programMetadata) {
    final productName = _presentMetadataValue(programMetadata.productName);
    if (productName != null) {
      return productName;
    }

    final fileDescription = _presentMetadataValue(
      programMetadata.fileDescription,
    );
    if (fileDescription != null) {
      return fileDescription;
    }

    return _baseName(programPath);
  });
}

String? _presentMetadataValue(Option<StringDomainValueObject> value) {
  return value.match(() => null, (item) => item.value.trim());
}

String _linuxExternalProgramLauncherPath({
  required HostEnvironment environment,
  required String bottleId,
  required String programPath,
}) {
  final digest = sha1.convert(utf8.encode('$bottleId:$programPath')).toString();
  return _joinPath(_linuxApplicationsHome(environment), <String>[
    'konyak',
    'konyak-$bottleId-${digest.substring(0, 12)}.desktop',
  ]);
}

String _linuxExternalProgramDesktopEntry({
  required BottleRecord bottle,
  required ProgramRunRequest request,
  required String launcherName,
  required String? iconPath,
}) {
  final lines = <String>[
    '[Desktop Entry]',
    'Type=Application',
    'Name=$launcherName',
    'Exec=${_linuxDesktopEntryExec(request: request, bottle: bottle)}',
    'NoDisplay=true',
    'StartupNotify=true',
    'StartupWMClass=${_normalizedExecutableName(request.programPath.value)}',
    'Path=${_parentDirectory(request.programPath.value).match(() => bottle.path.value, (value) => value)}',
  ];

  if (iconPath != null && iconPath.trim().isNotEmpty) {
    lines.add('Icon=$iconPath');
  }

  return '${lines.join('\n')}\n';
}

String _linuxDesktopEntryExec({
  required ProgramRunRequest request,
  required BottleRecord bottle,
}) {
  final arguments = request.arguments.map(_desktopEntryQuote).join(' ');
  final buffer = StringBuffer(
    'env "WINEPREFIX=${bottle.path.value}" ${_desktopEntryQuote(request.executable.value)}',
  );
  if (arguments.isNotEmpty) {
    buffer.write(' ');
    buffer.write(arguments);
  }

  return buffer.toString();
}
