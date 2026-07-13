import 'dart:io';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_profile_install_models.dart';
import '../domain/shared/domain_helpers.dart';
import '../domain/shared/domain_value_objects.dart';

final class DartIoManagedProfileProgramVerifier
    implements ManagedProfileProgramVerifier {
  const DartIoManagedProfileProgramVerifier();

  @override
  ManagedProfileProgramVerificationResult verify({
    required BottleRecord bottle,
    required ProgramPath managedProgramPath,
  }) {
    final components = _managedCDriveComponents(managedProgramPath.value);
    if (components == null) {
      return const ManagedProfileProgramVerificationFailed(
        code: 'managedProgramPathInvalid',
        message: 'Managed program path is not a safe absolute C-drive path.',
      );
    }

    final driveCRoot = Directory(
      domainJoinPath(bottle.path.value, const <String>['drive_c']),
    );
    final candidate = File(domainJoinPath(driveCRoot.path, components));
    try {
      if (!driveCRoot.existsSync() ||
          FileSystemEntity.typeSync(candidate.path, followLinks: false) ==
              FileSystemEntityType.notFound) {
        return const ManagedProfileProgramVerificationFailed(
          code: 'managedProgramMissing',
          message: 'Managed program executable does not exist.',
        );
      }

      final realBottleRoot = Directory(
        bottle.path.value,
      ).resolveSymbolicLinksSync();
      final realDriveCRoot = driveCRoot.resolveSymbolicLinksSync();
      final realCandidate = candidate.resolveSymbolicLinksSync();
      if (!isPathWithinRoot(path: realDriveCRoot, root: realBottleRoot) ||
          !isPathWithinRoot(path: realCandidate, root: realDriveCRoot)) {
        return const ManagedProfileProgramVerificationFailed(
          code: 'managedProgramOutsideBottle',
          message: 'Managed program executable resolves outside drive_c.',
        );
      }

      if (FileStat.statSync(realCandidate).type != FileSystemEntityType.file) {
        return const ManagedProfileProgramVerificationFailed(
          code: 'managedProgramNotRegularFile',
          message: 'Managed program executable is not a regular file.',
        );
      }

      return ManagedProfileProgramVerified(ProgramPath(realCandidate));
    } on FileSystemException catch (error) {
      return ManagedProfileProgramVerificationFailed(
        code: 'managedProgramVerificationFailed',
        message: error.message,
      );
    }
  }
}

List<String>? _managedCDriveComponents(String value) {
  if (!RegExp(r'^[Cc]:[\\/]').hasMatch(value) || value.length < 4) {
    return null;
  }
  final components = value.substring(3).split(RegExp(r'[\\/]'));
  if (components.isEmpty ||
      components.any(
        (component) =>
            component.isEmpty || component == '.' || component == '..',
      )) {
    return null;
  }
  return List<String>.unmodifiable(components);
}
