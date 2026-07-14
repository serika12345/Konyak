import '../bottles/bottle_summary.dart';
import '../runs/program_run_summary.dart';

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
    this.logFileCreated = true,
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
  final bool logFileCreated;
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

sealed class InstallProfileListLoadResult {
  const InstallProfileListLoadResult();
}

final class LoadedInstallProfiles extends InstallProfileListLoadResult {
  LoadedInstallProfiles({required Iterable<InstallProfileListItem> profiles})
    : profiles = List.unmodifiable(profiles);

  final List<InstallProfileListItem> profiles;
}

final class InstallProfileListLoadFailure extends InstallProfileListLoadResult {
  const InstallProfileListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class InstallProfileInspectLoadResult {
  const InstallProfileInspectLoadResult();
}

final class InspectedInstallProfile extends InstallProfileInspectLoadResult {
  const InspectedInstallProfile(this.profile);

  final InstallProfileDetails profile;
}

final class InstallProfileInspectLoadFailure
    extends InstallProfileInspectLoadResult {
  const InstallProfileInspectLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramProfileApplyLoadResult {
  const ProgramProfileApplyLoadResult();
}

final class AppliedProgramProfile extends ProgramProfileApplyLoadResult {
  const AppliedProgramProfile(this.profile);

  final ProgramProfileSummary profile;
}

final class ProgramProfileApplyLoadFailure
    extends ProgramProfileApplyLoadResult {
  const ProgramProfileApplyLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramProfileInstallLoadResult {
  const ProgramProfileInstallLoadResult();
}

final class InstalledProgramProfile extends ProgramProfileInstallLoadResult {
  const InstalledProgramProfile(this.profile);

  final ProgramProfileSummary profile;
}

final class ProgramProfileInstallLoadFailure
    extends ProgramProfileInstallLoadResult {
  const ProgramProfileInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class InstallProfileListItem {
  const InstallProfileListItem({
    required this.id,
    required this.name,
    required this.profileVersion,
  });

  final String id;
  final String name;
  final int profileVersion;
}

final class InstallProfileDetails {
  InstallProfileDetails({
    required this.id,
    required this.name,
    required this.profileVersion,
    required this.profileSourceKind,
    required this.profileSourceId,
    required this.profileDigest,
    required this.summary,
    required Iterable<String> platforms,
    required this.windowsVersion,
    required this.managedProgramPath,
    required this.installerResource,
    required Iterable<PreInstallActionSummary> preInstallActions,
    required this.runCompletionPolicy,
    required this.compatibilityProfile,
  }) : platforms = List.unmodifiable(platforms),
       preInstallActions = List.unmodifiable(preInstallActions);

  final String id;
  final String name;
  final int profileVersion;
  final String profileSourceKind;
  final String profileSourceId;
  final String profileDigest;
  final String summary;
  final List<String> platforms;
  final String windowsVersion;
  final String managedProgramPath;
  final InstallerResourceSummary installerResource;
  final List<PreInstallActionSummary> preInstallActions;
  final String runCompletionPolicy;
  final CompatibilityProfileSummary compatibilityProfile;
}

sealed class PreInstallActionSummary {
  const PreInstallActionSummary();

  String get id;
  String get kind;
}

final class WinetricksPreInstallActionSummary extends PreInstallActionSummary {
  const WinetricksPreInstallActionSummary(this.verb);

  final String verb;

  @override
  String get id => verb;

  @override
  String get kind => 'winetricks';
}

final class NativeDllPreInstallActionSummary extends PreInstallActionSummary {
  const NativeDllPreInstallActionSummary({
    required this.componentId,
    required this.machine,
    required this.destination,
    required this.targetFileName,
    required this.resource,
  });

  final String componentId;
  final String machine;
  final String destination;
  final String targetFileName;
  final NativeDllResourceSummary resource;

  @override
  String get id => componentId;

  @override
  String get kind => 'nativeDll';
}

final class NativeDllResourceSummary {
  factory NativeDllResourceSummary({
    required String kind,
    required String url,
    required String sha256,
    required String fileName,
  }) {
    final parsedUrl = _parseInstallerResourceUrl(url);
    if (kind != 'https' ||
        url.isEmpty ||
        url.length > 8192 ||
        url.codeUnits.any((code) => code <= 0x20 || code == 0x7f) ||
        parsedUrl.scheme != 'https' ||
        !parsedUrl.hasAuthority ||
        parsedUrl.host.isEmpty ||
        parsedUrl.authority.contains('@') ||
        parsedUrl.hasFragment ||
        !RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(sha256) ||
        !isSafeNativeDllFileName(fileName)) {
      throw ArgumentError('Invalid native DLL resource.');
    }
    return NativeDllResourceSummary._(
      kind: kind,
      url: url,
      sha256: sha256.toLowerCase(),
      fileName: fileName,
    );
  }

  const NativeDllResourceSummary._({
    required this.kind,
    required this.url,
    required this.sha256,
    required this.fileName,
  });

  final String kind;
  final String url;
  final String sha256;
  final String fileName;
}

bool isSafeNativeDllFileName(String value) {
  return value.length > 4 &&
      value.length <= 255 &&
      !value.contains('/') &&
      !value.contains('\\') &&
      value.toLowerCase().endsWith('.dll') &&
      value.codeUnits.every((code) => code > 0x1f && code != 0x7f);
}

final class InstallerResourceSummary {
  factory InstallerResourceSummary({
    required String kind,
    required String url,
    required String sha256,
    required String fileName,
  }) {
    final parsedUrl = _parseInstallerResourceUrl(url);
    final lowerCaseFileName = fileName.toLowerCase();
    final hasInstallerExtension =
        lowerCaseFileName.endsWith('.exe') ||
        lowerCaseFileName.endsWith('.msi');
    final isValid =
        kind == 'https' &&
        url.isNotEmpty &&
        url.length <= 8192 &&
        url.codeUnits.every(
          (codeUnit) => codeUnit > 0x20 && codeUnit != 0x7f,
        ) &&
        parsedUrl.scheme == 'https' &&
        parsedUrl.hasAuthority &&
        parsedUrl.host.isNotEmpty &&
        !parsedUrl.authority.contains('@') &&
        !parsedUrl.hasFragment &&
        RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(sha256) &&
        fileName.length > '.exe'.length &&
        fileName.length <= 255 &&
        !fileName.contains('/') &&
        !fileName.contains('\\') &&
        fileName.codeUnits.every(
          (codeUnit) => codeUnit > 0x1f && codeUnit != 0x7f,
        ) &&
        hasInstallerExtension;
    if (!isValid) {
      throw ArgumentError('Invalid installer resource summary.');
    }
    return InstallerResourceSummary._validated(
      kind: kind,
      url: url,
      sha256: sha256,
      fileName: fileName,
    );
  }

  const InstallerResourceSummary._validated({
    required this.kind,
    required this.url,
    required this.sha256,
    required this.fileName,
  });

  final String kind;
  final String url;
  final String sha256;
  final String fileName;
}

Uri _parseInstallerResourceUrl(String value) {
  try {
    return Uri.parse(value);
  } on FormatException {
    throw ArgumentError('Invalid installer resource URL.');
  }
}

final class CompatibilityProfileSummary {
  CompatibilityProfileSummary({
    required this.id,
    required this.profileVersion,
    required Iterable<ChildProcessCompatibilityRuleSummary> childProcessRules,
  }) : childProcessRules = List.unmodifiable(childProcessRules);

  final String id;
  final int profileVersion;
  final List<ChildProcessCompatibilityRuleSummary> childProcessRules;
}

final class ChildProcessCompatibilityRuleSummary {
  ChildProcessCompatibilityRuleSummary({
    required this.executableSuffix,
    required Iterable<String> appendArgumentsIfMissing,
  }) : appendArgumentsIfMissing = List.unmodifiable(appendArgumentsIfMissing);

  final String executableSuffix;
  final List<String> appendArgumentsIfMissing;
}

final class ProgramProfileSummary {
  const ProgramProfileSummary({
    required this.bottleId,
    required this.profileId,
    required this.profileVersion,
    required this.managedProgramPath,
    required this.compatibilityProfileId,
    required this.compatibilityProfileVersion,
  });

  final String bottleId;
  final String profileId;
  final int profileVersion;
  final String managedProgramPath;
  final String compatibilityProfileId;
  final int compatibilityProfileVersion;
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
