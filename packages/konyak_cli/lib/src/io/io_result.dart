part of '../../konyak_cli.dart';

typedef IoResult<T> = Either<String, T>;

Either<String, T> _ioResult<T>(T Function() operation) {
  try {
    return Right<String, T>(operation());
  } on FileSystemException catch (error) {
    return Left<String, T>(error.message);
  } on FormatException catch (error) {
    return Left<String, T>(error.message);
  } on ProcessException catch (error) {
    return Left<String, T>(error.message);
  } on IOException catch (error) {
    return Left<String, T>(error.toString());
  }
}
