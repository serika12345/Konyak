import 'package:fpdart/fpdart.dart';

import '../io/linux_file_associations.dart';
import 'cli_app_process_parsers.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';

CliResult? handleHostIntegrationCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  if (!isJsonLinuxFileAssociationInstallCommand(arguments)) {
    return null;
  }

  final result = installLinuxFileAssociations(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment.toMap(),
  );
  return switch (result) {
    LinuxFileAssociationsInstalled(
      :final desktopEntryPath,
      :final iconPath,
      :final mimeAppsPath,
    ) =>
      jsonSuccess(<String, Object?>{
        'linuxFileAssociations': linuxFileAssociationsPayload(
          desktopEntryPath: desktopEntryPath,
          iconPath: iconPath,
          mimeAppsPath: mimeAppsPath,
        ),
      }),
    LinuxFileAssociationInstallFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'linuxFileAssociationInstallFailed',
      message: message,
    ),
  };
}

Map<String, Object?> linuxFileAssociationsPayload({
  required String desktopEntryPath,
  required Option<String> iconPath,
  required String mimeAppsPath,
}) {
  return <String, Object?>{
    'desktopEntryPath': desktopEntryPath,
    'mimeAppsPath': mimeAppsPath,
    'mimeTypes': linuxExecutableMimeTypes,
    ...iconPath.match(
      () => const <String, Object?>{},
      (path) => <String, Object?>{'iconPath': path},
    ),
  };
}
