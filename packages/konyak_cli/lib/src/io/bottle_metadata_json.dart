import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_profile_models.dart';

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
    'profileId': profile.profileId.value,
    'profileVersion': profile.profileVersion.value,
    'managedProgramPath': profile.managedProgramPath.value,
    'compatibilityProfileId': profile.compatibilityProfileId.value,
    'compatibilityProfileVersion': profile.compatibilityProfileVersion.value,
  };
}
