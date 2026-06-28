import '../updates/update_check_summary.dart';

sealed class UpdateCheckLoadResult {
  const UpdateCheckLoadResult();
}

final class LoadedUpdateCheck extends UpdateCheckLoadResult {
  const LoadedUpdateCheck(this.update);

  final UpdateCheckSummary update;
}

final class UpdateCheckLoadFailure extends UpdateCheckLoadResult {
  const UpdateCheckLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class UpdateInstallLoadResult {
  const UpdateInstallLoadResult();
}

final class InstalledUpdate extends UpdateInstallLoadResult {
  const InstalledUpdate(this.update);

  final UpdateInstallSummary update;
}

final class UpdateInstallLoadFailure extends UpdateInstallLoadResult {
  const UpdateInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}
