part of '../konyak_cli.dart';

void _recordExternalProgramRun({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
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

  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
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
    final launcherName = metadata?.productName?.trim().isNotEmpty == true
        ? metadata!.productName!.trim()
        : metadata?.fileDescription?.trim().isNotEmpty == true
        ? metadata!.fileDescription!.trim()
        : _baseName(normalizedProgramPath);
    final launcherDirectory = File(launcherPath).parent
      ..createSync(recursive: true);
    final launcherContents = _linuxExternalProgramDesktopEntry(
      bottle: bottle,
      request: request,
      launcherName: launcherName,
      iconPath: metadata?.iconPath,
    );
    File(_joinPath(launcherDirectory.path, [_baseName(launcherPath)]))
      ..createSync(recursive: true)
      ..writeAsStringSync(launcherContents);
  } on FileSystemException {
    return;
  } on BottleRepositoryException {
    return;
  } on StateError {
    return;
  }
}

void _recordExternalProgramLaunch({
  required BottleRecord bottle,
  required String programPath,
}) {
  try {
    final launchIndexFile = File(
      _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
    );
    final entry = <String, Object?>{
      'programPath': programPath,
      'executableName': _normalizedExecutableName(programPath),
    };

    final existingEntries = <Map<String, Object?>>[];
    if (launchIndexFile.existsSync()) {
      final decoded =
          jsonDecode(launchIndexFile.readAsStringSync())
              as Map<String, Object?>;
      if (decoded['schemaVersion'] == 1) {
        final launches = decoded['launches'];
        if (launches is List<Object?>) {
          for (final launch in launches) {
            if (launch is Map<String, Object?>) {
              final existingProgramPath = launch['programPath'];
              final existingExecutableName = launch['executableName'];
              if (existingProgramPath is! String ||
                  existingExecutableName is! String) {
                continue;
              }

              if (_normalizeFilesystemPath(existingProgramPath) ==
                      _normalizeFilesystemPath(programPath) &&
                  _normalizedExecutableName(existingExecutableName) ==
                      entry['executableName']) {
                continue;
              }

              existingEntries.add(<String, Object?>{
                'programPath': existingProgramPath,
                'executableName': existingExecutableName,
              });
            }
          }
        }
      }
    }

    final launches = <Map<String, Object?>>[...existingEntries.take(31), entry];
    launchIndexFile.parent.createSync(recursive: true);
    launchIndexFile.writeAsStringSync(
      jsonEncode({'schemaVersion': 1, 'launches': launches}),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  } on TypeError {
    return;
  }
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
