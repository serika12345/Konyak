import 'dart:convert';

import '../updates/update_check_summary.dart';
import 'cli_optional_fields.dart';
import 'konyak_cli_update_result_types.dart';

sealed class UpdateCheckSummaryParseResult {
  const UpdateCheckSummaryParseResult();
}

final class ParsedUpdateCheckSummary extends UpdateCheckSummaryParseResult {
  const ParsedUpdateCheckSummary(this.update);

  final UpdateCheckSummary update;
}

final class InvalidUpdateCheckSummary extends UpdateCheckSummaryParseResult {
  const InvalidUpdateCheckSummary();
}

sealed class UpdateInstallSummaryParseResult {
  const UpdateInstallSummaryParseResult();
}

final class ParsedUpdateInstallSummary extends UpdateInstallSummaryParseResult {
  const ParsedUpdateInstallSummary(this.update);

  final UpdateInstallSummary update;
}

final class InvalidUpdateInstallSummary
    extends UpdateInstallSummaryParseResult {
  const InvalidUpdateInstallSummary();
}

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

  return switch (parseUpdateCheckSummary(update, idKey: idKey)) {
    ParsedUpdateCheckSummary(:final update) => LoadedUpdateCheck(update),
    InvalidUpdateCheckSummary() => const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Invalid update check payload.',
      diagnostic: '',
    ),
  };
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

  return switch (parseUpdateInstallSummary(install)) {
    ParsedUpdateInstallSummary(:final update) => InstalledUpdate(update),
    InvalidUpdateInstallSummary() => const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Invalid update install payload.',
      diagnostic: '',
    ),
  };
}

UpdateCheckSummaryParseResult parseUpdateCheckSummary(
  Map<String, Object?> value, {
  required String idKey,
}) {
  final id = value[idKey];
  final status = value['status'];
  final currentVersion = parseCliOptionalStringField(
    payload: value,
    key: 'currentVersion',
  );
  final latestVersion = parseCliOptionalStringField(
    payload: value,
    key: 'latestVersion',
  );
  final versionUrl = parseCliOptionalStringField(
    payload: value,
    key: 'versionUrl',
  );
  final archiveUrl = parseCliOptionalStringField(
    payload: value,
    key: 'archiveUrl',
  );

  if (id is! String || status is! String) {
    return const InvalidUpdateCheckSummary();
  }

  return switch ((currentVersion, latestVersion, versionUrl, archiveUrl)) {
    (
      ParsedCliOptionalString(value: final currentVersion),
      ParsedCliOptionalString(value: final latestVersion),
      ParsedCliOptionalString(value: final versionUrl),
      ParsedCliOptionalString(value: final archiveUrl),
    ) =>
      ParsedUpdateCheckSummary(
        UpdateCheckSummary(
          id: id,
          status: status,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          versionUrl: versionUrl,
          archiveUrl: archiveUrl,
        ),
      ),
    _ => const InvalidUpdateCheckSummary(),
  };
}

UpdateInstallSummaryParseResult parseUpdateInstallSummary(
  Map<String, Object?> value,
) {
  final id = value['appId'];
  final status = value['status'];
  final currentVersion = parseCliOptionalStringField(
    payload: value,
    key: 'currentVersion',
  );
  final installedVersion = parseCliOptionalStringField(
    payload: value,
    key: 'installedVersion',
  );
  final archiveUrl = parseCliOptionalStringField(
    payload: value,
    key: 'archiveUrl',
  );
  final installPath = parseCliOptionalStringField(
    payload: value,
    key: 'installPath',
  );

  if (id is! String || status is! String) {
    return const InvalidUpdateInstallSummary();
  }

  return switch ((currentVersion, installedVersion, archiveUrl, installPath)) {
    (
      ParsedCliOptionalString(value: final currentVersion),
      ParsedCliOptionalString(value: final installedVersion),
      ParsedCliOptionalString(value: final archiveUrl),
      ParsedCliOptionalString(value: final installPath),
    ) =>
      ParsedUpdateInstallSummary(
        UpdateInstallSummary(
          id: id,
          status: status,
          currentVersion: currentVersion,
          installedVersion: installedVersion,
          archiveUrl: archiveUrl,
          installPath: installPath,
        ),
      ),
    _ => const InvalidUpdateInstallSummary(),
  };
}

CliOptionalStringParseResult parseCliOptionalStringField({
  required Map<String, Object?> payload,
  required String key,
}) {
  if (!payload.containsKey(key)) {
    return const ParsedCliOptionalString(CliOptionalString.absent());
  }

  final value = payload[key];
  if (value is String) {
    return ParsedCliOptionalString(CliOptionalString.present(value));
  }

  if (value == null) {
    return const ParsedCliOptionalString(CliOptionalString.explicitNull());
  }

  return const InvalidCliOptionalString();
}
