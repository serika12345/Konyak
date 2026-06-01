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

String _desktopEntryQuote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _linuxApplicationsHome(Map<String, String> environment) {
  final xdgDataHome = environment['XDG_DATA_HOME'];
  if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
    return _joinPath(xdgDataHome, const <String>['applications']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const <String>['.local', 'share', 'applications']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux applications directory.',
  );
}

const _linuxKonyakDesktopEntryId = 'app.konyak.Konyak.desktop';
const _linuxExecutableMimeTypes = <String>[
  'application/x-ms-dos-executable',
  'application/x-msdownload',
  'application/vnd.microsoft.portable-executable',
  'application/x-msi',
  'application/x-ms-installer',
  'application/x-ms-shortcut',
  'application/x-msdos-program',
  'text/x-msdos-batch',
];

sealed class _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationInstallResult();
}

final class _LinuxFileAssociationsInstalled
    extends _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationsInstalled({
    required this.desktopEntryPath,
    required this.mimeAppsPath,
  });

  final String desktopEntryPath;
  final String mimeAppsPath;
}

final class _LinuxFileAssociationInstallFailed
    extends _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationInstallFailed(this.message);

  final String message;
}

_LinuxFileAssociationInstallResult _installLinuxFileAssociations({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
}) {
  if (hostPlatform != KonyakHostPlatform.linux &&
      environment['KONYAK_FORCE_LINUX_FILE_ASSOCIATIONS'] != '1') {
    return const _LinuxFileAssociationInstallFailed(
      'Linux file associations are supported on Linux only.',
    );
  }

  final appExecutable = _linuxFileAssociationAppExecutable(environment);
  if (appExecutable == null) {
    return const _LinuxFileAssociationInstallFailed(
      'Unable to resolve the Konyak application executable.',
    );
  }

  try {
    final desktopEntryPath = _joinPath(_linuxApplicationsHome(environment), [
      _linuxKonyakDesktopEntryId,
    ]);
    final mimeAppsPath = _linuxMimeAppsPath(environment);

    final desktopEntry = File(desktopEntryPath);
    desktopEntry.parent.createSync(recursive: true);
    desktopEntry.writeAsStringSync(
      _linuxKonyakDesktopEntry(appExecutable: appExecutable),
    );

    final mimeApps = File(mimeAppsPath);
    mimeApps.parent.createSync(recursive: true);
    mimeApps.writeAsStringSync(
      _linuxMimeAppsWithKonyakDefaults(
        existing: mimeApps.existsSync() ? mimeApps.readAsStringSync() : '',
      ),
    );

    return _LinuxFileAssociationsInstalled(
      desktopEntryPath: desktopEntryPath,
      mimeAppsPath: mimeAppsPath,
    );
  } on FileSystemException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  } on BottleRepositoryException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  }
}

String? _linuxFileAssociationAppExecutable(Map<String, String> environment) {
  for (final key in const <String>[
    'KONYAK_APPIMAGE_PATH',
    'KONYAK_APP_EXECUTABLE',
  ]) {
    final value = environment[key];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}

String _linuxKonyakDesktopEntry({required String appExecutable}) {
  final mimeTypes = '${_linuxExecutableMimeTypes.join(';')};';
  return <String>[
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=Konyak',
    'Comment=Run Windows executables with Konyak.',
    'Exec=${_desktopEntryQuote(appExecutable)} %f',
    'Icon=app.konyak.Konyak',
    'StartupWMClass=app.konyak.Konyak',
    'Terminal=false',
    'Categories=Utility;',
    'MimeType=$mimeTypes',
    'StartupNotify=true',
    '',
  ].join('\n');
}

String _linuxMimeAppsPath(Map<String, String> environment) {
  final xdgConfigHome = environment['XDG_CONFIG_HOME'];
  if (xdgConfigHome != null && xdgConfigHome.trim().isNotEmpty) {
    return _joinPath(xdgConfigHome, const ['mimeapps.list']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['.config', 'mimeapps.list']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux MIME applications file.',
  );
}

String _linuxMimeAppsWithKonyakDefaults({required String existing}) {
  final lines = existing.split('\n');
  final output = <String>[];
  var inDefaultApplications = false;
  var wroteDefaultApplications = false;
  final pendingMimeTypes = <String>{..._linuxExecutableMimeTypes};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      if (inDefaultApplications) {
        _appendLinuxMimeDefaults(output, pendingMimeTypes);
      }
      inDefaultApplications = trimmed == '[Default Applications]';
      wroteDefaultApplications |= inDefaultApplications;
      output.add(line);
      continue;
    }

    if (inDefaultApplications) {
      final separator = line.indexOf('=');
      if (separator > 0) {
        final mimeType = line.substring(0, separator).trim();
        if (pendingMimeTypes.remove(mimeType)) {
          output.add('$mimeType=$_linuxKonyakDesktopEntryId');
          continue;
        }
      }
    }

    if (line.isNotEmpty || output.isNotEmpty) {
      output.add(line);
    }
  }

  if (inDefaultApplications) {
    _appendLinuxMimeDefaults(output, pendingMimeTypes);
  } else {
    if (output.isNotEmpty && output.last.isNotEmpty) {
      output.add('');
    }
    output.add('[Default Applications]');
    _appendLinuxMimeDefaults(output, pendingMimeTypes);
  }

  if (!wroteDefaultApplications && output.first == '') {
    output.removeAt(0);
  }

  return '${output.join('\n').replaceAll(RegExp(r'\n+$'), '')}\n';
}

void _appendLinuxMimeDefaults(
  List<String> output,
  Set<String> pendingMimeTypes,
) {
  for (final mimeType in _linuxExecutableMimeTypes) {
    if (pendingMimeTypes.remove(mimeType)) {
      output.add('$mimeType=$_linuxKonyakDesktopEntryId');
    }
  }
}
