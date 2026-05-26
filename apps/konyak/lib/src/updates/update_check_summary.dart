class UpdateCheckSummary {
  const UpdateCheckSummary({
    required this.id,
    required this.status,
    this.currentVersion,
    this.latestVersion,
    this.versionUrl,
    this.archiveUrl,
  });

  final String id;
  final String status;
  final String? currentVersion;
  final String? latestVersion;
  final String? versionUrl;
  final String? archiveUrl;
}

class UpdateInstallSummary {
  const UpdateInstallSummary({
    required this.id,
    required this.status,
    this.currentVersion,
    this.installedVersion,
    this.archiveUrl,
    this.installPath,
  });

  final String id;
  final String status;
  final String? currentVersion;
  final String? installedVersion;
  final String? archiveUrl;
  final String? installPath;
}
