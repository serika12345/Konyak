import '../cli/cli_optional_fields.dart';

class UpdateCheckSummary {
  const UpdateCheckSummary({
    required this.id,
    required this.status,
    this.currentVersion = const CliOptionalString.absent(),
    this.latestVersion = const CliOptionalString.absent(),
    this.versionUrl = const CliOptionalString.absent(),
    this.archiveUrl = const CliOptionalString.absent(),
  });

  final String id;
  final String status;
  final CliOptionalString currentVersion;
  final CliOptionalString latestVersion;
  final CliOptionalString versionUrl;
  final CliOptionalString archiveUrl;
}

class UpdateInstallSummary {
  const UpdateInstallSummary({
    required this.id,
    required this.status,
    this.currentVersion = const CliOptionalString.absent(),
    this.installedVersion = const CliOptionalString.absent(),
    this.archiveUrl = const CliOptionalString.absent(),
    this.installPath = const CliOptionalString.absent(),
  });

  final String id;
  final String status;
  final CliOptionalString currentVersion;
  final CliOptionalString installedVersion;
  final CliOptionalString archiveUrl;
  final CliOptionalString installPath;
}
