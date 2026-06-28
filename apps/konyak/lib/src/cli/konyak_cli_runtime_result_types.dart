import '../runtimes/runtime_summary.dart';

sealed class RuntimeListLoadResult {
  const RuntimeListLoadResult();
}

final class LoadedRuntimeList extends RuntimeListLoadResult {
  const LoadedRuntimeList(this.runtimes);

  final List<RuntimeSummary> runtimes;
}

final class RuntimeListLoadFailure extends RuntimeListLoadResult {
  const RuntimeListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class RuntimeInstallLoadResult {
  const RuntimeInstallLoadResult();
}

final class InstalledRuntime extends RuntimeInstallLoadResult {
  const InstalledRuntime(this.runtime);

  final RuntimeSummary runtime;
}

final class RuntimeInstallLoadFailure extends RuntimeInstallLoadResult {
  const RuntimeInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}
