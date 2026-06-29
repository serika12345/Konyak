import 'package:args/args.dart';

import '../domain/shared/domain_value_objects.dart';
import 'cli_parsers.dart';

BottleId? requiredCliBottleId(ArgResults results, {int index = 0}) {
  final value = requiredCliRest(results, index: index);
  return value == null ? null : BottleId(value);
}
