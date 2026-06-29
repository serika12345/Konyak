import 'dart:async';

class Option<T> {
  const Option.none();
}

Option<int>? nullableOptionResult() {
  return null;
}

Future<String?> nullableFutureResult() async {
  return null;
}

Future<Map<String, Object?>?> nullableFutureJsonResult() async {
  return null;
}

Future<Option<int>>? nullableFutureCache() {
  return null;
}
