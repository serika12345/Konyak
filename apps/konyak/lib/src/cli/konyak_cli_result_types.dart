part of 'konyak_cli_client.dart';

sealed class BottleListLoadResult {
  const BottleListLoadResult();
}

final class LoadedBottleList extends BottleListLoadResult {
  const LoadedBottleList(this.bottles);

  final List<BottleSummary> bottles;
}

final class BottleListLoadFailure extends BottleListLoadResult {
  const BottleListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleDetailLoadResult {
  const BottleDetailLoadResult();
}

final class LoadedBottleDetail extends BottleDetailLoadResult {
  const LoadedBottleDetail(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleDetail extends BottleDetailLoadResult {
  const MissingBottleDetail({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDetailLoadFailure extends BottleDetailLoadResult {
  const BottleDetailLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class RuntimeListLoadResult {
  const RuntimeListLoadResult();
}

final class LoadedRuntimeList extends RuntimeListLoadResult {
  const LoadedRuntimeList(this.runtimes);

  final List<RuntimeSummary> runtimes;
}

final class RuntimeListLoadFailure extends RuntimeListLoadResult {
  const RuntimeListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class RuntimeInstallLoadResult {
  const RuntimeInstallLoadResult();
}

final class InstalledRuntime extends RuntimeInstallLoadResult {
  const InstalledRuntime(this.runtime);

  final RuntimeSummary runtime;
}

final class RuntimeInstallLoadFailure extends RuntimeInstallLoadResult {
  const RuntimeInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class AppSettingsLoadResult {
  const AppSettingsLoadResult();
}

final class LoadedAppSettings extends AppSettingsLoadResult {
  const LoadedAppSettings(this.settings);

  final AppSettingsSummary settings;
}

final class AppSettingsLoadFailure extends AppSettingsLoadResult {
  const AppSettingsLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class UpdateCheckLoadResult {
  const UpdateCheckLoadResult();
}

final class LoadedUpdateCheck extends UpdateCheckLoadResult {
  const LoadedUpdateCheck(this.update);

  final UpdateCheckSummary update;
}

final class UpdateCheckLoadFailure extends UpdateCheckLoadResult {
  const UpdateCheckLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class UpdateInstallLoadResult {
  const UpdateInstallLoadResult();
}

final class InstalledUpdate extends UpdateInstallLoadResult {
  const InstalledUpdate(this.update);

  final UpdateInstallSummary update;
}

final class UpdateInstallLoadFailure extends UpdateInstallLoadResult {
  const UpdateInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class WineProcessTerminationLoadResult {
  const WineProcessTerminationLoadResult();
}

final class TerminatedWineProcesses extends WineProcessTerminationLoadResult {
  const TerminatedWineProcesses();
}

final class WineProcessTerminationLoadFailure
    extends WineProcessTerminationLoadResult {
  const WineProcessTerminationLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleCreateLoadResult {
  const BottleCreateLoadResult();
}

final class CreatedBottle extends BottleCreateLoadResult {
  const CreatedBottle(this.bottle);

  final BottleSummary bottle;
}

final class ExistingBottle extends BottleCreateLoadResult {
  const ExistingBottle({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleCreateLoadFailure extends BottleCreateLoadResult {
  const BottleCreateLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleArchiveExportLoadResult {
  const BottleArchiveExportLoadResult();
}

final class ExportedBottleArchive extends BottleArchiveExportLoadResult {
  const ExportedBottleArchive({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;
}

final class BottleArchiveExportLoadFailure
    extends BottleArchiveExportLoadResult {
  const BottleArchiveExportLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleArchiveImportLoadResult {
  const BottleArchiveImportLoadResult();
}

final class ImportedBottleArchive extends BottleArchiveImportLoadResult {
  const ImportedBottleArchive(this.bottle);

  final BottleSummary bottle;
}

final class BottleArchiveImportLoadFailure
    extends BottleArchiveImportLoadResult {
  const BottleArchiveImportLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleUpdateLoadResult {
  const BottleUpdateLoadResult();
}

final class UpdatedBottle extends BottleUpdateLoadResult {
  const UpdatedBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleUpdate extends BottleUpdateLoadResult {
  const MissingBottleUpdate({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleUpdateLoadFailure extends BottleUpdateLoadResult {
  const BottleUpdateLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleDeleteLoadResult {
  const BottleDeleteLoadResult();
}

final class DeletedBottle extends BottleDeleteLoadResult {
  const DeletedBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleDelete extends BottleDeleteLoadResult {
  const MissingBottleDelete({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDeleteLoadFailure extends BottleDeleteLoadResult {
  const BottleDeleteLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramRunLoadResult {
  const ProgramRunLoadResult();
}

final class CompletedProgramRun extends ProgramRunLoadResult {
  const CompletedProgramRun(this.run);

  final ProgramRunSummary run;
}

final class UnsupportedProgramRun extends ProgramRunLoadResult {
  const UnsupportedProgramRun({
    required this.programPath,
    required this.message,
  });

  final String programPath;
  final String message;
}

final class MissingProgramRunBottle extends ProgramRunLoadResult {
  const MissingProgramRunBottle({
    required this.bottleId,
    required this.message,
  });

  final String bottleId;
  final String message;
}

final class FailedProgramRun extends ProgramRunLoadResult {
  FailedProgramRun({
    required this.bottleId,
    required this.programPath,
    required this.message,
    required this.runnerKind,
    required this.executable,
    required List<String> argv,
    required this.logPath,
    this.workingDirectory,
  }) : argv = List.unmodifiable(argv);

  final String bottleId;
  final String programPath;
  final String message;
  final String runnerKind;
  final String executable;
  final String? workingDirectory;
  final List<String> argv;
  final String logPath;
}

final class ProgramRunLoadFailure extends ProgramRunLoadResult {
  const ProgramRunLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleLocationOpenResult {
  const BottleLocationOpenResult();
}

final class OpenedBottleLocation extends BottleLocationOpenResult {
  const OpenedBottleLocation({
    required this.bottleId,
    required this.location,
    required this.path,
  });

  final String bottleId;
  final String location;
  final String path;
}

final class BottleLocationOpenFailure extends BottleLocationOpenResult {
  const BottleLocationOpenFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramLocationOpenResult {
  const ProgramLocationOpenResult();
}

final class OpenedProgramLocation extends ProgramLocationOpenResult {
  const OpenedProgramLocation({
    required this.bottleId,
    required this.programPath,
    required this.path,
  });

  final String bottleId;
  final String programPath;
  final String path;
}

final class ProgramLocationOpenFailure extends ProgramLocationOpenResult {
  const ProgramLocationOpenFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramSettingsLoadResult {
  const ProgramSettingsLoadResult();
}

final class LoadedProgramSettings extends ProgramSettingsLoadResult {
  const LoadedProgramSettings({
    required this.bottleId,
    required this.programPath,
    required this.settings,
  });

  final String bottleId;
  final String programPath;
  final ProgramSettingsSummary settings;
}

final class MissingProgramSettingsBottle extends ProgramSettingsLoadResult {
  const MissingProgramSettingsBottle({
    required this.bottleId,
    required this.message,
  });

  final String bottleId;
  final String message;
}

final class ProgramSettingsLoadFailure extends ProgramSettingsLoadResult {
  const ProgramSettingsLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class BottleProgramSummary {
  const BottleProgramSummary({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    this.metadata,
  });

  final String id;
  final String name;
  final String path;
  final String source;
  final ProgramMetadataSummary? metadata;
}

final class ProgramMetadataSummary {
  const ProgramMetadataSummary({
    this.architecture,
    this.fileDescription,
    this.productName,
    this.companyName,
    this.fileVersion,
    this.productVersion,
    this.iconPath,
  });

  final String? architecture;
  final String? fileDescription;
  final String? productName;
  final String? companyName;
  final String? fileVersion;
  final String? productVersion;
  final String? iconPath;

  String get displayName {
    return fileDescription ?? productName ?? '';
  }
}

sealed class WineProcessListLoadResult {
  const WineProcessListLoadResult();
}

final class LoadedWineProcesses extends WineProcessListLoadResult {
  LoadedWineProcesses({required List<WineProcessSummary> processes})
    : processes = List.unmodifiable(processes);

  final List<WineProcessSummary> processes;
}

final class WineProcessListLoadFailure extends WineProcessListLoadResult {
  const WineProcessListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class WineProcessSummary {
  const WineProcessSummary({
    required this.bottleId,
    required this.processId,
    required this.executable,
    this.hostPath,
    this.metadata,
  });

  final String bottleId;
  final String processId;
  final String executable;
  final String? hostPath;
  final ProgramMetadataSummary? metadata;
}

sealed class BottleProgramListLoadResult {
  const BottleProgramListLoadResult();
}

final class LoadedBottlePrograms extends BottleProgramListLoadResult {
  LoadedBottlePrograms({
    required this.bottleId,
    required List<BottleProgramSummary> programs,
  }) : programs = List.unmodifiable(programs);

  final String bottleId;
  final List<BottleProgramSummary> programs;
}

final class BottleProgramListLoadFailure extends BottleProgramListLoadResult {
  const BottleProgramListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class WinetricksVerbSummary {
  const WinetricksVerbSummary({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

final class WinetricksCategorySummary {
  WinetricksCategorySummary({
    required this.id,
    required this.name,
    required List<WinetricksVerbSummary> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbSummary> verbs;
}

sealed class WinetricksVerbListLoadResult {
  const WinetricksVerbListLoadResult();
}

final class LoadedWinetricksVerbs extends WinetricksVerbListLoadResult {
  LoadedWinetricksVerbs({required List<WinetricksCategorySummary> categories})
    : categories = List.unmodifiable(categories);

  final List<WinetricksCategorySummary> categories;
}

final class WinetricksVerbListLoadFailure extends WinetricksVerbListLoadResult {
  const WinetricksVerbListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}
