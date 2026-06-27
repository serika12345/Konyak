part of '../../konyak_cli.dart';

CliResult? _handleHostIntegrationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonLinuxFileAssociationInstallCommand(arguments)) {
    return null;
  }

  final result = _installLinuxFileAssociations(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment.toMap(),
  );
  return switch (result) {
    _LinuxFileAssociationsInstalled(
      :final desktopEntryPath,
      :final iconPath,
      :final mimeAppsPath,
    ) =>
      _jsonSuccess(<String, Object?>{
        'linuxFileAssociations': _linuxFileAssociationsPayload(
          desktopEntryPath: desktopEntryPath,
          iconPath: iconPath,
          mimeAppsPath: mimeAppsPath,
        ),
      }),
    _LinuxFileAssociationInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxFileAssociationInstallFailed',
      message: message,
    ),
  };
}

Map<String, Object?> _linuxFileAssociationsPayload({
  required String desktopEntryPath,
  required Option<String> iconPath,
  required String mimeAppsPath,
}) {
  return <String, Object?>{
    'desktopEntryPath': desktopEntryPath,
    'mimeAppsPath': mimeAppsPath,
    'mimeTypes': _linuxExecutableMimeTypes,
    ...iconPath.match(
      () => const <String, Object?>{},
      (path) => <String, Object?>{'iconPath': path},
    ),
  };
}
