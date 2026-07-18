import 'dart:convert';

import 'konyak_cli_program_result_types.dart';

sealed class InstallProfileManifestDuplicationResult {
  const InstallProfileManifestDuplicationResult();
}

final class DuplicatedInstallProfileManifest
    extends InstallProfileManifestDuplicationResult {
  const DuplicatedInstallProfileManifest(this.manifestJson);

  final String manifestJson;
}

final class InvalidInstallProfileManifestForDuplication
    extends InstallProfileManifestDuplicationResult {
  const InvalidInstallProfileManifestForDuplication(this.message);

  final String message;
}

InstallProfileManifestDuplicationResult duplicateInstallProfileManifest(
  InstallProfileDetails profile,
) {
  try {
    final decoded = jsonDecode(profile.manifestJson);
    if (decoded is! Map<String, Object?>) {
      return const InvalidInstallProfileManifestForDuplication(
        'The canonical profile manifest is not a JSON object.',
      );
    }
    final compatibilityProfile = decoded['compatibilityProfile'];
    if (compatibilityProfile is! Map<String, Object?>) {
      return const InvalidInstallProfileManifestForDuplication(
        'The canonical profile manifest has no compatibility profile.',
      );
    }

    final copyId = '${profile.id}-copy';
    return DuplicatedInstallProfileManifest(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        ...decoded,
        'id': copyId,
        'name': '${profile.name} Copy',
        'profileVersion': 1,
        'compatibilityProfile': <String, Object?>{
          ...compatibilityProfile,
          'id': copyId,
          'profileVersion': 1,
        },
      }),
    );
  } on FormatException catch (error) {
    return InvalidInstallProfileManifestForDuplication(error.message);
  }
}
