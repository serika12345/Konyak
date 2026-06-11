part of '../../../konyak_cli.dart';

class _RuntimeStackComponentDefinition {
  const _RuntimeStackComponentDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required this.relativePaths,
  });

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final List<List<String>> relativePaths;
}

class _RuntimeBackendDefinition {
  const _RuntimeBackendDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.componentIds,
  });

  final String id;
  final String name;
  final String role;
  final List<String> componentIds;
}

class _RuntimePlatformSpec {
  const _RuntimePlatformSpec({
    required this.runtimeId,
    required this.runtimeName,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.stackId,
    required this.stackName,
    required this.requiredExecutableRelativePath,
    required this.defaultArchiveFileName,
    required this.developmentSourceManifestEnvironmentKey,
    required this.releaseSourceManifestEnvironmentKey,
    required this.developmentSourceSignatureEnvironmentKey,
    required this.releaseSourceSignatureEnvironmentKey,
    required this.componentDefinitions,
    this.backendDefinitions = const <_RuntimeBackendDefinition>[],
    this.defaultSourceManifestUrl = const Option.none(),
    this.archiveUrlEnvironmentKey = const Option.none(),
    this.layoutNormalization = _RuntimeLayoutNormalization.none,
  });

  final String runtimeId;
  final String runtimeName;
  final String platform;
  final String architecture;
  final String runnerKind;
  final String stackId;
  final String stackName;
  final List<String> requiredExecutableRelativePath;
  final String defaultArchiveFileName;
  final String developmentSourceManifestEnvironmentKey;
  final String releaseSourceManifestEnvironmentKey;
  final String developmentSourceSignatureEnvironmentKey;
  final String releaseSourceSignatureEnvironmentKey;
  final List<_RuntimeStackComponentDefinition> componentDefinitions;
  final List<_RuntimeBackendDefinition> backendDefinitions;
  final Option<String> defaultSourceManifestUrl;
  final Option<String> archiveUrlEnvironmentKey;
  final _RuntimeLayoutNormalization layoutNormalization;
}

enum _RuntimeLayoutNormalization { none, macosWineBundle }

class RuntimeValidationRecord {
  RuntimeValidationRecord({
    required this.runtimeId,
    required this.isValid,
    required Iterable<RuntimeValidationCheck> checks,
  }) : checks = List.unmodifiable(checks);

  final String runtimeId;
  final bool isValid;
  final List<RuntimeValidationCheck> checks;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'isValid': isValid,
      'checks': checks.map((check) => check.toJson()).toList(growable: false),
    };
  }
}

class RuntimeValidationCheck {
  const RuntimeValidationCheck({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isPassed,
    required this.message,
  });

  final String id;
  final String name;
  final bool isRequired;
  final bool isPassed;
  final String message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'isRequired': isRequired,
      'isPassed': isPassed,
      'message': message,
    };
  }
}

sealed class RuntimeValidationResult {
  const RuntimeValidationResult();
}

class RuntimeValidationCompleted extends RuntimeValidationResult {
  const RuntimeValidationCompleted(this.validation);

  final RuntimeValidationRecord validation;
}

class RuntimeValidationFailed extends RuntimeValidationResult {
  const RuntimeValidationFailed(this.message);

  final String message;
}

class RuntimeValidationRuntimeNotFound extends RuntimeValidationResult {
  const RuntimeValidationRuntimeNotFound(this.runtimeId);

  final String runtimeId;
}

abstract interface class RuntimeValidator {
  RuntimeValidationResult validate(String runtimeId);
}

class RuntimeExecutableProbeResult {
  const RuntimeExecutableProbeResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class RuntimeExecutableProbe {
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required ProgramRunEnvironment environment,
    required String workingDirectory,
  });
}
