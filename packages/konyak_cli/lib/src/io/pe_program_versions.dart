import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../domain/shared/domain_value_objects.dart';
import 'external_payload_helpers.dart';
import 'pe_program_image.dart';
import 'pe_program_resources.dart';

PeVersionStrings peVersionStrings(PortableExecutableImage image) {
  final resources = peResourceLeaves(image, 16);
  final versionStrings = resources.fold(
    PeVersionStringOptions.empty(),
    (options, resource) => options.withValuesFrom(utf16LeTokens(resource.data)),
  );

  return PeVersionStrings(
    fileDescription: versionStrings.fileDescription.map(
      ProgramFileDescription.new,
    ),
    productName: versionStrings.productName.map(ProgramProductName.new),
    companyName: versionStrings.companyName.map(ProgramCompanyName.new),
    fileVersion: versionStrings.fileVersion.map(ProgramFileVersion.new),
    productVersion: versionStrings.productVersion.map(
      ProgramProductVersion.new,
    ),
  );
}

final class PeVersionStringOptions {
  const PeVersionStringOptions({
    required this.fileDescription,
    required this.productName,
    required this.companyName,
    required this.fileVersion,
    required this.productVersion,
  });

  factory PeVersionStringOptions.empty() {
    return const PeVersionStringOptions(
      fileDescription: Option.none(),
      productName: Option.none(),
      companyName: Option.none(),
      fileVersion: Option.none(),
      productVersion: Option.none(),
    );
  }

  final Option<String> fileDescription;
  final Option<String> productName;
  final Option<String> companyName;
  final Option<String> fileVersion;
  final Option<String> productVersion;

  PeVersionStringOptions withValuesFrom(List<String> values) {
    return PeVersionStringOptions(
      fileDescription: firstPresent(
        fileDescription,
        valueAfterToken(values, 'FileDescription'),
      ),
      productName: firstPresent(
        productName,
        valueAfterToken(values, 'ProductName'),
      ),
      companyName: firstPresent(
        companyName,
        valueAfterToken(values, 'CompanyName'),
      ),
      fileVersion: firstPresent(
        fileVersion,
        valueAfterToken(values, 'FileVersion'),
      ),
      productVersion: firstPresent(
        productVersion,
        valueAfterToken(values, 'ProductVersion'),
      ),
    );
  }
}

Option<String> firstPresent(Option<String> current, Option<String> next) {
  return current.match(() => next, (_) => current);
}

final class PeVersionStrings {
  const PeVersionStrings({
    required this.fileDescription,
    required this.productName,
    required this.companyName,
    required this.fileVersion,
    required this.productVersion,
  });

  final Option<ProgramFileDescription> fileDescription;
  final Option<ProgramProductName> productName;
  final Option<ProgramCompanyName> companyName;
  final Option<ProgramFileVersion> fileVersion;
  final Option<ProgramProductVersion> productVersion;
}

Option<String> valueAfterToken(List<String> values, String key) {
  final knownKeys = const <String>{
    'FileDescription',
    'ProductName',
    'CompanyName',
    'FileVersion',
    'ProductVersion',
  };
  for (final (index, value) in values.indexed) {
    if (value != key) {
      continue;
    }
    final tokenValue = firstTokenValueBeforeKnownKey(
      values.skip(index + 1),
      knownKeys: knownKeys,
    );
    if (tokenValue.isSome()) {
      return tokenValue;
    }
  }

  return const Option.none();
}

Option<String> firstTokenValueBeforeKnownKey(
  Iterable<String> values, {
  required Set<String> knownKeys,
}) {
  for (final value in values) {
    if (knownKeys.contains(value)) {
      return const Option.none();
    }
    if (value.isNotEmpty) {
      return Option.of(value);
    }
  }

  return const Option.none();
}

List<String> utf16LeTokens(Uint8List bytes) {
  final codeUnits = Iterable<int>.generate(
    bytes.length ~/ 2,
    (index) => readUint16Option(bytes, index * 2).getOrElse(() => 0),
  );

  return String.fromCharCodes(codeUnits)
      .split('\u0000')
      .map((value) => value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
