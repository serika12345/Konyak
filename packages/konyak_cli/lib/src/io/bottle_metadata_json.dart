import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_profile_models.dart';
import '../shared/model_constants.dart';

Map<String, Object?> bottleRecordJson(BottleRecord bottle) {
  return <String, Object?>{
    'id': bottle.id.value,
    'name': bottle.name.value,
    'path': bottle.path.value,
    'windowsVersion': bottle.windowsVersion.value,
    if (bottle.runtimeSettings != BottleRuntimeSettings())
      'runtimeSettings': bottleRuntimeSettingsJson(bottle.runtimeSettings),
    if (bottle.pinnedPrograms.isNotEmpty)
      'pinnedPrograms': bottle.pinnedPrograms
          .map(pinnedProgramRecordJson)
          .toList(growable: false),
    if (bottle.programProfiles.isNotEmpty)
      'profiles': bottle.programProfiles
          .map(programProfileRecordJson)
          .toList(growable: false),
  };
}

Map<String, Object?> bottleMetadataDocumentJson(BottleRecord bottle) {
  return <String, Object?>{
    'schemaVersion': cliSchemaVersion,
    'bottle': bottleRecordJson(bottle),
  };
}

Map<String, Object?> pinnedProgramRecordJson(PinnedProgramRecord program) {
  return <String, Object?>{
    'name': program.name.value,
    'path': program.path.value,
    'removable': program.removable,
    ...program.iconPath.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'iconPath': value.value},
    ),
  };
}

Map<String, Object?> bottleRuntimeSettingsJson(BottleRuntimeSettings settings) {
  return <String, Object?>{
    'enhancedSync': settings.enhancedSync.value,
    'metalHud': settings.metalHud,
    'metalTrace': settings.metalTrace,
    'avxEnabled': settings.avxEnabled,
    'dxrEnabled': settings.dxrEnabled,
    'dxvk': settings.dxvk,
    'dxmt': settings.dxmt,
    'dlssMetalFx': settings.dlssMetalFx,
    'dxvkAsync': settings.dxvkAsync,
    'dxvkHud': settings.dxvkHud.value,
    'vkd3dProton': settings.vkd3dProton,
    'buildVersion': settings.buildVersion.value,
    'retinaMode': settings.retinaMode,
    'dpiScaling': settings.dpiScaling.value,
  };
}

Map<String, Object?> programProfileRecordJson(ProgramProfileRecord profile) {
  return <String, Object?>{
    'profileSchemaVersion': profile.profileSchemaVersion.value,
    'profileId': profile.profileId.value,
    'profileVersion': profile.profileVersion.value,
    'profileSourceKind': profile.profileSourceKind.value,
    'profileSourceId': profile.profileSourceId.value,
    'profileDigest': profile.profileDigest.value,
    'managedProgramPath': profile.managedProgramPath.value,
    'compatibilityProfileId': profile.compatibilityProfileId.value,
    'compatibilityProfileVersion': profile.compatibilityProfileVersion.value,
    'installerResource': <String, Object?>{
      'kind': profile.installerResource.kind.value,
      'url': profile.installerResource.url.value,
      'sha256': profile.installerResource.sha256.value,
      'fileName': profile.installerResource.fileName.value,
    },
    'preInstallActions': profile.preInstallActions
        .map(preInstallActionJson)
        .toList(growable: false),
    ...profile.launchPolicy.match(
      () => const <String, Object?>{},
      (policy) => <String, Object?>{
        'launchPolicy': <String, Object?>{
          'runCompletionPolicy': policy.runCompletionPolicy.value,
          'compatibilityProfile': <String, Object?>{
            'id': policy.compatibilityProfile.id.value,
            'profileVersion': policy.compatibilityProfile.profileVersion.value,
            'childProcessRules': policy.compatibilityProfile.childProcessRules
                .map(
                  (rule) => <String, Object?>{
                    'executableSuffix': rule.executableSuffix.value,
                    'appendArgumentsIfMissing':
                        rule.appendArgumentsIfMissing.value,
                  },
                )
                .toList(growable: false),
          },
        },
      },
    ),
  };
}

Map<String, Object?> preInstallActionJson(PreInstallActionRecord action) {
  return switch (action) {
    WinetricksPreInstallAction(:final verb) => <String, Object?>{
      'kind': 'winetricks',
      'verb': verb.value,
    },
    NativeDllPreInstallAction(
      :final componentId,
      :final machine,
      :final destination,
      :final targetFileName,
      :final resource,
    ) =>
      <String, Object?>{
        'kind': 'nativeDll',
        'componentId': componentId.value,
        'machine': machine.value,
        'destination': destination.value,
        'targetFileName': targetFileName.value,
        'resource': <String, Object?>{
          'kind': resource.kind.value,
          'url': resource.url.value,
          'sha256': resource.sha256.value,
          'fileName': resource.fileName.value,
        },
      },
  };
}
