import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_catalog.dart';
import '../domain/program/program_profile_install_models.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_profiles.dart';
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
    required this.installerProgramRunner,
    required this.resourceFetcher,
    this.nativeDllInstaller = const UnsupportedNativeDllInstaller(),
    required this.managedProgramVerifier,
    this.progressSink = const NoopProgramProfileInstallProgressSink(),
  });

  final InstallProfileCatalog installProfileCatalog;
  final RuntimeCatalog runtimeCatalog;
  final BottleRepository bottleRepository;
  final WinetricksVerbRepository winetricksVerbRepository;
  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner programRunner;
  final AsyncProgramRunner installerProgramRunner;
  final ProfileInstallerResourceFetcher resourceFetcher;
  final NativeDllInstaller nativeDllInstaller;
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
      installerProgramRunner: installerProgramRunner,
      resourceFetcher: resourceFetcher,
      nativeDllInstaller: nativeDllInstaller,
      managedProgramVerifier: managedProgramVerifier,
      progressSink: progressSink,
    );
  }

  @override
  Future<ProgramProfileInstallResult> install(
    ProgramProfileInstallRequest request,
  ) {
    _started(ProgramProfileInstallStage.preflight);
    return installProfileCatalog
        .find(request.profileId)
        .match(
          () async {
            return _failed(
              const ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.preflight,
                code: 'installProfileNotFound',
                message: 'Install profile was not found.',
              ),
            );
          },
          (profile) async {
            final platform = programRunPlanner.hostPlatform.name;
            if (!profile.platforms.any(
              (candidate) => candidate.value == platform,
            )) {
              return _failed(
                const ProgramProfileInstallFailed(
                  stage: ProgramProfileInstallStage.preflight,
                  code: 'installProfilePlatformUnsupported',
                  message:
                      'Install profile does not support the host platform.',
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

            return bottleRepository.findBottle(request.bottleId).fold(
              (message) async {
                return _failed(
                  ProgramProfileInstallFailed(
                    stage: ProgramProfileInstallStage.preflight,
                    code: 'bottleLookupFailed',
                    message: message,
                  ),
                );
              },
              (bottle) => bottle.match(
                () async {
                  return _failed(
                    const ProgramProfileInstallFailed(
                      stage: ProgramProfileInstallStage.preflight,
                      code: 'bottleNotFound',
                      message: 'Bottle was not found.',
                    ),
                  );
                },
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

  Future<ProgramProfileInstallResult> _installIntoBottle({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
  }) async {
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
      WinetricksVerbListCompleted(:final categories) => await (() async {
        final availableVerbs = categories
            .expand((category) => category.verbs)
            .map((verb) => verb.id)
            .toSet();
        for (final (index, action) in profile.preInstallActions.indexed) {
          if (action is! WinetricksPreInstallAction) {
            continue;
          }
          final verb = action.verb;
          if (!availableVerbs.contains(verb)) {
            return _failed(
              ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.preflight,
                code: 'dependencyWinetricksVerbUnavailable',
                message: 'A dependency winetricks verb is unavailable.',
                actionIndex: Option.of(index),
                actionKind: Option.of(PreInstallActionKind.winetricks),
                actionId: Option.of(PreInstallActionId(verb.value)),
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
              compatibilityEnvironment:
                  installerCompatibilityEnvironmentForProfile(profile),
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
        for (final (index, action) in profile.preInstallActions.indexed) {
          if (action is! WinetricksPreInstallAction) {
            continue;
          }
          final verb = action.verb;
          if (programRunPlanner
              .planWinetricksVerb(bottle: bottle, verb: verb)
              .isNone()) {
            return _failed(
              ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.preflight,
                code: 'dependencyInstallerPlanUnavailable',
                message: 'A dependency winetricks verb cannot be planned.',
                actionIndex: Option.of(index),
                actionKind: Option.of(PreInstallActionKind.winetricks),
                actionId: Option.of(PreInstallActionId(verb.value)),
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
      })(),
    };
  }

  Future<ProgramProfileInstallResult> _fetchAndInstall({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
  }) {
    _started(ProgramProfileInstallStage.download);
    final requests = <_ProfileResourceRequest>[
      _ProfileResourceRequest(
        ProfileResourceFetchRequest.installer(profile.installerResource),
      ),
      ...profile.preInstallActions.indexed.expand<_ProfileResourceRequest>((
        entry,
      ) {
        final (index, action) = entry;
        return switch (action) {
          WinetricksPreInstallAction() => const <_ProfileResourceRequest>[],
          NativeDllPreInstallAction(:final resource) =>
            <_ProfileResourceRequest>[
              _ProfileResourceRequest(
                ProfileResourceFetchRequest.nativeDll(resource),
                actionIndex: Option.of(index),
                action: Option.of(action),
              ),
            ],
        };
      }),
    ];
    final fetched = <_FetchedProfileResource>[];
    for (final requestResource in requests) {
      switch (resourceFetcher.fetch(requestResource.resource)) {
        case ProfileInstallerResourceDownloadFailed(:final message):
          final failure = ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.download,
            code: 'profileResourceDownloadFailed',
            message: message,
            actionIndex: requestResource.actionIndex,
            actionKind: requestResource.action.map(preInstallActionKind),
            actionId: requestResource.action.map(preInstallActionId),
          );
          return Future.value(
            _releaseResourcesThen(
              resources: fetched.map((item) => item.fetched),
              continuation: () => _failed(failure),
            ),
          );
        case ProfileInstallerResourceDigestMismatch():
          _completed(ProgramProfileInstallStage.download);
          _started(ProgramProfileInstallStage.verification);
          final failure = ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.verification,
            code: 'profileResourceDigestMismatch',
            message: 'Profile resource SHA-256 digest did not match.',
            actionIndex: requestResource.actionIndex,
            actionKind: requestResource.action.map(preInstallActionKind),
            actionId: requestResource.action.map(preInstallActionId),
          );
          return Future.value(
            _releaseResourcesThen(
              resources: fetched.map((item) => item.fetched),
              continuation: () => _failed(failure),
            ),
          );
        case final ProfileInstallerResourceFetched resource:
          fetched.add(
            _FetchedProfileResource(
              fetched: resource,
              actionIndex: requestResource.actionIndex,
            ),
          );
      }
    }
    _completed(ProgramProfileInstallStage.download);
    _started(ProgramProfileInstallStage.verification);
    _completed(ProgramProfileInstallStage.verification);
    return _runPreInstallActions(
      request: request,
      profile: profile,
      bottle: bottle,
      resources: fetched,
    );
  }

  ProgramProfileInstallResult _releaseResourcesThen({
    required Iterable<ProfileInstallerResourceFetched> resources,
    required ProgramProfileInstallResult Function() continuation,
  }) {
    _started(ProgramProfileInstallStage.resourceCleanup);
    ProfileInstallerResourceReleaseFailed? firstFailure;
    resources.toList(growable: false).reversed.forEach((resource) {
      final result = resourceFetcher.release(resource);
      if (result case final ProfileInstallerResourceReleaseFailed failure) {
        firstFailure ??= failure;
      }
    });
    final failure = firstFailure;
    if (failure != null) {
      return _failed(
        ProgramProfileInstallFailed(
          stage: ProgramProfileInstallStage.resourceCleanup,
          code: failure.code,
          message: failure.message,
        ),
      );
    }
    _completed(ProgramProfileInstallStage.resourceCleanup);
    return continuation();
  }

  Future<ProgramProfileInstallResult> _runInstaller({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
    required ProgramRunRequest plan,
    required List<_FetchedProfileResource> resources,
  }) async {
    final runResult = await installerProgramRunner.run(plan);
    return switch (runResult) {
      ProgramRunFailed(:final message) => _releaseResourcesThen(
        resources: resources.map((item) => item.fetched),
        continuation: () => _failed(
          ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.installer,
            code: 'installerRunFailed',
            message: message,
          ),
        ),
      ),
      ProgramRunCompleted(:final processExitCode) when processExitCode != 0 =>
        _releaseResourcesThen(
          resources: resources.map((item) => item.fetched),
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
        return _releaseResourcesThen(
          resources: resources.map((item) => item.fetched),
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

  Future<ProgramProfileInstallResult> _runPreInstallActions({
    required ProgramProfileInstallRequest request,
    required InstallProfileRecord profile,
    required BottleRecord bottle,
    required List<_FetchedProfileResource> resources,
  }) async {
    for (final (index, action) in profile.preInstallActions.indexed) {
      final kind = preInstallActionKind(action);
      final id = preInstallActionId(action);
      _started(
        ProgramProfileInstallStage.preInstallAction,
        actionIndex: Option.of(index),
        actionKind: Option.of(kind),
        actionId: Option.of(id),
      );
      final step = switch (action) {
        WinetricksPreInstallAction(:final verb) => _runDependency(
          bottle: bottle,
          index: index,
          verb: verb,
        ),
        final NativeDllPreInstallAction nativeDll => _runNativeDllAction(
          bottle: bottle,
          index: index,
          action: nativeDll,
          resource: resources
              .singleWhere((item) => item.actionIndex == Option.of(index))
              .fetched,
        ),
      };
      switch (step) {
        case _DependencyInstallContinued():
          _completed(
            ProgramProfileInstallStage.preInstallAction,
            actionIndex: Option.of(index),
            actionKind: Option.of(kind),
            actionId: Option.of(id),
          );
          continue;
        case _DependencyInstallStopped(:final failure):
          return _releaseResourcesThen(
            resources: resources.map((item) => item.fetched),
            continuation: () => _failed(failure),
          );
      }
    }

    _started(ProgramProfileInstallStage.installer);
    final installerResource = resources.first.fetched;
    return programRunPlanner
        .planInstaller(
          bottle: bottle,
          installerPath: installerResource.path,
          compatibilityEnvironment: installerCompatibilityEnvironmentForProfile(
            profile,
          ),
        )
        .match<Future<ProgramProfileInstallResult>>(
          () async => _releaseResourcesThen(
            resources: resources.map((item) => item.fetched),
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
            resources: resources,
          ),
        );
  }

  _DependencyInstallStepResult _runNativeDllAction({
    required BottleRecord bottle,
    required int index,
    required NativeDllPreInstallAction action,
    required ProfileInstallerResourceFetched resource,
  }) {
    return switch (nativeDllInstaller.install(
      bottle: bottle,
      action: action,
      resourcePath: resource.path,
    )) {
      NativeDllInstalled() => const _DependencyInstallContinued(),
      NativeDllInstallFailed(:final code, :final message) =>
        _DependencyInstallStopped(
          ProgramProfileInstallFailed(
            stage: ProgramProfileInstallStage.preInstallAction,
            code: code,
            message: message,
            actionIndex: Option.of(index),
            actionKind: Option.of(PreInstallActionKind.nativeDll),
            actionId: Option.of(PreInstallActionId(action.componentId.value)),
          ),
        ),
    };
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
              stage: ProgramProfileInstallStage.preInstallAction,
              code: 'dependencyInstallerPlanUnavailable',
              message: 'A dependency winetricks verb cannot be planned.',
              actionIndex: Option.of(index),
              actionKind: Option.of(PreInstallActionKind.winetricks),
              actionId: Option.of(PreInstallActionId(verb.value)),
            ),
          ),
          (plan) => switch (programRunner.run(plan)) {
            ProgramRunFailed(:final message) => _DependencyInstallStopped(
              ProgramProfileInstallFailed(
                stage: ProgramProfileInstallStage.preInstallAction,
                code: 'dependencyInstallerRunFailed',
                message: message,
                actionIndex: Option.of(index),
                actionKind: Option.of(PreInstallActionKind.winetricks),
                actionId: Option.of(PreInstallActionId(verb.value)),
              ),
            ),
            ProgramRunCompleted(:final processExitCode)
                when processExitCode != 0 =>
              _DependencyInstallStopped(
                ProgramProfileInstallFailed(
                  stage: ProgramProfileInstallStage.preInstallAction,
                  code: 'dependencyInstallerExitNonZero',
                  message:
                      'A dependency installer exited with a non-zero status.',
                  actionIndex: Option.of(index),
                  actionKind: Option.of(PreInstallActionKind.winetricks),
                  actionId: Option.of(PreInstallActionId(verb.value)),
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
    Option<int> actionIndex = const Option.none(),
    Option<PreInstallActionKind> actionKind = const Option.none(),
    Option<PreInstallActionId> actionId = const Option.none(),
  }) {
    progressSink.report(
      ProgramProfileInstallStageStarted(
        stage: stage,
        actionIndex: actionIndex,
        actionKind: actionKind,
        actionId: actionId,
      ),
    );
  }

  void _completed(
    ProgramProfileInstallStage stage, {
    Option<int> actionIndex = const Option.none(),
    Option<PreInstallActionKind> actionKind = const Option.none(),
    Option<PreInstallActionId> actionId = const Option.none(),
  }) {
    progressSink.report(
      ProgramProfileInstallStageCompleted(
        stage: stage,
        actionIndex: actionIndex,
        actionKind: actionKind,
        actionId: actionId,
      ),
    );
  }

  ProgramProfileInstallFailed _failed(ProgramProfileInstallFailed failure) {
    progressSink.report(
      ProgramProfileInstallStageFailed(
        stage: failure.stage,
        code: failure.code,
        actionIndex: failure.actionIndex,
        actionKind: failure.actionKind,
        actionId: failure.actionId,
      ),
    );
    return failure;
  }
}

final class _ProfileResourceRequest {
  const _ProfileResourceRequest(
    this.resource, {
    this.actionIndex = const Option.none(),
    this.action = const Option.none(),
  });

  final ProfileResourceFetchRequest resource;
  final Option<int> actionIndex;
  final Option<PreInstallActionRecord> action;
}

final class _FetchedProfileResource {
  const _FetchedProfileResource({
    required this.fetched,
    required this.actionIndex,
  });

  final ProfileInstallerResourceFetched fetched;
  final Option<int> actionIndex;
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
