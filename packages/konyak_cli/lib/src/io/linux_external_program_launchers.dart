part of '../../konyak_cli.dart';

void _recordExternalProgramRun({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = _externalProgramRunPath(
    bottle: bottle,
    request: request,
  );
  if (normalizedProgramPath == null) {
    return;
  }

  _recordExternalProgramLaunch(
    bottle: bottle,
    programPath: normalizedProgramPath,
  );
}

void _synchronizeLinuxDesktopLauncherForProgramRun({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required BottleRecord bottle,
  required ProgramRunRequest request,
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
}) {
  if (hostPlatform != KonyakHostPlatform.linux ||
      request.runnerKind != 'wine') {
    return;
  }

  final normalizedProgramPath = _externalProgramRunPath(
    bottle: bottle,
    request: request,
  );
  if (normalizedProgramPath == null) {
    return;
  }

  try {
    _recordExternalProgramLaunch(
      bottle: bottle,
      programPath: normalizedProgramPath,
    );
    final launcherPath = _linuxExternalProgramLauncherPath(
      environment: environment,
      bottleId: bottle.id,
      programPath: normalizedProgramPath,
    );
    final metadata = programMetadataExtractor.extract(
      bottle: bottle,
      programPath: _metadataProgramPath(
        bottle: bottle,
        programPath: normalizedProgramPath,
      ),
    );
    final launcherContents = _linuxExternalProgramDesktopEntry(
      bottle: bottle,
      request: request,
      launcherName: _linuxExternalProgramLauncherName(
        programPath: normalizedProgramPath,
        metadata: metadata,
      ),
      iconPath: metadata?.iconPath,
    );
    _writeLinuxExternalProgramDesktopLauncher(
      launcherPath: launcherPath,
      launcherContents: launcherContents,
    );
  } on FileSystemException {
    return;
  } on BottleRepositoryException {
    return;
  } on StateError {
    return;
  }
}

String _linuxExternalProgramLauncherName({
  required String programPath,
  required ProgramMetadataRecord? metadata,
}) {
  if (metadata?.productName?.trim().isNotEmpty == true) {
    return metadata!.productName!.trim();
  }
  if (metadata?.fileDescription?.trim().isNotEmpty == true) {
    return metadata!.fileDescription!.trim();
  }

  return _baseName(programPath);
}

String _linuxExternalProgramLauncherPath({
  required Map<String, String> environment,
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
    'StartupWMClass=${_normalizedExecutableName(request.programPath)}',
    'Path=${_parentDirectory(request.programPath) ?? bottle.path}',
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
    'env "WINEPREFIX=${bottle.path}" ${request.executable}',
  );
  if (arguments.isNotEmpty) {
    buffer.write(' ');
    buffer.write(arguments);
  }

  return buffer.toString();
}
