part of '../../konyak_cli.dart';

class DartIoProgramMetadataExtractor implements ProgramMetadataExtractor {
  const DartIoProgramMetadataExtractor();

  @override
  ProgramMetadataRecord? extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    try {
      final file = File(programPath);
      if (!file.existsSync()) {
        return null;
      }

      final image = _PortableExecutableImage.parse(file.readAsBytesSync());
      if (image == null) {
        return null;
      }

      final versionStrings = _peVersionStrings(image);
      final iconPath = _extractPeIcon(
        image: image,
        bottle: bottle,
        programPath: programPath,
        fileStat: file.statSync(),
      );
      final metadata = ProgramMetadataRecord(
        architecture: image.architecture,
        fileDescription: versionStrings['FileDescription'],
        productName: versionStrings['ProductName'],
        companyName: versionStrings['CompanyName'],
        fileVersion: versionStrings['FileVersion'],
        productVersion: versionStrings['ProductVersion'],
        iconPath: iconPath,
      );

      return metadata.isEmpty ? null : metadata;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }
}
