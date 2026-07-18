import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_install_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/program_profile_catalog_io.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_program_mutation_parsers.dart';
import 'cli_program_profile_json.dart';
import 'cli_result_model.dart';

CliResult? handleProgramProfileCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final listRequest = parseJsonInstallProfileListCliRequest(arguments);
  if (listRequest != null) {
    return jsonSuccess(<String, Object?>{
      'installProfiles': context.installProfileCatalog.profiles
          .map(installProfileSummaryJson)
          .toList(growable: false),
      'issues': context.installProfileCatalog.issues
          .map(
            (issue) => <String, Object?>{
              'sourceId': issue.sourceId,
              'message': issue.message,
            },
          )
          .toList(growable: false),
    });
  }

  final inspectRequest = parseJsonInstallProfileInspectCliRequest(arguments);
  if (inspectRequest != null) {
    return context.installProfileCatalog
        .find(inspectRequest.profileId)
        .match(
          () => installProfileNotFoundError(inspectRequest.profileId),
          (profile) => jsonSuccess(<String, Object?>{
            'installProfile': <String, Object?>{
              ...installProfileJson(profile),
              'manifest': canonicalInstallProfileManifestJson(profile),
            },
          }),
        );
  }

  final validateRequest = parseJsonInstallProfileValidateCliRequest(arguments);
  if (validateRequest != null) {
    return _installProfileLibraryResult(
      context: context,
      operation: 'validate',
      execute: (library) => library.validateProfile(validateRequest.sourcePath),
    );
  }

  final importRequest = parseJsonInstallProfileImportCliRequest(arguments);
  if (importRequest != null) {
    return _installProfileLibraryResult(
      context: context,
      operation: 'import',
      execute: (library) => library.importProfile(importRequest.sourcePath),
    );
  }

  final updateRequest = parseJsonInstallProfileUpdateCliRequest(arguments);
  if (updateRequest != null) {
    return _installProfileLibraryResult(
      context: context,
      operation: 'update',
      execute: (library) => library.updateProfile(
        profileId: updateRequest.profileId,
        expectedDigest: updateRequest.expectedDigest,
        sourcePath: updateRequest.sourcePath,
      ),
    );
  }

  final exportRequest = parseJsonInstallProfileExportCliRequest(arguments);
  if (exportRequest != null) {
    return _installProfileLibraryResult(
      context: context,
      operation: 'export',
      execute: (library) => library.exportProfile(
        profileId: exportRequest.profileId,
        destinationPath: exportRequest.destinationPath,
      ),
    );
  }

  final deleteRequest = parseJsonInstallProfileDeleteCliRequest(arguments);
  if (deleteRequest != null) {
    return _installProfileLibraryResult(
      context: context,
      operation: 'delete',
      execute: (library) => library.deleteProfile(
        profileId: deleteRequest.profileId,
        expectedDigest: deleteRequest.expectedDigest,
      ),
    );
  }

  final applyRequest = parseJsonProgramProfileApplyRequest(arguments);
  if (applyRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return context.installProfileCatalog
        .find(applyRequest.profileId)
        .match(
          () => installProfileNotFoundError(applyRequest.profileId),
          (profile) => programProfileUpdateJsonResult(
            result: repository.applyProgramProfile(
              ProgramProfileApplyRequest(
                bottleId: applyRequest.bottleId,
                installProfile: profile,
                programPath: applyRequest.programPath,
              ),
            ),
          ),
        );
  }

  final repairRequest = parseJsonProgramProfileRepairRequest(arguments);
  if (repairRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return context.installProfileCatalog
        .find(repairRequest.profileId)
        .match(
          () => installProfileNotFoundError(repairRequest.profileId),
          (profile) => programProfileUpdateJsonResult(
            result: repository.repairProgramProfile(
              ProgramProfileRepairRequest(
                bottleId: repairRequest.bottleId,
                installProfile: profile,
              ),
            ),
          ),
        );
  }

  return null;
}

CliResult _installProfileLibraryResult({
  required CliCommandContext context,
  required String operation,
  required InstallProfileLibraryResult Function(InstallProfileLibrary library)
  execute,
}) {
  final library = context.installProfileLibrary;
  if (library == null) {
    return jsonError(
      exitCode: 69,
      code: 'installProfileLibraryUnavailable',
      message: 'The install profile library is unavailable.',
    );
  }
  return switch (execute(library)) {
    InstallProfileValidated(:final profile) ||
    InstallProfileImported(:final profile) ||
    InstallProfileUpdated(:final profile) => jsonSuccess(<String, Object?>{
      'installProfileMutation': <String, Object?>{
        'operation': operation,
        'installProfile': installProfileJson(profile),
      },
    }),
    InstallProfileExported(:final profile, :final path) => jsonSuccess(
      <String, Object?>{
        'installProfileMutation': <String, Object?>{
          'operation': operation,
          'installProfile': installProfileJson(profile),
          'path': path,
        },
      },
    ),
    InstallProfileDeleted(:final profileId, :final profileDigest) =>
      jsonSuccess(<String, Object?>{
        'installProfileMutation': <String, Object?>{
          'operation': operation,
          'profileId': profileId.value,
          'profileDigest': profileDigest.value,
        },
      }),
    InstallProfileLibraryFailure(:final code, :final message, :final issues) =>
      jsonError(
        exitCode: _installProfileLibraryExitCode(code),
        code: code.value,
        message: message,
        extra: <String, Object?>{
          if (issues.isNotEmpty)
            'validationErrors': issues
                .map(
                  (issue) => <String, Object?>{
                    'path': issue.path,
                    'message': issue.message,
                  },
                )
                .toList(growable: false),
        },
      ),
  };
}

int _installProfileLibraryExitCode(InstallProfileLibraryFailureCode code) {
  return switch (code) {
    InstallProfileLibraryFailureCode.invalidProfile => 65,
    InstallProfileLibraryFailureCode.profileNotFound => 66,
    InstallProfileLibraryFailureCode.profileConflict ||
    InstallProfileLibraryFailureCode.profileModified => 73,
    InstallProfileLibraryFailureCode.profileIoFailure => 74,
    InstallProfileLibraryFailureCode.profileReadOnly => 77,
  };
}

sealed class ProgramProfileInstallCommandMatch {
  const ProgramProfileInstallCommandMatch();
}

final class ProgramProfileInstallCommandNotMatched
    extends ProgramProfileInstallCommandMatch {
  const ProgramProfileInstallCommandNotMatched();
}

final class ProgramProfileInstallCommandMatched
    extends ProgramProfileInstallCommandMatch {
  const ProgramProfileInstallCommandMatched(this.result);

  final CliResult result;
}

Future<ProgramProfileInstallCommandMatch> handleProgramProfileInstallCommand(
  List<String> arguments,
  CliCommandContext context,
) async {
  final installRequest = parseJsonProgramProfileInstallRequest(arguments);
  if (installRequest == null) {
    return const ProgramProfileInstallCommandNotMatched();
  }

  final installer = context.programProfileInstaller;
  if (installer == null) {
    return ProgramProfileInstallCommandMatched(
      jsonError(
        exitCode: 69,
        code: 'programProfileInstallerUnavailable',
        message: 'Program profile installer is unavailable.',
      ),
    );
  }

  final progressSink = installRequest.emitProgress
      ? context.programProfileInstallProgressSink ??
            const NoopProgramProfileInstallProgressSink()
      : const NoopProgramProfileInstallProgressSink();
  final result = await installer
      .withProgressSink(progressSink)
      .install(
        ProgramProfileInstallRequest(
          profileId: installRequest.profileId,
          bottleId: installRequest.bottleId,
        ),
      );
  return ProgramProfileInstallCommandMatched(
    programProfileInstallJsonResult(request: installRequest, result: result),
  );
}

CliResult programProfileInstallJsonResult({
  required ProgramProfileInstallCliRequest request,
  required ProgramProfileInstallResult result,
}) {
  return switch (result) {
    ProgramProfileInstalled(:final bottleId, :final profile) => jsonSuccess(
      <String, Object?>{
        'programProfileInstall': <String, Object?>{
          'stage': ProgramProfileInstallStage.persistence.value,
          'programProfile': programProfileJson(
            bottleId: bottleId.value,
            profile: profile,
          ),
        },
      },
    ),
    ProgramProfileInstallFailed(
      :final stage,
      :final code,
      :final message,
      :final actionIndex,
      :final actionKind,
      :final actionId,
      :final processExitCode,
    ) =>
      jsonError(
        exitCode: 70,
        code: code,
        message: message,
        extra: <String, Object?>{
          'programProfileInstall': <String, Object?>{
            'profileId': request.profileId.value,
            'bottleId': request.bottleId.value,
            'stage': stage.value,
            ...actionIndex.match(
              () => const <String, Object?>{},
              (value) => <String, Object?>{'actionIndex': value},
            ),
            ...actionKind.match(
              () => const <String, Object?>{},
              (value) => <String, Object?>{'actionKind': value.value},
            ),
            ...actionId.match(
              () => const <String, Object?>{},
              (value) => <String, Object?>{'actionId': value.value},
            ),
            ...processExitCode.match(
              () => const <String, Object?>{},
              (value) => <String, Object?>{'processExitCode': value},
            ),
          },
        },
      ),
  };
}

CliResult programProfileUpdateJsonResult({
  required ProgramProfileUpdateResult result,
}) {
  return switch (result) {
    ProgramProfileUpdated(:final bottleId, :final profile) =>
      jsonSuccess(<String, Object?>{
        'programProfile': programProfileJson(
          bottleId: bottleId.value,
          profile: profile,
        ),
      }),
    ProgramProfileUpdateMissingBottle(:final bottleId) => bottleNotFoundError(
      bottleId.value,
    ),
    ProgramProfileUpdateProfileNotApplied(:final profileId) => jsonError(
      exitCode: 66,
      code: 'programProfileNotApplied',
      message: 'Program profile is not applied to the bottle.',
      extra: <String, Object?>{'profileId': profileId.value},
    ),
    ProgramProfileUpdateFailed(:final message) =>
      bottleRepositoryFailureJsonResult(message),
  };
}

CliResult installProfileNotFoundError(ProfileId profileId) {
  return jsonError(
    exitCode: 66,
    code: 'installProfileNotFound',
    message: 'Install profile was not found.',
    extra: <String, Object?>{'profileId': profileId.value},
  );
}
