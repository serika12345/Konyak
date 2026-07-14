import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_catalog.dart';
import '../domain/program/program_profile_install_models.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/runtime_catalogs.dart';
import '../domain/shared/domain_value_objects.dart';
import '../repository/repository_interfaces.dart';

final class DefaultProgramProfileInstaller implements ProgramProfileInstaller {
  const DefaultProgramProfileInstaller({
    required this.installProfileCatalog,
    required this.runtimeCatalog,
    required this.bottleRepository,
    required this.winetricksVerbRepository,
    required this.programRunPlanner,
    required this.programRunner,
    required this.resourceFetcher,
    required this.managedProgramVerifier,
    this.progressSink = const NoopProgramProfileInstallProgressSink(),
  });

  final InstallProfileCatalog installProfileCatalog;
  final RuntimeCatalog runtimeCatalog;
  final BottleRepository bottleRepository;
  final WinetricksVerbRepository winetricksVerbRepository;
  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner programRunner;
  final ProfileInstallerResourceFetcher resourceFetcher;
  final ManagedProfileProgramVerifier managedProgramVerifier;
  final ProgramProfileInstallProgressSink progressSink;

  @override
  ProgramProfileInstaller withProgressSink(
    ProgramProfileInstallProgressSink progressSink,
  ) {
    return DefaultProgramProfileInstaller(
      installProfileCatalog: installProfileCatalog,
      runtimeCatalog: runtimeCatalog,
      bottleRepository: bottleRepository,
      winetricksVerbRepository: winetricksVerbRepository,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
      resourceFetcher: resourceFetcher,
      managedProgramVerifier: managedProgramVerifier,
      progressSink: progressSink,
    );
  }

  @override
  ProgramProfileInstallResult install(ProgramProfileInstallRequest request) {
    _started(ProgramProfileInstallStage.preflight);
    return installProfileCatalog.find(request.profileId).match(
      () => _failed(
        const ProgramProfileInstallFailed(
          stage: ProgramProfileInstallStage.preflight,
          code: 'installProfileNotFound',
          message: 'Install profile was not found.',
        ),
      ),
      (profile) {
        final platform = programRunPlanner.hostPlatform.name;
        if (!profile.platforms.any(
          (candidate) => candidate.value == platform,
        )) {
          return _failed(
            const ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.preflight,
              code: 'installProfilePlatformUnsupported',
              message: 'Install profile does not support the host platform.',
            ),
          );
        }

        final expectedRunnerKind = switch (programRunPlanner.hostPlatform) {
          KonyakHostPlatform.linux => 'wine',
          KonyakHostPlatform.macos => 'macosWine',
        };
        final hasInstalledRuntime = runtimeCatalog.listRuntimes().any(
          (runtime) =>
              runtime.platform.value == platform &&
              runtime.runnerKind.value == expectedRunnerKind &&
              runtime.isInstalled.getOrElse(() => false) &&
              runtime.libraryPath.isSome() &&
              runtime.executablePath.isSome() &&
              runtime.stack.match(() => false, (stack) => stack.isComplete),
        );
        if (!hasInstalledRuntime) {
          return _failed(
            const ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.preflight,
              code: 'installedRuntimeUnavailable',
              message:
                  'An installed runtime for the host platform is required.',
            ),
          );
        }

        return bottleRepository
            .findBottle(request.bottleId)
            .fold(
              (message) => _failed(
                ProgramProfileInstallFailed(
                  stage: ProgramProfileInstallStage.preflight,
                  code: 'bottleLookupFailed',
                  message: message,
                ),
              ),
              (bottle) => bottle.match(
                () => _failed(
                  const ProgramProfileInstallFailed(
                    stage: ProgramProfileInstallStage.preflight,
                    code: 'bottleNotFound',
                    message: 'Bottle was not found.',
                  ),
                ),
                (foundBottle) => _installIntoBottle(
                  request: request,
                  profile: profile,
                  bottle: foundBottle,
                ),
              ),
            );
      },
    );
  }

  ProgramProfileInstallResult _installIntoBottle({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
  }) {
    if (bottle.windowsVersion != profile.windowsVersion) {
      return _failed(
        const ProgramProfileInstallFailed(
          stage: ProgramProfileInstallStage.preflight,
          code: 'bottleWindowsVersionMismatch',
          message: 'Bottle Windows version does not match the install profile.',
        ),
      );
    }
    final verbList = winetricksVerbRepository.listVerbs();
    return switch (verbList) {
      WinetricksVerbListFailed(:final message) => _failed(
        ProgramProfileInstallFailed(
          stage: ProgramProfileInstallStage.preflight,
          code: 'winetricksVerbListFailed',
          message: message,
        ),
      ),
      WinetricksVerbListCompleted(:final categories) => () {
        final availableVerbs = categories
            .expand((category) => category.verbs)
            .map((verb) => verb.id)
            .toSet();
        for (final (index, verb) in profile.dependencyWinetricksVerbs.indexed) {
          if (!availableVerbs.contains(verb)) {
            return _failed(
              ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.preflight,
                code: 'dependencyWinetricksVerbUnavailable',
                message: 'A dependency winetricks verb is unavailable.',
                dependencyIndex: Option.of(index),
                dependencyVerb: Option.of(verb),
              ),
            );
          }
        }
        if (programRunPlanner
            .planInstaller(
              bottle: bottle,
              installerPath: ProgramPath(
                profile.installerResource.fileName.value,
              ),
            )
            .isNone()) {
          return _failed(
            const ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.preflight,
              code: 'installerPlanUnavailable',
              message: 'Installer resource type is not supported.',
            ),
          );
        }
        for (final (index, verb) in profile.dependencyWinetricksVerbs.indexed) {
          if (programRunPlanner
              .planWinetricksVerb(bottle: bottle, verb: verb)
              .isNone()) {
            return _failed(
              ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.preflight,
                code: 'dependencyInstallerPlanUnavailable',
                message: 'A dependency winetricks verb cannot be planned.',
                dependencyIndex: Option.of(index),
                dependencyVerb: Option.of(verb),
              ),
            );
          }
        }
        _completed(ProgramProfileInstallStage.preflight);
        return _fetchAndInstall(
          request: request,
          profile: profile,
          bottle: bottle,
        );
      }(),
    };
  }

  ProgramProfileInstallResult _fetchAndInstall({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
  }) {
    _started(ProgramProfileInstallStage.download);
    final fetchResult = resourceFetcher.fetch(profile.installerResource);
    return switch (fetchResult) {
      ProfileInstallerResourceDownloadFailed(:final message) => _failed(
        ProgramProfileInstallFailed(
          stage: ProgramProfileInstallStage.download,
          code: 'installerResourceDownloadFailed',
          message: message,
        ),
      ),
      ProfileInstallerResourceDigestMismatch() => () {
        _completed(ProgramProfileInstallStage.download);
        _started(ProgramProfileInstallStage.verification);
        return _failed(
          const ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.verification,
            code: 'installerResourceDigestMismatch',
            message: 'Installer resource SHA-256 digest did not match.',
          ),
        );
      }(),
      final ProfileInstallerResourceFetched fetched => () {
        _completed(ProgramProfileInstallStage.download);
        _started(ProgramProfileInstallStage.verification);
        _completed(ProgramProfileInstallStage.verification);
        return _runDependencies(
          request: request,
          profile: profile,
          bottle: bottle,
          resource: fetched,
        );
      }(),
    };
  }

  ProgramProfileInstallResult _releaseResourceThen({
    required ProfileInstallerResourceFetched resource,
    required ProgramProfileInstallResult Function() continuation,
  }) {
    _started(ProgramProfileInstallStage.resourceCleanup);
    return switch (resourceFetcher.release(resource)) {
      ProfileInstallerResourceReleased() => () {
        _completed(ProgramProfileInstallStage.resourceCleanup);
        return continuation();
      }(),
      ProfileInstallerResourceReleaseFailed(:final code, :final message) =>
        _failed(
          ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.resourceCleanup,
            code: code,
            message: message,
          ),
        ),
    };
  }

  ProgramProfileInstallResult _runInstaller({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
    required ProgramRunRequest plan,
    required ProfileInstallerResourceFetched resource,
  }) {
    final runResult = programRunner.run(plan);
    return switch (runResult) {
      ProgramRunFailed(:final message) => _releaseResourceThen(
        resource: resource,
        continuation: () => _failed(
          ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.installer,
            code: 'installerRunFailed',
            message: message,
          ),
        ),
      ),
      ProgramRunCompleted(:final processExitCode) when processExitCode != 0 =>
        _releaseResourceThen(
          resource: resource,
          continuation: () => _failed(
            ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.installer,
              code: 'installerExitNonZero',
              message: 'Installer exited with a non-zero status.',
              processExitCode: Option.of(processExitCode),
            ),
          ),
        ),
      ProgramRunCompleted() => () {
        _completed(ProgramProfileInstallStage.installer);
        return _releaseResourceThen(
          resource: resource,
          continuation: () {
            _started(ProgramProfileInstallStage.managedProgram);
            return _verifyAndPersist(
              request: request,
              profile: profile,
              bottle: bottle,
            );
          },
        );
      }(),
    };
  }

  ProgramProfileInstallResult _runDependencies({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
    required ProfileInstallerResourceFetched resource,
  }) {
    for (final (index, verb) in profile.dependencyWinetricksVerbs.indexed) {
      final dependencyIndex = Option.of(index);
      final dependencyVerb = Option.of(verb);
      _started(
        ProgramProfileInstallStage.dependency,
        dependencyIndex: dependencyIndex,
        dependencyVerb: dependencyVerb,
      );
      switch (_runDependency(bottle: bottle, index: index, verb: verb)) {
        case _DependencyInstallContinued():
          _completed(
            ProgramProfileInstallStage.dependency,
            dependencyIndex: dependencyIndex,
            dependencyVerb: dependencyVerb,
          );
          continue;
        case _DependencyInstallStopped(:final failure):
          return _releaseResourceThen(
            resource: resource,
            continuation: () => _failed(failure),
          );
      }
    }

    _started(ProgramProfileInstallStage.installer);
    return programRunPlanner
        .planInstaller(bottle: bottle, installerPath: resource.path)
        .match(
          () => _releaseResourceThen(
            resource: resource,
            continuation: () => _failed(
              const ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.installer,
                code: 'installerPlanUnavailable',
                message: 'Installer resource type is not supported.',
              ),
            ),
          ),
          (plan) => _runInstaller(
            request: request,
            profile: profile,
            bottle: bottle,
            plan: plan,
            resource: resource,
          ),
        );
  }

  _DependencyInstallStepResult _runDependency({
    required BottleRecord bottle,
    required int index,
    required WinetricksVerbId verb,
  }) {
    return programRunPlanner
        .planWinetricksVerb(bottle: bottle, verb: verb)
        .match(
          () => _DependencyInstallStopped(
            ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.dependency,
              code: 'dependencyInstallerPlanUnavailable',
              message: 'A dependency winetricks verb cannot be planned.',
              dependencyIndex: Option.of(index),
              dependencyVerb: Option.of(verb),
            ),
          ),
          (plan) => switch (programRunner.run(plan)) {
            ProgramRunFailed(:final message) => _DependencyInstallStopped(
              ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.dependency,
                code: 'dependencyInstallerRunFailed',
                message: message,
                dependencyIndex: Option.of(index),
                dependencyVerb: Option.of(verb),
              ),
            ),
            ProgramRunCompleted(:final processExitCode)
                when processExitCode != 0 =>
              _DependencyInstallStopped(
                ProgramProfileInstallFailed(
                  stage: ProgramProfileInstallStage.dependency,
                  code: 'dependencyInstallerExitNonZero',
                  message:
                      'A dependency installer exited with a non-zero status.',
                  dependencyIndex: Option.of(index),
                  dependencyVerb: Option.of(verb),
                  processExitCode: Option.of(processExitCode),
                ),
              ),
            ProgramRunCompleted() => const _DependencyInstallContinued(),
          },
        );
  }

  ProgramProfileInstallResult _verifyAndPersist({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
  }) {
    final verification = managedProgramVerifier.verify(
      bottle: bottle,
      managedProgramPath: profile.managedProgramPath,
    );
    return switch (verification) {
      ManagedProfileProgramVerificationFailed(:final code, :final message) =>
        _failed(
          ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.managedProgram,
            code: code,
            message: message,
          ),
        ),
      ManagedProfileProgramVerified() => () {
        _completed(ProgramProfileInstallStage.managedProgram);
        _started(ProgramProfileInstallStage.persistence);
        return switch (bottleRepository.applyProgramProfile(
          ProgramProfileApplyRequest(
            bottleId: request.bottleId,
            installProfile: profile,
            programPath: profile.managedProgramPath,
          ),
        )) {
          ProgramProfileUpdated(:final bottleId, :final profile) => () {
            _completed(ProgramProfileInstallStage.persistence);
            return ProgramProfileInstalled(
              bottleId: bottleId,
              profile: profile,
            );
          }(),
          ProgramProfileUpdateMissingBottle() => _failed(
            const ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.persistence,
              code: 'bottleNotFound',
              message: 'Bottle disappeared before profile persistence.',
            ),
          ),
          ProgramProfileUpdateProfileNotApplied() => _failed(
            const ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.persistence,
              code: 'programProfileNotApplied',
              message: 'Program profile metadata was not applied.',
            ),
          ),
          ProgramProfileUpdateFailed(:final message) => _failed(
            ProgramProfileInstallFailed(
              stage: ProgramProfileInstallStage.persistence,
              code: 'programProfilePersistenceFailed',
              message: message,
            ),
          ),
        };
      }(),
    };
  }

  void _started(
    ProgramProfileInstallStage stage, {
    Option<int> dependencyIndex = const Option.none(),
    Option<WinetricksVerbId> dependencyVerb = const Option.none(),
  }) {
    progressSink.report(
      ProgramProfileInstallStageStarted(
        stage: stage,
        dependencyIndex: dependencyIndex,
        dependencyVerb: dependencyVerb,
      ),
    );
  }

  void _completed(
    ProgramProfileInstallStage stage, {
    Option<int> dependencyIndex = const Option.none(),
    Option<WinetricksVerbId> dependencyVerb = const Option.none(),
  }) {
    progressSink.report(
      ProgramProfileInstallStageCompleted(
        stage: stage,
        dependencyIndex: dependencyIndex,
        dependencyVerb: dependencyVerb,
      ),
    );
  }

  ProgramProfileInstallFailed _failed(ProgramProfileInstallFailed failure) {
    progressSink.report(
      ProgramProfileInstallStageFailed(
        stage: failure.stage,
        code: failure.code,
        dependencyIndex: failure.dependencyIndex,
        dependencyVerb: failure.dependencyVerb,
      ),
    );
    return failure;
  }
}

sealed class _DependencyInstallStepResult {
  const _DependencyInstallStepResult();
}

final class _DependencyInstallContinued extends _DependencyInstallStepResult {
  const _DependencyInstallContinued();
}

final class _DependencyInstallStopped extends _DependencyInstallStepResult {
  const _DependencyInstallStopped(this.failure);

  final ProgramProfileInstallFailed failure;
}
