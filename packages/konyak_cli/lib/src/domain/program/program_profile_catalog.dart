import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import 'program_profile_models.dart';

abstract class InstallProfileCatalog {
  const InstallProfileCatalog._();

  factory InstallProfileCatalog(Iterable<InstallProfileRecord> profiles) =
      _EagerInstallProfileCatalog;

  factory InstallProfileCatalog.deferred(
    InstallProfileCatalog Function() loader,
  ) = _DeferredInstallProfileCatalog;

  IList<InstallProfileRecord> get profiles;

  Option<InstallProfileRecord> find(ProfileId profileId) {
    final matches = profiles
        .where((profile) => profile.id == profileId)
        .toList(growable: false);
    return matches.isEmpty ? const Option.none() : Option.of(matches.first);
  }
}

final class _EagerInstallProfileCatalog extends InstallProfileCatalog {
  _EagerInstallProfileCatalog(Iterable<InstallProfileRecord> profiles)
    : profiles = profiles.toIList(),
      super._() {
    final profileIds = this.profiles.map((profile) => profile.id).toSet();
    if (profileIds.length != this.profiles.length) {
      throw ArgumentError('Install profile catalog contains duplicate IDs.');
    }
  }

  @override
  final IList<InstallProfileRecord> profiles;
}

final class _DeferredInstallProfileCatalog extends InstallProfileCatalog {
  _DeferredInstallProfileCatalog(this._loader) : super._();

  final InstallProfileCatalog Function() _loader;
  late final InstallProfileCatalog _loadedCatalog = _loader();

  @override
  IList<InstallProfileRecord> get profiles => _loadedCatalog.profiles;
}

final class InstallProfileCatalogException implements Exception {
  const InstallProfileCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

ProgramProfileRecord programProfileFromInstallProfile({
  required InstallProfileRecord installProfile,
  required ProgramPath managedProgramPath,
}) {
  return ProgramProfileRecord(
    profileSchemaVersion: konyakProfileSchemaVersion,
    profileId: installProfile.id.value,
    profileVersion: installProfile.profileVersion.value,
    profileSourceKind: installProfile.sourceKind,
    profileSourceId: installProfile.sourceId.value,
    profileDigest: installProfile.manifestDigest.value,
    managedProgramPath: managedProgramPath.value,
    installerResource: installProfile.installerResource,
    compatibilityProfileId: installProfile.compatibilityProfile.id.value,
    compatibilityProfileVersion:
        installProfile.compatibilityProfile.profileVersion.value,
  );
}
