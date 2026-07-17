import '../../cli/konyak_cli_program_result_types.dart';

typedef ProfileManagerActionExecutor =
    Future<ProfileManagerActionResult> Function(
      ProfileManagerActionRequest request,
    );

sealed class ProfileManagerActionRequest {
  const ProfileManagerActionRequest();
}

final class ImportProfileManagerActionRequest
    extends ProfileManagerActionRequest {
  const ImportProfileManagerActionRequest({required this.sourcePath});

  final String sourcePath;
}

final class EditProfileManagerActionRequest
    extends ProfileManagerActionRequest {
  const EditProfileManagerActionRequest({
    required this.profileId,
    required this.profileName,
    required this.expectedDigest,
    required this.manifestJson,
  });

  final String profileId;
  final String profileName;
  final String expectedDigest;
  final String manifestJson;
}

final class DuplicateProfileManagerActionRequest
    extends ProfileManagerActionRequest {
  const DuplicateProfileManagerActionRequest({required this.manifestJson});

  final String manifestJson;
}

final class ExportProfileManagerActionRequest
    extends ProfileManagerActionRequest {
  const ExportProfileManagerActionRequest({
    required this.profileId,
    required this.profileName,
    required this.destinationPath,
  });

  final String profileId;
  final String profileName;
  final String destinationPath;
}

final class DeleteProfileManagerActionRequest
    extends ProfileManagerActionRequest {
  const DeleteProfileManagerActionRequest({
    required this.profileId,
    required this.profileName,
    required this.expectedDigest,
  });

  final String profileId;
  final String profileName;
  final String expectedDigest;
}

sealed class ProfileManagerCatalogSelection {
  const ProfileManagerCatalogSelection();
}

final class SelectProfileManagerCatalogProfile
    extends ProfileManagerCatalogSelection {
  const SelectProfileManagerCatalogProfile(this.profileId);

  final String profileId;
}

final class SelectFirstProfileManagerCatalogProfile
    extends ProfileManagerCatalogSelection {
  const SelectFirstProfileManagerCatalogProfile();
}

sealed class ProfileManagerActionResult {
  const ProfileManagerActionResult();
}

final class UnchangedProfileManagerCatalog extends ProfileManagerActionResult {
  const UnchangedProfileManagerCatalog();
}

final class ReloadedProfileManagerCatalog extends ProfileManagerActionResult {
  const ReloadedProfileManagerCatalog({
    required this.profiles,
    required this.selection,
  });

  final List<InstallProfileListItem> profiles;
  final ProfileManagerCatalogSelection selection;
}
