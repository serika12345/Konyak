part of '../konyak_cli.dart';

class FileBottleRepository
    with
        _FileBottleRepositoryReadOperations,
        _FileBottleRepositoryArchiveOperations,
        _FileBottleRepositoryMutationOperations,
        _FileBottleRepositoryProgramOperations
    implements BottleRepository {
  FileBottleRepository({
    required this.dataHome,
    String? bottleDirectory,
    ProgramMetadataExtractor programMetadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : bottleDirectory =
           bottleDirectory ?? _joinPath(dataHome, const ['bottles']),
       _programMetadataExtractor = programMetadataExtractor;

  factory FileBottleRepository.fromEnvironment(
    Map<String, String> environment, {
    String? bottleDirectory,
  }) {
    return FileBottleRepository(
      dataHome: _resolveDataHome(environment),
      bottleDirectory: bottleDirectory,
    );
  }

  @override
  final String dataHome;
  @override
  final String bottleDirectory;
  @override
  final ProgramMetadataExtractor _programMetadataExtractor;
}
