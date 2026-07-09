import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/io_result.dart';
import '../shared/common_helpers.dart';
import '../storage/storage_paths.dart';
import 'file_bottle_repository_archive_operations.dart';
import 'file_bottle_repository_mutation_operations.dart';
import 'file_bottle_repository_program_operations.dart';
import 'file_bottle_repository_read_operations.dart';
import 'repository_interfaces.dart';

class FileBottleRepository implements BottleRepository {
  factory FileBottleRepository({
    required String dataHome,
    Option<String> bottleDirectory = const Option.none(),
    required ProgramMetadataExtractor programMetadataExtractor,
  }) {
    final resolvedBottleDirectory = bottleDirectory.match(
      () => joinPath(dataHome, const ['bottles']),
      (value) => value,
    );
    final readOperations = FileBottleRepositoryReadOperations(
      bottleDirectory: resolvedBottleDirectory,
      programMetadataExtractor: programMetadataExtractor,
    );

    return FileBottleRepository._(
      dataHome: dataHome,
      bottleDirectory: resolvedBottleDirectory,
      readOperations: readOperations,
      mutationOperations: FileBottleRepositoryMutationOperations(
        dataHome: dataHome,
        bottleDirectory: resolvedBottleDirectory,
        findBottle: readOperations.findBottle,
      ),
      archiveOperations: FileBottleRepositoryArchiveOperations(
        bottleDirectory: resolvedBottleDirectory,
        findBottle: readOperations.findBottle,
      ),
      programOperations: FileBottleRepositoryProgramOperations(
        programMetadataExtractor: programMetadataExtractor,
        findBottle: readOperations.findBottle,
      ),
    );
  }

  const FileBottleRepository._({
    required this.dataHome,
    required this.bottleDirectory,
    required this.readOperations,
    required this.mutationOperations,
    required this.archiveOperations,
    required this.programOperations,
  });

  factory FileBottleRepository.fromEnvironment(
    HostEnvironment environment, {
    Option<String> bottleDirectory = const Option.none(),
    required ProgramMetadataExtractor programMetadataExtractor,
  }) {
    return FileBottleRepository(
      dataHome: resolveDataHome(environment),
      bottleDirectory: bottleDirectory,
      programMetadataExtractor: programMetadataExtractor,
    );
  }

  final String dataHome;
  final String bottleDirectory;
  final FileBottleRepositoryReadOperations readOperations;
  final FileBottleRepositoryMutationOperations mutationOperations;
  final FileBottleRepositoryArchiveOperations archiveOperations;
  final FileBottleRepositoryProgramOperations programOperations;

  @override
  IoResult<List<BottleRecord>> listBottles() => readOperations.listBottles();

  @override
  IoResult<Option<BottleRecord>> findBottle(BottleId id) {
    return readOperations.findBottle(id);
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return mutationOperations.createBottle(request);
  }

  @override
  BottleDeleteResult deleteBottle(BottleId id) {
    return mutationOperations.deleteBottle(id);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return mutationOperations.renameBottle(request);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return mutationOperations.moveBottle(request);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return mutationOperations.setWindowsVersion(request);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return mutationOperations.setRuntimeSettings(request);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return archiveOperations.exportBottleArchive(request);
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return archiveOperations.importBottleArchive(request);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return programOperations.pinProgram(request);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return programOperations.unpinProgram(request);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return programOperations.renamePinnedProgram(request);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return programOperations.readProgramSettings(request);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return programOperations.setProgramSettings(request);
  }

  @override
  ProgramProfileUpdateResult applyProgramProfile(
    ProgramProfileApplyRequest request,
  ) {
    return programOperations.applyProgramProfile(request);
  }

  @override
  ProgramProfileUpdateResult repairProgramProfile(
    ProgramProfileRepairRequest request,
  ) {
    return programOperations.repairProgramProfile(request);
  }
}
