import 'dart:convert';

import '../updates/update_check_summary.dart';
import 'konyak_cli_settings_payload_parsers.dart';
import 'konyak_cli_update_result_types.dart';

UpdateCheckLoadResult parseUpdateCheckPayload({
  required String payload,
  required String payloadKey,
  required String idKey,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return UpdateCheckLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Unsupported update check payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return UpdateCheckLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Update check failed.',
      diagnostic: '',
    );
  }

  final update = decoded[payloadKey];
  if (update is! Map<String, Object?>) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Missing update check payload.',
      diagnostic: '',
    );
  }

  final parsedUpdate = parseUpdateCheckSummary(update, idKey: idKey);
  if (parsedUpdate == null) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Invalid update check payload.',
      diagnostic: '',
    );
  }

  return LoadedUpdateCheck(parsedUpdate);
}

UpdateInstallLoadResult parseUpdateInstallPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return UpdateInstallLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Unsupported update install payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return UpdateInstallLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Update install failed.',
      diagnostic: '',
    );
  }

  final install = decoded['appUpdateInstall'];
  if (install is! Map<String, Object?>) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Missing update install payload.',
      diagnostic: '',
    );
  }

  final parsedInstall = parseUpdateInstallSummary(install);
  if (parsedInstall == null) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Invalid update install payload.',
      diagnostic: '',
    );
  }

  return InstalledUpdate(parsedInstall);
}

UpdateCheckSummary? parseUpdateCheckSummary(
  Map<String, Object?> value, {
  required String idKey,
}) {
  final id = value[idKey];
  final status = value['status'];
  final currentVersion = value['currentVersion'];
  final latestVersion = value['latestVersion'];
  final versionUrl = value['versionUrl'];
  final archiveUrl = value['archiveUrl'];

  if (id is! String || status is! String) {
    return null;
  }

  if (!isOptionalString(currentVersion) ||
      !isOptionalString(latestVersion) ||
      !isOptionalString(versionUrl) ||
      !isOptionalString(archiveUrl)) {
    return null;
  }

  return UpdateCheckSummary(
    id: id,
    status: status,
    currentVersion: currentVersion as String?,
    latestVersion: latestVersion as String?,
    versionUrl: versionUrl as String?,
    archiveUrl: archiveUrl as String?,
  );
}

UpdateInstallSummary? parseUpdateInstallSummary(Map<String, Object?> value) {
  final id = value['appId'];
  final status = value['status'];
  final currentVersion = value['currentVersion'];
  final installedVersion = value['installedVersion'];
  final archiveUrl = value['archiveUrl'];
  final installPath = value['installPath'];

  if (id is! String || status is! String) {
    return null;
  }

  if (!isOptionalString(currentVersion) ||
      !isOptionalString(installedVersion) ||
      !isOptionalString(archiveUrl) ||
      !isOptionalString(installPath)) {
    return null;
  }

  return UpdateInstallSummary(
    id: id,
    status: status,
    currentVersion: currentVersion as String?,
    installedVersion: installedVersion as String?,
    archiveUrl: archiveUrl as String?,
    installPath: installPath as String?,
  );
}
