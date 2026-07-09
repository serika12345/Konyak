import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_catalog.dart';
import '../domain/shared/domain_value_objects.dart';
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
      'installProfiles': installProfileCatalog
          .map(installProfileJson)
          .toList(growable: false),
    });
  }

  final inspectRequest = parseJsonInstallProfileInspectCliRequest(arguments);
  if (inspectRequest != null) {
    return findInstallProfile(inspectRequest.profileId).match(
      () => installProfileNotFoundError(inspectRequest.profileId),
      (profile) => jsonSuccess(<String, Object?>{
        'installProfile': installProfileJson(profile),
      }),
    );
  }

  final applyRequest = parseJsonProgramProfileApplyRequest(arguments);
  if (applyRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return findInstallProfile(applyRequest.profileId).match(
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

    return findInstallProfile(repairRequest.profileId).match(
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
