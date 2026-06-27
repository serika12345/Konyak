part of '../../../konyak_cli.dart';

_PeVersionStrings _peVersionStrings(_PortableExecutableImage image) {
  final resources = _peResourceLeaves(image, 16);
  String? fileDescription;
  String? productName;
  String? companyName;
  String? fileVersion;
  String? productVersion;

  void putIfAbsent(String key, String value) {
    switch (key) {
      case 'FileDescription':
        fileDescription ??= value;
      case 'ProductName':
        productName ??= value;
      case 'CompanyName':
        companyName ??= value;
      case 'FileVersion':
        fileVersion ??= value;
      case 'ProductVersion':
        productVersion ??= value;
    }
  }

  for (final resource in resources) {
    final strings = _utf16LeTokens(resource.data);
    for (final key in const <String>[
      'FileDescription',
      'ProductName',
      'CompanyName',
      'FileVersion',
      'ProductVersion',
    ]) {
      _valueAfterToken(
        strings,
        key,
      ).match(() {}, (value) => putIfAbsent(key, value));
    }
  }

  return _PeVersionStrings(
    fileDescription: Option.fromNullable(
      fileDescription,
    ).map(ProgramFileDescription.new),
    productName: Option.fromNullable(productName).map(ProgramProductName.new),
    companyName: Option.fromNullable(companyName).map(ProgramCompanyName.new),
    fileVersion: Option.fromNullable(fileVersion).map(ProgramFileVersion.new),
    productVersion: Option.fromNullable(
      productVersion,
    ).map(ProgramProductVersion.new),
  );
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
  for (var index = 0; index < values.length; index += 1) {
    if (values[index] != key) {
      continue;
    }
    for (
      var valueIndex = index + 1;
      valueIndex < values.length;
      valueIndex += 1
    ) {
      final value = values[valueIndex];
      if (knownKeys.contains(value)) {
        break;
      }
      if (value.isNotEmpty) {
        return Option.of(value);
      }
    }
  }

  return const Option.none();
}

List<String> _utf16LeTokens(Uint8List bytes) {
  final codeUnits = <int>[];
  for (var offset = 0; offset + 1 < bytes.length; offset += 2) {
    codeUnits.add(_readUint16(bytes, offset) ?? 0);
  }

  return String.fromCharCodes(codeUnits)
      .split('\u0000')
      .map((value) => value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
