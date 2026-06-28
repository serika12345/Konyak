class SomeResult {
  const SomeResult();
}

class SomeFailed extends SomeResult {
  const SomeFailed(Object failure);
}

class SomeSucceeded extends SomeResult {
  const SomeSucceeded(this.value);

  final int value;
}

class Result<L, R> {
  const Result();

  T fold<T>(T Function(L failure) onFailure, T Function(R value) onSuccess) {
    throw UnimplementedError();
  }
}

class Option<T> {
  const Option.none();

  R match<R>(R Function() onNone, R Function(T value) onSome) {
    throw UnimplementedError();
  }
}

SomeResult explicitBranches(Result<Object, Option<int>> result) {
  return result.fold<SomeResult>(
    SomeFailed.new,
    (maybeValue) =>
        maybeValue.match(() => const SomeResult(), SomeSucceeded.new),
  );
}
