part of 'konyak_cli_client.dart';

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

sealed class GraphicsBackendHintsLoadResult {
  const GraphicsBackendHintsLoadResult();
}

final class LoadedGraphicsBackendHints extends GraphicsBackendHintsLoadResult {
  const LoadedGraphicsBackendHints(this.hints);

  final ProgramGraphicsBackendHintsSummary hints;
}

final class GraphicsBackendHintsLoadFailure
    extends GraphicsBackendHintsLoadResult {
  const GraphicsBackendHintsLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class ProgramGraphicsBackendHintsSummary {
  ProgramGraphicsBackendHintsSummary({
    required this.programPath,
    required this.hostPlatform,
    required Iterable<ProgramGraphicsBackendSignalSummary> signals,
    required Iterable<ProgramGraphicsBackendSuggestionSummary> suggestions,
  }) : signals = List.unmodifiable(signals),
       suggestions = List.unmodifiable(suggestions);

  final String programPath;
  final String hostPlatform;
  final List<ProgramGraphicsBackendSignalSummary> signals;
  final List<ProgramGraphicsBackendSuggestionSummary> suggestions;
}

final class ProgramGraphicsBackendSignalSummary {
  const ProgramGraphicsBackendSignalSummary({
    required this.kind,
    required this.value,
  });

  final String kind;
  final String value;
}

final class ProgramGraphicsBackendSuggestionSummary {
  const ProgramGraphicsBackendSuggestionSummary({
    required this.backend,
    required this.confidence,
    required this.reason,
  });

  final String backend;
  final String confidence;
  final String reason;
}
