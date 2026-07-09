import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_catalog.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/shared/domain_value_objects.dart';
import '../repository/repository_interfaces.dart';
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

  final installRequest = parseJsonProgramProfileInstallRequest(arguments);
  if (installRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    final runner = context.programRunner;
    if (runner == null) {
      return programRunnerUnavailableError();
    }

    return findInstallProfile(installRequest.profileId).match(
      () => installProfileNotFoundError(installRequest.profileId),
      (profile) => installProfileJsonResult(
        request: installRequest,
        profile: profile,
        repository: repository,
        programRunPlanner: context.programRunPlanner,
        programRunner: runner,
      ),
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

CliResult installProfileJsonResult({
  required ProgramProfileInstallCliRequest request,
  required InstallProfileRecord profile,
  required BottleRepository repository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner programRunner,
}) {
  if (!installProfileSupportsHostPlatform(profile, programRunPlanner)) {
    return jsonError(
      exitCode: 65,
      code: 'installProfileUnsupportedPlatform',
      message: 'Install profile is not supported on this platform.',
      extra: <String, Object?>{
        'profileId': profile.id.value,
        'hostPlatform': hostPlatformName(programRunPlanner.hostPlatform),
      },
    );
  }

  return foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final dependencyResult = runInstallProfileDependencySteps(
        profile: profile,
        bottle: bottle,
        programRunPlanner: programRunPlanner,
        programRunner: programRunner,
      );
      return switch (dependencyResult) {
        InstallProfileStepsFailed(:final result) => result,
        InstallProfileStepsCompleted(:final steps) =>
          runInstallProfileInstaller(
            request: request,
            profile: profile,
            bottle: bottle,
            repository: repository,
            programRunPlanner: programRunPlanner,
            programRunner: programRunner,
            dependencySteps: steps,
          ),
      };
    },
  );
}

bool installProfileSupportsHostPlatform(
  InstallProfileRecord profile,
  ProgramRunPlanner programRunPlanner,
) {
  final platformName = hostPlatformName(programRunPlanner.hostPlatform);
  return profile.platforms.any((platform) => platform.value == platformName);
}

String hostPlatformName(KonyakHostPlatform hostPlatform) {
  return switch (hostPlatform) {
    KonyakHostPlatform.linux => 'linux',
    KonyakHostPlatform.macos => 'macos',
  };
}

sealed class InstallProfileStepsResult {
  const InstallProfileStepsResult();
}

final class InstallProfileStepsCompleted extends InstallProfileStepsResult {
  const InstallProfileStepsCompleted(this.steps);

  final List<Map<String, Object?>> steps;
}

final class InstallProfileStepsFailed extends InstallProfileStepsResult {
  const InstallProfileStepsFailed(this.result);

  final CliResult result;
}

InstallProfileStepsResult runInstallProfileDependencySteps({
  required InstallProfileRecord profile,
  required BottleRecord bottle,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner programRunner,
}) {
  final steps = <Map<String, Object?>>[];
  for (final verb in profile.dependencyWinetricksVerbs) {
    final request = programRunPlanner.planWinetricksVerb(
      bottle: bottle,
      verb: verb,
    );
    final stepResult = request.match(
      () => InstallProfileStepsFailed(
        installProfileStepUnsupportedError(
          profileId: profile.id,
          stepKind: 'winetricks',
          stepId: verb.value,
        ),
      ),
      (value) {
        final stepResult = runInstallProfileStep(
          profileId: profile.id,
          stepKind: 'winetricks',
          stepId: verb.value,
          request: value,
          programRunner: programRunner,
        );
        switch (stepResult) {
          case InstallProfileStepFailed(:final result):
            return InstallProfileStepsFailed(result);
          case InstallProfileStepCompleted(:final step):
            steps.add(step);
            return null;
        }
      },
    );
    if (stepResult is InstallProfileStepsFailed) {
      return stepResult;
    }
  }

  return InstallProfileStepsCompleted(List.unmodifiable(steps));
}

CliResult runInstallProfileInstaller({
  required ProgramProfileInstallCliRequest request,
  required InstallProfileRecord profile,
  required BottleRecord bottle,
  required BottleRepository repository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner programRunner,
  required List<Map<String, Object?>> dependencySteps,
}) {
  final installerRequest = programRunPlanner.plan(
    bottle: bottle,
    programPath: request.installerPath,
  );

  return installerRequest.match(
    () => installProfileStepUnsupportedError(
      profileId: profile.id,
      stepKind: 'installer',
      stepId: request.installerPath.value,
    ),
    (installerRequest) {
      return switch (runInstallProfileStep(
        profileId: profile.id,
        stepKind: 'installer',
        stepId: request.installerPath.value,
        request: installerRequest,
        programRunner: programRunner,
      )) {
        InstallProfileStepFailed(:final result) => result,
        InstallProfileStepCompleted(:final step) =>
          installProfileApplyMetadataJsonResult(
            bottleId: request.bottleId,
            profile: profile,
            installerPath: request.installerPath,
            repository: repository,
            steps: List.unmodifiable(<Map<String, Object?>>[
              ...dependencySteps,
              step,
            ]),
          ),
      };
    },
  );
}

sealed class InstallProfileStepResult {
  const InstallProfileStepResult();
}

final class InstallProfileStepCompleted extends InstallProfileStepResult {
  const InstallProfileStepCompleted(this.step);

  final Map<String, Object?> step;
}

final class InstallProfileStepFailed extends InstallProfileStepResult {
  const InstallProfileStepFailed(this.result);

  final CliResult result;
}

InstallProfileStepResult runInstallProfileStep({
  required ProfileId profileId,
  required String stepKind,
  required String stepId,
  required ProgramRunRequest request,
  required ProgramRunner programRunner,
}) {
  return switch (programRunner.run(request)) {
    ProgramRunCompleted(:final processExitCode) when processExitCode == 0 =>
      InstallProfileStepCompleted(
        installProfileStepJson(
          kind: stepKind,
          id: stepId,
          request: request,
          processExitCode: processExitCode,
        ),
      ),
    ProgramRunCompleted(:final processExitCode) => InstallProfileStepFailed(
      installProfileStepFailedError(
        profileId: profileId,
        stepKind: stepKind,
        stepId: stepId,
        request: request,
        processExitCode: processExitCode,
      ),
    ),
    ProgramRunFailed(:final message) => InstallProfileStepFailed(
      installProfileStepFailedError(
        profileId: profileId,
        stepKind: stepKind,
        stepId: stepId,
        request: request,
        message: message,
      ),
    ),
  };
}

Map<String, Object?> installProfileStepJson({
  required String kind,
  required String id,
  required ProgramRunRequest request,
  required int processExitCode,
}) {
  return <String, Object?>{
    'kind': kind,
    'id': id,
    'runnerKind': request.runnerKind.value,
    'argv': request.argv,
    'logPath': request.logPath.value,
    'processExitCode': processExitCode,
  };
}

CliResult installProfileApplyMetadataJsonResult({
  required BottleId bottleId,
  required InstallProfileRecord profile,
  required ProgramPath installerPath,
  required BottleRepository repository,
  required List<Map<String, Object?>> steps,
}) {
  final updateResult = repository.applyProgramProfile(
    ProgramProfileApplyRequest(
      bottleId: bottleId,
      installProfile: profile,
      programPath: profile.managedProgramPath,
    ),
  );

  return switch (updateResult) {
    ProgramProfileUpdated(profile: final programProfile) => jsonSuccess(
      <String, Object?>{
        'installedProfile': <String, Object?>{
          'bottleId': bottleId.value,
          'profileId': programProfile.profileId.value,
          'profileVersion': programProfile.profileVersion.value,
          'installerSource': <String, Object?>{
            'kind': 'localFile',
            'path': installerPath.value,
          },
          'steps': steps,
          'programProfile': programProfileJson(
            bottleId: bottleId.value,
            profile: programProfile,
          ),
        },
      },
    ),
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

CliResult installProfileStepUnsupportedError({
  required ProfileId profileId,
  required String stepKind,
  required String stepId,
}) {
  return jsonError(
    exitCode: 65,
    code: 'installProfileStepUnsupported',
    message: 'Install profile step is not supported.',
    extra: <String, Object?>{
      'profileId': profileId.value,
      'stepKind': stepKind,
      'stepId': stepId,
    },
  );
}

CliResult installProfileStepFailedError({
  required ProfileId profileId,
  required String stepKind,
  required String stepId,
  required ProgramRunRequest request,
  int? processExitCode,
  String? message,
}) {
  final processExitCodeJson = processExitCode == null
      ? const <String, Object?>{}
      : <String, Object?>{'processExitCode': processExitCode};
  return jsonError(
    exitCode: 75,
    code: 'installProfileStepFailed',
    message:
        message ?? 'Install profile step exited with code $processExitCode.',
    extra: <String, Object?>{
      'profileId': profileId.value,
      'stepKind': stepKind,
      'stepId': stepId,
      'runnerKind': request.runnerKind.value,
      'argv': request.argv,
      ...processExitCodeJson,
    },
  );
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

CliResult programRunnerUnavailableError() {
  return unavailableJsonError(
    code: 'programRunnerUnavailable',
    subject: 'Program runner',
  );
}
