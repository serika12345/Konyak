import 'dart:convert';
import 'dart:io';

class Option<T> {
  const Option(this.value);

  final T value;
}

String readBoundaryFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return '';
  }

  return file.readAsStringSync();
}

String readBoundaryEnvironment() {
  return Platform.environment['HOME'] ?? '';
}

class DartIoAllowedBoundary {
  const DartIoAllowedBoundary();

  void write(StringSink output) {
    output.writeln(jsonEncode(<String, Object?>{'ok': true}));
  }
}

Future<Option<Map<String, Object?>>> readDecodedJsonBoundary() async {
  return const Option(<String, Object?>{'ok': true});
}
