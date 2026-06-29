import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../platform/linux/linux_integration.dart';
import '../platform/platform_terminal_commands.dart';
import '../repository/repository_exceptions.dart';
import '../shared/common_helpers.dart';
import 'linux_file_association_io.dart';

const linuxKonyakDesktopEntryId = 'app.konyak.Konyak.desktop';
const linuxKonyakIconFileName = 'app.konyak.Konyak.png';
const linuxExecutableMimeTypes = <String>[
  'application/x-ms-dos-executable',
  'application/x-msdownload',
  'application/vnd.microsoft.portable-executable',
  'application/x-msi',
  'application/x-ms-installer',
  'application/x-ms-shortcut',
  'application/x-msdos-program',
  'text/x-msdos-batch',
];

sealed class LinuxFileAssociationInstallResult {
  const LinuxFileAssociationInstallResult();
}

final class LinuxFileAssociationsInstalled
    extends LinuxFileAssociationInstallResult {
  const LinuxFileAssociationsInstalled({
    required this.desktopEntryPath,
    required this.iconPath,
    required this.mimeAppsPath,
  });

  final String desktopEntryPath;
  final Option<String> iconPath;
  final String mimeAppsPath;
}

final class LinuxFileAssociationInstallFailed
    extends LinuxFileAssociationInstallResult {
  const LinuxFileAssociationInstallFailed(this.message);

  final String message;
}

LinuxFileAssociationInstallResult installLinuxFileAssociations({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final forceLinuxFileAssociations =
      hostEnvironment['KONYAK_FORCE_LINUX_FILE_ASSOCIATIONS'].match(
        () => false,
        (value) => value == '1',
      );
  if (hostPlatform != KonyakHostPlatform.linux && !forceLinuxFileAssociations) {
    return const LinuxFileAssociationInstallFailed(
      'Linux file associations are supported on Linux only.',
    );
  }

  return linuxFileAssociationAppExecutable(hostEnvironment).match(
    () => const LinuxFileAssociationInstallFailed(
      'Unable to resolve the Konyak application executable.',
    ),
    (appExecutable) {
      try {
        final desktopEntryPath = joinPath(
          linuxApplicationsHome(hostEnvironment),
          [linuxKonyakDesktopEntryId],
        );
        final iconSourcePath = linuxFileAssociationIconSource(hostEnvironment);
        final iconPath = iconSourcePath.map(
          (_) => linuxKonyakIconPath(hostEnvironment),
        );
        final mimeAppsPath = linuxMimeAppsPath(hostEnvironment);
        writeLinuxFileAssociationFiles(
          desktopEntryPath: desktopEntryPath,
          desktopEntry: linuxKonyakDesktopEntry(appExecutable: appExecutable),
          iconSourcePath: iconSourcePath.match(() => null, (value) => value),
          iconTargetPath: iconPath.match(() => null, (value) => value),
          iconThemePath: iconPath
              .map((_) => linuxKonyakHicolorIconThemePath(hostEnvironment))
              .match(() => null, (value) => value),
          mimeAppsPath: mimeAppsPath,
        );

        return LinuxFileAssociationsInstalled(
          desktopEntryPath: desktopEntryPath,
          iconPath: iconPath,
          mimeAppsPath: mimeAppsPath,
        );
      } on FileSystemException catch (error) {
        return LinuxFileAssociationInstallFailed(error.message);
      } on BottleRepositoryException catch (error) {
        return LinuxFileAssociationInstallFailed(error.message);
      }
    },
  );
}

Option<String> linuxFileAssociationAppExecutable(HostEnvironment environment) {
  for (final key in const <String>[
    'KONYAK_APPIMAGE_PATH',
    'KONYAK_APP_EXECUTABLE',
  ]) {
    final value = environment.nonEmptyValue(key);
    if (value.isSome()) {
      return value;
    }
  }

  return const Option.none();
}

Option<String> linuxFileAssociationIconSource(HostEnvironment environment) {
  return environment.nonEmptyValue('KONYAK_APP_ICON_PATH').match(
    () => environment.nonEmptyValue('KONYAK_APP_EXECUTABLE').flatMap((
      appExecutable,
    ) {
      final executableDirectory = dirname(appExecutable);
      return firstExistingFilePath(<String>[
        joinPath(executableDirectory, const ['data', 'app_icon_256.png']),
        joinPath(executableDirectory, const [
          'share',
          'icons',
          'hicolor',
          '256x256',
          'apps',
          linuxKonyakIconFileName,
        ]),
        joinPath(dirname(executableDirectory), const [linuxKonyakIconFileName]),
      ]);
    }),
    (explicitIconPath) {
      if (!File(explicitIconPath).existsSync()) {
        throw BottleRepositoryException(
          'Konyak application icon was not found: $explicitIconPath',
        );
      }
      return Option.of(explicitIconPath);
    },
  );
}

Option<String> firstExistingFilePath(Iterable<String> candidates) {
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return Option.of(candidate);
    }
  }

  return const Option.none();
}

String linuxKonyakIconPath(HostEnvironment environment) {
  return joinPath(linuxKonyakIconAppsPath(environment), const [
    linuxKonyakIconFileName,
  ]);
}

String linuxKonyakIconAppsPath(HostEnvironment environment) {
  return joinPath(linuxKonyakHicolorIconThemePath(environment), const [
    '256x256',
    'apps',
  ]);
}

String linuxKonyakHicolorIconThemePath(HostEnvironment environment) {
  return joinPath(linuxDataHome(environment), const ['icons', 'hicolor']);
}

String linuxKonyakDesktopEntry({required String appExecutable}) {
  final mimeTypes = '${linuxExecutableMimeTypes.join(';')};';
  return <String>[
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=Konyak',
    'Comment=Run Windows executables with Konyak.',
    'Exec=${desktopEntryQuote(appExecutable)} %f',
    'Icon=app.konyak.Konyak',
    'StartupWMClass=app.konyak.Konyak',
    'Terminal=false',
    'Categories=Utility;',
    'MimeType=$mimeTypes',
    'StartupNotify=true',
    '',
  ].join('\n');
}

String linuxMimeAppsPath(HostEnvironment environment) {
  return environment
      .nonEmptyValue('XDG_CONFIG_HOME')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .match(
              () => throw const BottleRepositoryException(
                'Unable to resolve Linux MIME applications file.',
              ),
              (home) => joinPath(home, const ['.config', 'mimeapps.list']),
            ),
        (xdgConfigHome) => joinPath(xdgConfigHome, const ['mimeapps.list']),
      );
}

String linuxMimeAppsWithKonyakDefaults({required String existing}) {
  final parsedState = existing
      .split('\n')
      .fold(
        LinuxMimeAppsDefaultsState.initial(),
        (state, line) => state.withLine(line),
      );
  final completedState = parsedState.inDefaultApplications
      ? parsedState.withAppendedMimeDefaults()
      : parsedState.withDefaultApplicationsSection();
  final output =
      !completedState.wroteDefaultApplications &&
          completedState.output.first == ''
      ? completedState.output.skip(1)
      : completedState.output;

  return '${output.join('\n').replaceAll(RegExp(r'\n+$'), '')}\n';
}

final class LinuxMimeAppsDefaultsState {
  LinuxMimeAppsDefaultsState({
    required Iterable<String> output,
    required Iterable<String> pendingMimeTypes,
    required this.inDefaultApplications,
    required this.wroteDefaultApplications,
  }) : output = List.unmodifiable(output),
       pendingMimeTypes = Set.unmodifiable(pendingMimeTypes);

  factory LinuxMimeAppsDefaultsState.initial() {
    return LinuxMimeAppsDefaultsState(
      output: const <String>[],
      pendingMimeTypes: linuxExecutableMimeTypes,
      inDefaultApplications: false,
      wroteDefaultApplications: false,
    );
  }

  final List<String> output;
  final Set<String> pendingMimeTypes;
  final bool inDefaultApplications;
  final bool wroteDefaultApplications;

  LinuxMimeAppsDefaultsState withLine(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      return withSectionHeader(line, trimmed: trimmed);
    }

    return inDefaultApplications
        ? withDefaultApplicationLine(line)
        : withNonDefaultApplicationLine(line);
  }

  LinuxMimeAppsDefaultsState withSectionHeader(
    String line, {
    required String trimmed,
  }) {
    final closedSectionState = inDefaultApplications
        ? withAppendedMimeDefaults()
        : this;
    final isDefaultApplications = trimmed == '[Default Applications]';
    return closedSectionState.copyWith(
      output: [...closedSectionState.output, line],
      inDefaultApplications: isDefaultApplications,
      wroteDefaultApplications:
          closedSectionState.wroteDefaultApplications || isDefaultApplications,
    );
  }

  LinuxMimeAppsDefaultsState withDefaultApplicationLine(String line) {
    final separator = line.indexOf('=');
    if (separator <= 0) {
      return withNonDefaultApplicationLine(line);
    }

    final mimeType = line.substring(0, separator).trim();
    return pendingMimeTypes.contains(mimeType)
        ? copyWith(
            output: [...output, '$mimeType=$linuxKonyakDesktopEntryId'],
            pendingMimeTypes: pendingMimeTypes.difference(<String>{mimeType}),
          )
        : withNonDefaultApplicationLine(line);
  }

  LinuxMimeAppsDefaultsState withNonDefaultApplicationLine(String line) {
    return line.isNotEmpty || output.isNotEmpty
        ? copyWith(output: [...output, line])
        : this;
  }

  LinuxMimeAppsDefaultsState withDefaultApplicationsSection() {
    final outputWithSection = <String>[
      ...output,
      if (output.isNotEmpty && output.last.isNotEmpty) '',
      '[Default Applications]',
    ];
    return copyWith(output: outputWithSection).withAppendedMimeDefaults();
  }

  LinuxMimeAppsDefaultsState withAppendedMimeDefaults() {
    return copyWith(
      output: [
        ...output,
        for (final mimeType in linuxExecutableMimeTypes)
          if (pendingMimeTypes.contains(mimeType))
            '$mimeType=$linuxKonyakDesktopEntryId',
      ],
      pendingMimeTypes: const <String>{},
    );
  }

  LinuxMimeAppsDefaultsState copyWith({
    Iterable<String>? output,
    Iterable<String>? pendingMimeTypes,
    bool? inDefaultApplications,
    bool? wroteDefaultApplications,
  }) {
    return LinuxMimeAppsDefaultsState(
      output: output ?? this.output,
      pendingMimeTypes: pendingMimeTypes ?? this.pendingMimeTypes,
      inDefaultApplications:
          inDefaultApplications ?? this.inDefaultApplications,
      wroteDefaultApplications:
          wroteDefaultApplications ?? this.wroteDefaultApplications,
    );
  }
}
