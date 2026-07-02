import 'package:freezed_annotation/freezed_annotation.dart';

part 'cli_optional_fields.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class CliOptionalString with _$CliOptionalString {
  const factory CliOptionalString.absent() = AbsentCliOptionalString;

  const factory CliOptionalString.explicitNull() =
      ExplicitNullCliOptionalString;

  const factory CliOptionalString.present(String value) =
      PresentCliOptionalString;
}

sealed class CliOptionalStringParseResult {
  const CliOptionalStringParseResult();
}

final class ParsedCliOptionalString extends CliOptionalStringParseResult {
  const ParsedCliOptionalString(this.value);

  final CliOptionalString value;
}

final class InvalidCliOptionalString extends CliOptionalStringParseResult {
  const InvalidCliOptionalString();
}

String cliOptionalStringText(CliOptionalString value) {
  return switch (value) {
    PresentCliOptionalString(:final value) => value,
    AbsentCliOptionalString() || ExplicitNullCliOptionalString() => '',
  };
}

CliOptionalString firstPresentCliOptionalString(
  Iterable<CliOptionalString> values,
) {
  for (final value in values) {
    switch (value) {
      case PresentCliOptionalString():
        return value;
      case AbsentCliOptionalString() || ExplicitNullCliOptionalString():
        continue;
    }
  }

  return const CliOptionalString.absent();
}
