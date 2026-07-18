import 'dart:convert';

import '../domain/program/program_profile_models.dart';

const konyakProfileSchemaFileName = 'profile.schema.json';
const konyakProfileSchemaUri =
    'https://raw.githubusercontent.com/serika12345/Konyak/main/'
    'packages/konyak_cli/profiles/profile.schema.json';

List<int> canonicalInstallProfileManifestBytes(InstallProfileRecord profile) {
  const encoder = JsonEncoder.withIndent('  ');
  return utf8.encode(
    '${encoder.convert(canonicalInstallProfileManifestJson(profile))}\n',
  );
}

Map<String, Object?> canonicalInstallProfileManifestJson(
  InstallProfileRecord profile,
) {
  return <String, Object?>{
    r'$schema': konyakProfileSchemaUri,
    'schemaVersion': konyakProfileSchemaVersion,
    'id': profile.id.value,
    'name': profile.name.value,
    'profileVersion': profile.profileVersion.value,
    'summary': profile.summary.value,
    'platforms': profile.platforms
        .map((platform) => platform.value)
        .toList(growable: false),
    'windowsVersion': profile.windowsVersion.value,
    'managedProgramPath': profile.managedProgramPath.value,
    'installerResource': <String, Object?>{
      'kind': profile.installerResource.kind.value,
      'url': profile.installerResource.url.value,
      'sha256': profile.installerResource.sha256.value,
      'fileName': profile.installerResource.fileName.value,
    },
    ...profile.installerCompletion.match(
      () => const <String, Object?>{},
      (completion) => <String, Object?>{
        'installerCompletion': <String, Object?>{
          'ignoreChildExecutable': completion.ignoreChildExecutable.value,
        },
      },
    ),
    'preInstallActions': profile.preInstallActions
        .map(_canonicalPreInstallActionJson)
        .toList(growable: false),
    'runCompletionPolicy': profile.runCompletionPolicy.value,
    'compatibilityProfile': <String, Object?>{
      'id': profile.compatibilityProfile.id.value,
      'profileVersion': profile.compatibilityProfile.profileVersion.value,
      'childProcessRules': profile.compatibilityProfile.childProcessRules
          .map(
            (rule) => <String, Object?>{
              'executableSuffix': rule.executableSuffix.value,
              'appendArgumentsIfMissing': rule.appendArgumentsIfMissing.value,
            },
          )
          .toList(growable: false),
    },
  };
}

Map<String, Object?> _canonicalPreInstallActionJson(
  PreInstallActionRecord action,
) {
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
