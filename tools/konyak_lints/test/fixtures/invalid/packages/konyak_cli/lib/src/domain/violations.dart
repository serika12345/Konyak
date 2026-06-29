import 'dart:io';

class Failure {
  const Failure();
}

class SomeResult {
  const SomeResult();
}

class SomeFailed extends SomeResult {
  const SomeFailed(Object failure);
}

class SomeSucceeded extends SomeResult {
  const SomeSucceeded();
}

class Result<L, R> {
  const Result();

  T fold<T>(T Function(L failure) onFailure, T Function(R value) onSuccess) {
    throw UnimplementedError();
  }

  R getOrElse(R Function(L failure) onFailure) {
    throw UnimplementedError();
  }
}

class Option<T> {
  const Option.none();

  static Option<T> fromNullable<T>(T? value) {
    return Option<T>.none();
  }

  R match<R>(R Function() onNone, R Function(T value) onSome) {
    throw UnimplementedError();
  }
}

extension NullableBridge<T> on Option<T> {
  T? toNullable() {
    return null;
  }
}

SomeResult nullableFoldSentinel(Result<Failure, int> result) {
  final failure = result.fold<SomeResult?>(SomeFailed.new, (_) => null);

  if (failure == null) {
    return const SomeSucceeded();
  }

  return failure;
}

Object? wildcardNullSentinel(Result<Failure, int> result) {
  return result.fold<Object?>((_) => const Failure(), (_) => null);
}

Object? optionMatchNullSentinel(Option<int> value) {
  return value.match(() => null, (number) => number);
}

Option<int> collapsedFailure(Result<Failure, Option<int>> result) {
  return result.getOrElse((_) => const Option<int>.none());
}

int nullableBridge(Option<int> value) {
  return value.toNullable() ?? 0;
}

Option<int> nullableInputBridge(int? value) {
  return Option.fromNullable(value);
}

void domainIoReferences(File file, Directory directory) {
  File('/tmp/konyak').existsSync();
  directory.createSync();
  file.openSync();
  Process.runSync('echo', const <String>[]);
  HttpClient();
  throw const FileSystemException('bad');
}

int domainMutation(List<int> values, int input) {
  var total = input;
  total += 1;
  total++;
  values.add(total);
  return total > 0 ? (total > 1 ? total : 1) : 0;
}
