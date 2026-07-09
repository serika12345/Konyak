import 'package:fpdart/fpdart.dart';

import '../domain/app/app_settings_models.dart';
import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/io_result.dart';

abstract interface class BottleCatalog {
  IoResult<List<BottleRecord>> listBottles();

  IoResult<Option<BottleRecord>> findBottle(BottleId id);
}

abstract interface class AppSettingsRepository {
  IoResult<AppSettingsRecord> read();

  IoResult<AppSettingsRecord> write(AppSettingsRecord settings);
}

abstract interface class BottleRepository implements BottleCatalog {
  BottleCreateResult createBottle(BottleCreateRequest request);

  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  );

  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  );

  BottleDeleteResult deleteBottle(BottleId id);

  BottleRenameResult renameBottle(BottleRenameRequest request);

  BottleMoveResult moveBottle(BottleMoveRequest request);

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request);

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request);

  ProgramPinResult pinProgram(ProgramPinRequest request);

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request);

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request);

  ProgramSettingsReadResult readProgramSettings(ProgramSettingsRequest request);

  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  );

  ProgramProfileUpdateResult applyProgramProfile(
    ProgramProfileApplyRequest request,
  );

  ProgramProfileUpdateResult repairProgramProfile(
    ProgramProfileRepairRequest request,
  );
}

abstract interface class BottleProgramRepository {
  List<BottleProgramRecord> listPrograms(BottleRecord bottle);
}

abstract interface class BottlePrefixInitializer {
  BottlePrefixInitializationResult initialize(BottleRecord bottle);
}

sealed class BottlePrefixInitializationResult {
  const BottlePrefixInitializationResult();
}

class BottlePrefixInitialized extends BottlePrefixInitializationResult {
  const BottlePrefixInitialized();
}

class BottlePrefixInitializationFailed
    extends BottlePrefixInitializationResult {
  const BottlePrefixInitializationFailed(this.message);

  final String message;
}

abstract interface class WinetricksVerbRepository {
  WinetricksVerbListResult listVerbs();
}

abstract interface class WinetricksVerbLister {
  WinetricksVerbListResult listVerbs({required ProgramExecutable executable});
}
