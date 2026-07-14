import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_install_models.dart';
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
      'installProfiles': context.installProfileCatalog.profiles
          .map(installProfileSummaryJson)
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
