part of '../../konyak_cli.dart';

class DartIoProgramMetadataExtractor implements ProgramMetadataExtractor {
  const DartIoProgramMetadataExtractor();

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    try {
      final file = File(programPath);
      if (!file.existsSync()) {
        return const Option.none();
      }

      final image = _PortableExecutableImage.parse(file.readAsBytesSync());
      if (image == null) {
        return const Option.none();
      }

      final versionStrings = _peVersionStrings(image);
      final iconPath = _extractPeIcon(
        image: image,
        bottle: bottle,
        programPath: programPath,
        fileStat: file.statSync(),
      );
      final metadata = ProgramMetadataRecord(
        architecture: Option.fromNullable(image.architecture),
        fileDescription: Option.fromNullable(versionStrings['FileDescription']),
        productName: Option.fromNullable(versionStrings['ProductName']),
        companyName: Option.fromNullable(versionStrings['CompanyName']),
        fileVersion: Option.fromNullable(versionStrings['FileVersion']),
        productVersion: Option.fromNullable(versionStrings['ProductVersion']),
        iconPath: Option.fromNullable(iconPath),
      );

      return metadata.isEmpty ? const Option.none() : Option.of(metadata);
    } on FileSystemException {
      return const Option.none();
    } on FormatException {
      return const Option.none();
    } on RangeError {
      return const Option.none();
    }
  }
}
