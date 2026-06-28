import 'package:args/args.dart' hide Option;

bool isJsonFlagOnlyCommand(List<String> arguments, String command) {
  final results = parseJsonCliCommand(arguments, command: command);
  return results != null && results.rest.isEmpty;
}

ArgResults? parseJsonCliCommand(
  List<String> arguments, {
  required String command,
  Iterable<String> options = const <String>[],
  Iterable<String> multiOptions = const <String>[],
  Iterable<String> flags = const <String>[],
}) {
  if (arguments.length < 2 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return null;
  }

  final parser = ArgParser();
  for (final option in options) {
    parser.addOption(option);
  }
  for (final option in multiOptions) {
    parser.addMultiOption(option);
  }
  for (final flag in flags) {
    parser.addFlag(flag, negatable: false);
  }
  parser.addFlag('json', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments.sublist(1));
  } on FormatException {
    return null;
  }

  if (results['json'] != true) {
    return null;
  }

  return results;
}

String? requiredCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  final value = results[name] as String?;
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? optionalCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  return requiredCliOption(results, name);
}

String? requiredCliRest(ArgResults results, {int index = 0}) {
  if (results.rest.length <= index) {
    return null;
  }

  final value = results.rest[index].trim();
  return value.isEmpty ? null : value;
}

bool hasRestCount(ArgResults results, int count) {
  return results.rest.length == count;
}

bool hasEmptyParsedCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return false;
  }

  final value = results[name] as String?;
  return value == null || value.trim().isEmpty;
}
