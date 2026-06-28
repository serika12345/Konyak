part of '../../konyak_cli.dart';

class DartIoProgramMetadataExtractor implements ProgramMetadataExtractor {
  const DartIoProgramMetadataExtractor();

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    try {
      final metadataProgramPath = _metadataProgramPath(
        bottle: bottle,
        programPath: programPath,
      );
      final file = File(metadataProgramPath);
      if (!file.existsSync()) {
        return const Option.none();
      }

      return _PortableExecutableImage.parse(file.readAsBytesSync()).flatMap((
        image,
      ) {
        final versionStrings = _peVersionStrings(image);
        final iconPath = _extractPeIcon(
          image: image,
          bottle: bottle,
          programPath: metadataProgramPath,
          fileStat: file.statSync(),
        );
        final metadata = ProgramMetadataRecord(
          architecture: image.architecture,
          fileDescription: versionStrings.fileDescription.map(
            (value) => value.value,
          ),
          productName: versionStrings.productName.map((value) => value.value),
          companyName: versionStrings.companyName.map((value) => value.value),
          fileVersion: versionStrings.fileVersion.map((value) => value.value),
          productVersion: versionStrings.productVersion.map(
            (value) => value.value,
          ),
          iconPath: Option.fromNullable(iconPath),
        );

        return metadata.isEmpty ? const Option.none() : Option.of(metadata);
      });
    } on FileSystemException {
      return const Option.none();
    } on FormatException {
      return const Option.none();
    } on RangeError {
      return const Option.none();
    }
  }
}

class DartIoAsyncProgramMetadataExtractor
    implements AsyncProgramMetadataExtractor {
  const DartIoAsyncProgramMetadataExtractor();

  @override
  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required String programPath,
  }) async {
    try {
      final metadataProgramPath = _metadataProgramPath(
        bottle: bottle,
        programPath: programPath,
      );
      final file = File(metadataProgramPath);
      if (!await file.exists()) {
        return const Option.none();
      }

      return await _PortableExecutableImage.parse(
        await file.readAsBytes(),
      ).match(() async => const Option.none(), (image) async {
        final versionStrings = _peVersionStrings(image);
        final iconPath = await _extractPeIconAsync(
          image: image,
          bottle: bottle,
          programPath: metadataProgramPath,
          fileStat: await file.stat(),
        );
        final metadata = ProgramMetadataRecord(
          architecture: image.architecture,
          fileDescription: versionStrings.fileDescription.map(
            (value) => value.value,
          ),
          productName: versionStrings.productName.map((value) => value.value),
          companyName: versionStrings.companyName.map((value) => value.value),
          fileVersion: versionStrings.fileVersion.map((value) => value.value),
          productVersion: versionStrings.productVersion.map(
            (value) => value.value,
          ),
          iconPath: Option.fromNullable(iconPath),
        );

        return metadata.isEmpty ? const Option.none() : Option.of(metadata);
      });
    } on FileSystemException {
      return const Option.none();
    } on FormatException {
      return const Option.none();
    } on RangeError {
      return const Option.none();
    }
  }
}
