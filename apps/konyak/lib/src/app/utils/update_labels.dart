import '../../cli/cli_optional_fields.dart';
import '../../updates/update_check_summary.dart';

String updateCheckLabel(UpdateCheckSummary update, String label) {
  return '$label ${cliOptionalStringText(update.latestVersion)}'.trim();
}

String installedUpdateLabel(UpdateInstallSummary update, String label) {
  return '$label ${cliOptionalStringText(firstPresentCliOptionalString([update.installedVersion, update.currentVersion]))}'
      .trim();
}
