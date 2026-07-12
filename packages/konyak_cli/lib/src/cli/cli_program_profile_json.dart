import '../domain/program/program_profile_models.dart';
import '../io/bottle_metadata_json.dart';

Map<String, Object?> installProfileSummaryJson(InstallProfileRecord profile) {
  return <String, Object?>{
    'id': profile.id.value,
    'name': profile.name.value,
    'profileVersion': profile.profileVersion.value,
  };
}

Map<String, Object?> installProfileJson(InstallProfileRecord profile) {
  return <String, Object?>{
    'id': profile.id.value,
    'name': profile.name.value,
    'profileVersion': profile.profileVersion.value,
    'summary': profile.summary.value,
    'platforms': profile.platforms
        .map((platform) => platform.value)
        .toList(growable: false),
    'bottleTemplate': <String, Object?>{
      'windowsVersion': profile.windowsVersion.value,
    },
    'managedProgramPath': profile.managedProgramPath.value,
    'dependencyWinetricksVerbs': profile.dependencyWinetricksVerbs
        .map((verb) => verb.value)
        .toList(growable: false),
    'runCompletionPolicy': profile.runCompletionPolicy.value,
    'compatibilityProfile': compatibilityProfileJson(
      profile.compatibilityProfile,
    ),
  };
}

Map<String, Object?> compatibilityProfileJson(
  CompatibilityProfileRecord profile,
) {
  return <String, Object?>{
    'id': profile.id.value,
    'profileVersion': profile.profileVersion.value,
    'childProcessRules': profile.childProcessRules
        .map(childProcessCompatibilityRuleJson)
        .toList(growable: false),
  };
}

Map<String, Object?> childProcessCompatibilityRuleJson(
  ChildProcessCompatibilityRule rule,
) {
  return <String, Object?>{
    'executableSuffix': rule.executableSuffix.value,
    'appendArgumentsIfMissing': rule.appendArgumentsIfMissing.value,
  };
}

Map<String, Object?> programProfileJson({
  required String bottleId,
  required ProgramProfileRecord profile,
}) {
  return <String, Object?>{
    'bottleId': bottleId,
    ...programProfileRecordJson(profile),
  };
}
