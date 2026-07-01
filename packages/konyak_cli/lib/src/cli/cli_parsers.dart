import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

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

Option<ArgResults> parseJsonCliCommandOption(
  List<String> arguments, {
  required String command,
  Iterable<String> options = const <String>[],
  Iterable<String> multiOptions = const <String>[],
  Iterable<String> flags = const <String>[],
}) {
  return Option.fromNullable(
    parseJsonCliCommand(
      arguments,
      command: command,
      options: options,
      multiOptions: multiOptions,
      flags: flags,
    ),
  );
}

String? requiredCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  final value = results[name] as String?;
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

Option<String> requiredCliOptionOption(ArgResults results, String name) {
  return Option.fromNullable(requiredCliOption(results, name));
}

String? optionalCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  return requiredCliOption(results, name);
}

Option<String> optionalCliOptionOption(ArgResults results, String name) {
  return Option.fromNullable(optionalCliOption(results, name));
}

String? requiredCliRest(ArgResults results, {int index = 0}) {
  if (results.rest.length <= index) {
    return null;
  }

  final value = results.rest[index].trim();
  return value.isEmpty ? null : value;
}

Option<String> requiredCliRestOption(ArgResults results, {int index = 0}) {
  return Option.fromNullable(requiredCliRest(results, index: index));
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

T? nullableParsedOption<T>(Option<T> option) {
  return option.match(() => null, (value) => value);
}
