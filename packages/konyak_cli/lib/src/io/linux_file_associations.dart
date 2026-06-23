part of '../../konyak_cli.dart';

const _linuxKonyakDesktopEntryId = 'app.konyak.Konyak.desktop';
const _linuxKonyakIconFileName = 'app.konyak.Konyak.png';
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
    required this.iconPath,
    required this.mimeAppsPath,
  });

  final String desktopEntryPath;
  final String? iconPath;
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
  final hostEnvironment = HostEnvironment(environment);
  if (hostPlatform != KonyakHostPlatform.linux &&
      hostEnvironment['KONYAK_FORCE_LINUX_FILE_ASSOCIATIONS'] != '1') {
    return const _LinuxFileAssociationInstallFailed(
      'Linux file associations are supported on Linux only.',
    );
  }

  final appExecutable = _linuxFileAssociationAppExecutable(hostEnvironment);
  if (appExecutable == null) {
    return const _LinuxFileAssociationInstallFailed(
      'Unable to resolve the Konyak application executable.',
    );
  }

  try {
    final desktopEntryPath = _joinPath(
      _linuxApplicationsHome(hostEnvironment),
      [_linuxKonyakDesktopEntryId],
    );
    final iconSourcePath = _linuxFileAssociationIconSource(hostEnvironment);
    final iconPath = iconSourcePath == null
        ? null
        : _linuxKonyakIconPath(hostEnvironment);
    final mimeAppsPath = _linuxMimeAppsPath(hostEnvironment);
    _writeLinuxFileAssociationFiles(
      desktopEntryPath: desktopEntryPath,
      desktopEntry: _linuxKonyakDesktopEntry(appExecutable: appExecutable),
      iconSourcePath: iconSourcePath,
      iconTargetPath: iconPath,
      iconThemePath: iconPath == null
          ? null
          : _linuxKonyakHicolorIconThemePath(hostEnvironment),
      mimeAppsPath: mimeAppsPath,
    );

    return _LinuxFileAssociationsInstalled(
      desktopEntryPath: desktopEntryPath,
      iconPath: iconPath,
      mimeAppsPath: mimeAppsPath,
    );
  } on FileSystemException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  } on BottleRepositoryException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  }
}

String? _linuxFileAssociationAppExecutable(HostEnvironment environment) {
  for (final key in const <String>[
    'KONYAK_APPIMAGE_PATH',
    'KONYAK_APP_EXECUTABLE',
  ]) {
    final value = environment.nonEmptyValue(key);
    if (value != null) {
      return value;
    }
  }

  return null;
}

String? _linuxFileAssociationIconSource(HostEnvironment environment) {
  final explicitIconPath = environment.nonEmptyValue('KONYAK_APP_ICON_PATH');
  if (explicitIconPath != null) {
    if (!File(explicitIconPath).existsSync()) {
      throw BottleRepositoryException(
        'Konyak application icon was not found: $explicitIconPath',
      );
    }
    return explicitIconPath;
  }

  final appExecutable = environment.nonEmptyValue('KONYAK_APP_EXECUTABLE');
  if (appExecutable == null) {
    return null;
  }

  final executableDirectory = _dirname(appExecutable);
  final candidates = <String>[
    _joinPath(executableDirectory, const ['data', 'app_icon_256.png']),
    _joinPath(executableDirectory, const [
      'share',
      'icons',
      'hicolor',
      '256x256',
      'apps',
      _linuxKonyakIconFileName,
    ]),
    _joinPath(_dirname(executableDirectory), const [_linuxKonyakIconFileName]),
  ];

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  return null;
}

String _linuxKonyakIconPath(HostEnvironment environment) {
  return _joinPath(_linuxKonyakIconAppsPath(environment), const [
    _linuxKonyakIconFileName,
  ]);
}

String _linuxKonyakIconAppsPath(HostEnvironment environment) {
  return _joinPath(_linuxKonyakHicolorIconThemePath(environment), const [
    '256x256',
    'apps',
  ]);
}

String _linuxKonyakHicolorIconThemePath(HostEnvironment environment) {
  return _joinPath(_linuxDataHome(environment), const ['icons', 'hicolor']);
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

String _linuxMimeAppsPath(HostEnvironment environment) {
  final xdgConfigHome = environment.nonEmptyValue('XDG_CONFIG_HOME');
  if (xdgConfigHome != null) {
    return _joinPath(xdgConfigHome, const ['mimeapps.list']);
  }

  final home = environment.nonEmptyValue('HOME');
  if (home != null) {
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
