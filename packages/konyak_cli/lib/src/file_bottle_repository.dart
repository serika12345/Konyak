part of '../konyak_cli.dart';

class FileBottleRepository implements BottleRepository {
  factory FileBottleRepository({
    required String dataHome,
    String? bottleDirectory,
    ProgramMetadataExtractor programMetadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) {
    final resolvedBottleDirectory =
        bottleDirectory ?? _joinPath(dataHome, const ['bottles']);
    final readOperations = _FileBottleRepositoryReadOperations(
      bottleDirectory: resolvedBottleDirectory,
      programMetadataExtractor: programMetadataExtractor,
    );

    return FileBottleRepository._(
      dataHome: dataHome,
      bottleDirectory: resolvedBottleDirectory,
      readOperations: readOperations,
      mutationOperations: _FileBottleRepositoryMutationOperations(
        dataHome: dataHome,
        bottleDirectory: resolvedBottleDirectory,
        findBottle: readOperations.findBottle,
      ),
      archiveOperations: _FileBottleRepositoryArchiveOperations(
        bottleDirectory: resolvedBottleDirectory,
        findBottle: readOperations.findBottle,
      ),
      programOperations: _FileBottleRepositoryProgramOperations(
        programMetadataExtractor: programMetadataExtractor,
        findBottle: readOperations.findBottle,
      ),
    );
  }

  const FileBottleRepository._({
    required this.dataHome,
    required this.bottleDirectory,
    required _FileBottleRepositoryReadOperations readOperations,
    required _FileBottleRepositoryMutationOperations mutationOperations,
    required _FileBottleRepositoryArchiveOperations archiveOperations,
    required _FileBottleRepositoryProgramOperations programOperations,
  }) : _readOperations = readOperations,
       _mutationOperations = mutationOperations,
       _archiveOperations = archiveOperations,
       _programOperations = programOperations;

  factory FileBottleRepository.fromEnvironment(
    Map<String, String> environment, {
    String? bottleDirectory,
  }) {
    return FileBottleRepository(
      dataHome: _resolveDataHome(environment),
      bottleDirectory: bottleDirectory,
    );
  }

  final String dataHome;
  final String bottleDirectory;
  final _FileBottleRepositoryReadOperations _readOperations;
  final _FileBottleRepositoryMutationOperations _mutationOperations;
  final _FileBottleRepositoryArchiveOperations _archiveOperations;
  final _FileBottleRepositoryProgramOperations _programOperations;

  @override
  IoResult<List<BottleRecord>> listBottles() => _readOperations.listBottles();

  @override
  IoResult<BottleRecord?> findBottle(String id) {
    return _readOperations.findBottle(id);
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return _mutationOperations.createBottle(request);
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    return _mutationOperations.deleteBottle(id);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return _mutationOperations.renameBottle(request);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return _mutationOperations.moveBottle(request);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return _mutationOperations.setWindowsVersion(request);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return _mutationOperations.setRuntimeSettings(request);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return _archiveOperations.exportBottleArchive(request);
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _archiveOperations.importBottleArchive(request);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return _programOperations.pinProgram(request);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return _programOperations.unpinProgram(request);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return _programOperations.renamePinnedProgram(request);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return _programOperations.readProgramSettings(request);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return _programOperations.setProgramSettings(request);
  }
}
