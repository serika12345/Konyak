import '../../updates/update_check_summary.dart';

String updateCheckLabel(UpdateCheckSummary update, String label) {
  return '$label ${update.latestVersion ?? ''}'.trim();
}

String installedUpdateLabel(UpdateInstallSummary update, String label) {
  return '$label ${update.installedVersion ?? update.currentVersion ?? ''}'
      .trim();
}
