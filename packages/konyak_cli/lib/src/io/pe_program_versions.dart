part of '../../konyak_cli.dart';

_PeVersionStrings _peVersionStrings(_PortableExecutableImage image) {
  final resources = _peResourceLeaves(image, 16);
  final versionStrings = resources.fold(
    _PeVersionStringOptions.empty(),
    (options, resource) =>
        options.withValuesFrom(_utf16LeTokens(resource.data)),
  );

  return _PeVersionStrings(
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

final class _PeVersionStringOptions {
  const _PeVersionStringOptions({
    required this.fileDescription,
    required this.productName,
    required this.companyName,
    required this.fileVersion,
    required this.productVersion,
  });

  factory _PeVersionStringOptions.empty() {
    return const _PeVersionStringOptions(
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

  _PeVersionStringOptions withValuesFrom(List<String> values) {
    return _PeVersionStringOptions(
      fileDescription: _firstPresent(
        fileDescription,
        _valueAfterToken(values, 'FileDescription'),
      ),
      productName: _firstPresent(
        productName,
        _valueAfterToken(values, 'ProductName'),
      ),
      companyName: _firstPresent(
        companyName,
        _valueAfterToken(values, 'CompanyName'),
      ),
      fileVersion: _firstPresent(
        fileVersion,
        _valueAfterToken(values, 'FileVersion'),
      ),
      productVersion: _firstPresent(
        productVersion,
        _valueAfterToken(values, 'ProductVersion'),
      ),
    );
  }
}

Option<String> _firstPresent(Option<String> current, Option<String> next) {
  return current.match(() => next, (_) => current);
}

final class _PeVersionStrings {
  const _PeVersionStrings({
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

Option<String> _valueAfterToken(List<String> values, String key) {
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
    final tokenValue = _firstTokenValueBeforeKnownKey(
      values.skip(index + 1),
      knownKeys: knownKeys,
    );
    if (tokenValue.isSome()) {
      return tokenValue;
    }
  }

  return const Option.none();
}

Option<String> _firstTokenValueBeforeKnownKey(
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

List<String> _utf16LeTokens(Uint8List bytes) {
  final codeUnits = Iterable<int>.generate(
    bytes.length ~/ 2,
    (index) => _readUint16Option(bytes, index * 2).getOrElse(() => 0),
  );

  return String.fromCharCodes(codeUnits)
      .split('\u0000')
      .map((value) => value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
