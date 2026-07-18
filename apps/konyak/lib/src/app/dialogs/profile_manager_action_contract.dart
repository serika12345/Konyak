import '../../cli/konyak_cli_program_result_types.dart';

typedef ProfileManagerActionExecutor =
    Future<ProfileManagerActionResult> Function(
      ProfileManagerActionRequest request,
    );
typedef ProfileManagerManifestValidator =
    Future<ProfileManagerManifestValidationResult> Function(
      ProfileManagerManifestValidationRequest request,
    );

sealed class ProfileManagerManifestValidationRequest {
  const ProfileManagerManifestValidationRequest();

  String get manifestJson;
}

final class ValidateEditedProfileManifest
    extends ProfileManagerManifestValidationRequest {
  const ValidateEditedProfileManifest({
    required this.profileId,
    required this.manifestJson,
  });

  final String profileId;
  @override
  final String manifestJson;
}

final class ValidateDuplicatedProfileManifest
    extends ProfileManagerManifestValidationRequest {
  const ValidateDuplicatedProfileManifest({required this.manifestJson});

  @override
  final String manifestJson;
}

sealed class ProfileManagerManifestValidationResult {
  const ProfileManagerManifestValidationResult();
}

final class ValidProfileManagerManifest
    extends ProfileManagerManifestValidationResult {
  const ValidProfileManagerManifest();
}

final class InvalidProfileManagerManifest
    extends ProfileManagerManifestValidationResult {
  const InvalidProfileManagerManifest(this.message);

  final String message;
}

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

  ProfileManagerActionFeedback get feedback;
  ProfileManagerActionDisposition get disposition;
}

final class UnchangedProfileManagerCatalog extends ProfileManagerActionResult {
  const UnchangedProfileManagerCatalog({
    this.feedback = const NoProfileManagerActionFeedback(),
    this.disposition = const CompletedProfileManagerAction(),
  });

  @override
  final ProfileManagerActionFeedback feedback;
  @override
  final ProfileManagerActionDisposition disposition;
}

final class ReloadedProfileManagerCatalog extends ProfileManagerActionResult {
  const ReloadedProfileManagerCatalog({
    required this.profiles,
    required this.selection,
    this.feedback = const NoProfileManagerActionFeedback(),
    this.disposition = const CompletedProfileManagerAction(),
  });

  final List<InstallProfileListItem> profiles;
  final ProfileManagerCatalogSelection selection;
  @override
  final ProfileManagerActionFeedback feedback;
  @override
  final ProfileManagerActionDisposition disposition;
}

sealed class ProfileManagerActionDisposition {
  const ProfileManagerActionDisposition();
}

final class CompletedProfileManagerAction
    extends ProfileManagerActionDisposition {
  const CompletedProfileManagerAction();
}

final class RejectedProfileManagerAction
    extends ProfileManagerActionDisposition {
  const RejectedProfileManagerAction();
}

sealed class ProfileManagerActionFeedback {
  const ProfileManagerActionFeedback();
}

final class NoProfileManagerActionFeedback
    extends ProfileManagerActionFeedback {
  const NoProfileManagerActionFeedback();
}

final class ShowProfileManagerActionFeedback
    extends ProfileManagerActionFeedback {
  const ShowProfileManagerActionFeedback(this.message);

  final String message;
}
