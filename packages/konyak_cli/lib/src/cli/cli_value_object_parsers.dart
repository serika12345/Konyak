import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/shared/domain_value_objects.dart';
import 'cli_parsers.dart';

BottleId? requiredCliBottleId(ArgResults results, {int index = 0}) {
  return nullableParsedOption(requiredCliBottleIdOption(results, index: index));
}

Option<BottleId> requiredCliBottleIdOption(
  ArgResults results, {
  int index = 0,
}) {
  return requiredCliRestOption(results, index: index).map(BottleId.new);
}
