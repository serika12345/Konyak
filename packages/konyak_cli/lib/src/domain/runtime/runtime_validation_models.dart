import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../program/program_run_environment.dart';
import '../shared/domain_value_objects.dart';

part 'runtime_validation_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackComponentDefinition
    with _$RuntimeStackComponentDefinition {
  const factory RuntimeStackComponentDefinition({
    required RuntimeComponentId id,
    required RuntimeName name,
    required RuntimeRole role,
    required bool isRequired,
    required List<RuntimeRelativePath> relativePaths,
  }) = _RuntimeStackComponentDefinition;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeBackendDefinition with _$RuntimeBackendDefinition {
  const factory RuntimeBackendDefinition({
    required RuntimeBackendId id,
    required RuntimeName name,
    required RuntimeRole role,
    required List<RuntimeComponentId> componentIds,
  }) = _RuntimeBackendDefinition;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimePlatformSpec with _$RuntimePlatformSpec {
  const factory RuntimePlatformSpec({
    required RuntimeId runtimeId,
    required RuntimeName runtimeName,
    required RuntimePlatformName platform,
    required RuntimeArchitecture architecture,
    required RunnerKind runnerKind,
    required RuntimeStackId stackId,
    required RuntimeStackName stackName,
    required RuntimeRelativePath requiredExecutableRelativePath,
    required RuntimeArchivePath defaultArchiveFileName,
    required ProgramEnvironmentVariableName
    developmentSourceManifestEnvironmentKey,
    required ProgramEnvironmentVariableName releaseSourceManifestEnvironmentKey,
    required ProgramEnvironmentVariableName
    developmentSourceSignatureEnvironmentKey,
    required ProgramEnvironmentVariableName
    releaseSourceSignatureEnvironmentKey,
    required List<RuntimeStackComponentDefinition> componentDefinitions,
    @Default(<RuntimeBackendDefinition>[])
    List<RuntimeBackendDefinition> backendDefinitions,
    @Default(Option<RuntimeSourceManifestUrl>.none())
    Option<RuntimeSourceManifestUrl> defaultSourceManifestUrl,
    @Default(RuntimeLayoutNormalization.none)
    RuntimeLayoutNormalization layoutNormalization,
  }) = _RuntimePlatformSpec;
}

enum RuntimeLayoutNormalization { none, macosWineBundle }

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeValidationRecord with _$RuntimeValidationRecord {
  const RuntimeValidationRecord._();

  factory RuntimeValidationRecord({
    required RuntimeId runtimeId,
    required bool isValid,
    required Iterable<RuntimeValidationCheck> checks,
  }) {
    return RuntimeValidationRecord._validated(
      runtimeId: runtimeId,
      isValid: isValid,
      checks: List.unmodifiable(checks),
    );
  }

  const factory RuntimeValidationRecord._validated({
    required RuntimeId runtimeId,
    required bool isValid,
    required List<RuntimeValidationCheck> checks,
  }) = _RuntimeValidationRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeValidationCheck with _$RuntimeValidationCheck {
  const factory RuntimeValidationCheck({
    required String id,
    required String name,
    required bool isRequired,
    required bool isPassed,
    required String message,
  }) = _RuntimeValidationCheck;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeValidationResult with _$RuntimeValidationResult {
  const RuntimeValidationResult._();

  const factory RuntimeValidationResult.completed(
    RuntimeValidationRecord validation,
  ) = RuntimeValidationCompleted;

  const factory RuntimeValidationResult.failed(String message) =
      RuntimeValidationFailed;

  factory RuntimeValidationResult.runtimeNotFound(RuntimeId runtimeId) {
    return RuntimeValidationResult._runtimeNotFound(runtimeId);
  }

  const factory RuntimeValidationResult._runtimeNotFound(RuntimeId runtimeId) =
      RuntimeValidationRuntimeNotFound;
}

abstract interface class RuntimeValidator {
  RuntimeValidationResult validate(RuntimeId runtimeId);
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeExecutableProbeResult
    with _$RuntimeExecutableProbeResult {
  const factory RuntimeExecutableProbeResult({
    required int exitCode,
    required String stdout,
    required String stderr,
  }) = _RuntimeExecutableProbeResult;
}

abstract interface class RuntimeExecutableProbe {
  RuntimeExecutableProbeResult run({
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
    required ProgramRunEnvironment environment,
    required ProgramWorkingDirectoryPath workingDirectory,
  });
}
