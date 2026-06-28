class BottleRepositoryException implements Exception {
  const BottleRepositoryException(this.message);

  final String message;
}

class AppSettingsRepositoryException implements Exception {
  const AppSettingsRepositoryException(this.message);

  final String message;
}
