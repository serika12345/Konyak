part of '../../../konyak_cli.dart';

Option<String> _runtimeProfileEnvironmentValue(
  HostEnvironment environment, {
  required String developmentKey,
  required String releaseKey,
}) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return Option.fromNullable(environment.nonEmptyValue(developmentKey));
  }

  return Option.fromNullable(environment.nonEmptyValue(releaseKey));
}

String _runtimeDistributionKind(
  HostEnvironment environment,
  String defaultKind,
) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return 'development';
  }

  return defaultKind;
}

bool _isDevelopmentRuntimeProfile(HostEnvironment environment) {
  return environment.nonEmptyValue('KONYAK_RUNTIME_PROFILE') == 'development';
}
