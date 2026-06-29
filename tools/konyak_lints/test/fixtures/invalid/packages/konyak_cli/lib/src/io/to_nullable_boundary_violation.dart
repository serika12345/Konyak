class Option<T> {
  const Option(this.value);

  final T value;
}

extension NullableBridge<T> on Option<T> {
  T? toNullable() {
    return value;
  }
}

T? nullableBoundaryBridge<T>(Option<T> value) {
  return value.toNullable();
}
