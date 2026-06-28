import 'package:fpdart/fpdart.dart';

import '../domain/shared/domain_value_objects.dart';
import '../domain/update/update_records.dart';

Map<String, Object?> runtimeUpdateRecordJson(RuntimeUpdateRecord update) {
  return <String, Object?>{
    'runtimeId': update.runtimeId.value,
    'status': update.status.value,
    ..._updateJsonField('currentVersion', update.currentVersion),
    ..._updateJsonField('latestVersion', update.latestVersion),
    ..._updateJsonField('versionUrl', update.versionUrl),
    ..._updateJsonField('archiveUrl', update.archiveUrl),
    ..._updateJsonField('sourceManifestUrl', update.sourceManifestUrl),
    ..._updateJsonField(
      'sourceManifestSignatureUrl',
      update.sourceManifestSignatureUrl,
    ),
  };
}

Map<String, Object?> appUpdateRecordJson(AppUpdateRecord update) {
  return <String, Object?>{
    'appId': update.appId.value,
    'status': update.status.value,
    ..._updateJsonField('currentVersion', update.currentVersion),
    ..._updateJsonField('latestVersion', update.latestVersion),
    ..._updateJsonField('versionUrl', update.versionUrl),
    ..._updateJsonField('archiveUrl', update.archiveUrl),
    ..._updateJsonField('archiveSha256', update.archiveSha256),
  };
}

Map<String, Object?> appUpdateInstallRecordJson(
  AppUpdateInstallRecord install,
) {
  return <String, Object?>{
    'appId': install.appId.value,
    'status': install.status.value,
    ..._updateJsonField('currentVersion', install.currentVersion),
    ..._updateJsonField('installedVersion', install.installedVersion),
    ..._updateJsonField('archiveUrl', install.archiveUrl),
    ..._updateJsonField('archiveSha256', install.archiveSha256),
    ..._updateJsonField('installPath', install.installPath),
  };
}

Map<String, Object?> _updateJsonField(
  String key,
  Option<StringDomainValueObject> value,
) {
  return value.match(
    () => const <String, Object?>{},
    (item) => <String, Object?>{key: item.value},
  );
}
