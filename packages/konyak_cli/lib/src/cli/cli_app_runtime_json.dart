import '../io/gptk_wine_installation.dart';
import '../platform/macos/macos_setup_checker.dart';

Map<String, Object?> macosSetupStatusJson(MacosSetupStatus status) {
  return <String, Object?>{
    'isSupported': status.isSupported,
    'rosetta': rosettaSetupStatusJson(status.rosetta),
    'runtime': runtimeSetupStatusJson(status.runtime),
  };
}

Map<String, Object?> rosettaSetupStatusJson(RosettaSetupStatus status) {
  return <String, Object?>{
    'isRequired': status.isRequired,
    'isInstalled': status.isInstalled,
    'installCommand': status.installCommand,
  };
}

Map<String, Object?> runtimeSetupStatusJson(RuntimeSetupStatus status) {
  return <String, Object?>{
    'runtimeId': status.runtimeId,
    'isInstalled': status.isInstalled,
  };
}

Map<String, Object?> gptkWineInstallRecordJson(GptkWineInstallRecord record) {
  return <String, Object?>{
    'componentId': record.componentId,
    'detectedVersion': gptkWineImportVersionCliValue(record.detectedVersion),
    'sourceDirectory': record.sourceDirectory,
    'runtimeRoot': record.runtimeRoot,
    'installedExecutablePath': record.installedExecutablePath,
  };
}
