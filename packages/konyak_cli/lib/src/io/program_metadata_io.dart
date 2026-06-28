import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_catalog_models.dart';
import 'pe_program_icon_io.dart';
import 'pe_program_image.dart';
import 'pe_program_versions.dart';
import 'program_shortcut_metadata_io.dart';

class DartIoProgramMetadataExtractor implements ProgramMetadataExtractor {
  const DartIoProgramMetadataExtractor();

  @override
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    try {
      final resolvedMetadataProgramPath = metadataProgramPath(
        bottle: bottle,
        programPath: programPath,
      );
      final file = File(resolvedMetadataProgramPath);
      if (!file.existsSync()) {
        return const Option.none();
      }

      return PortableExecutableImage.parse(file.readAsBytesSync()).flatMap((
        image,
      ) {
        final versionStrings = peVersionStrings(image);
        final iconPath = extractPeIcon(
          image: image,
          bottle: bottle,
          programPath: resolvedMetadataProgramPath,
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
      final resolvedMetadataProgramPath = metadataProgramPath(
        bottle: bottle,
        programPath: programPath,
      );
      final file = File(resolvedMetadataProgramPath);
      if (!await file.exists()) {
        return const Option.none();
      }

      return await PortableExecutableImage.parse(
        await file.readAsBytes(),
      ).match(() async => const Option.none(), (image) async {
        final versionStrings = peVersionStrings(image);
        final iconPath = await extractPeIconAsync(
          image: image,
          bottle: bottle,
          programPath: resolvedMetadataProgramPath,
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
