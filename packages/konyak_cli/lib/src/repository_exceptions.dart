part of '../konyak_cli.dart';

class BottleRepositoryException implements Exception {
  const BottleRepositoryException(this.message);

  final String message;
}

class AppSettingsRepositoryException implements Exception {
  const AppSettingsRepositoryException(this.message);

  final String message;
}

Either<String, T> _repositoryIoResult<T>(T Function() operation) {
  try {
    return Right<String, T>(operation());
  } on FileSystemException catch (error) {
    return Left<String, T>(error.message);
  } on FormatException catch (error) {
    return Left<String, T>(error.message);
  }
}
