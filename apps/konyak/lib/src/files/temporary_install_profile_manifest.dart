typedef TemporaryInstallProfileManifestAction<T> =
    Future<T> Function(String sourcePath);

sealed class TemporaryInstallProfileManifestResult<T> {
  const TemporaryInstallProfileManifestResult();
}

final class ExecutedTemporaryInstallProfileManifest<T>
    extends TemporaryInstallProfileManifestResult<T> {
  const ExecutedTemporaryInstallProfileManifest(this.value);

  final T value;
}

final class TemporaryInstallProfileManifestFailure<T>
    extends TemporaryInstallProfileManifestResult<T> {
  const TemporaryInstallProfileManifestFailure({
    required this.message,
    required this.diagnostic,
  });

  final String message;
  final String diagnostic;
}

abstract interface class TemporaryInstallProfileManifestExecutor {
  Future<TemporaryInstallProfileManifestResult<T>> execute<T>({
    required String manifestJson,
    required TemporaryInstallProfileManifestAction<T> action,
  });
}
