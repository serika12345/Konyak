part of '../konyak_cli.dart';

String? _runtimeProfileEnvironmentValue(
  Map<String, String> environment, {
  required String developmentKey,
  required String releaseKey,
}) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return _nonEmptyEnvironmentValue(environment, developmentKey);
  }

  return _nonEmptyEnvironmentValue(environment, releaseKey);
}

String _runtimeDistributionKind(
  Map<String, String> environment,
  String defaultKind,
) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return 'development';
  }

  return defaultKind;
}

bool _isDevelopmentRuntimeProfile(Map<String, String> environment) {
  return _nonEmptyEnvironmentValue(environment, 'KONYAK_RUNTIME_PROFILE') ==
      'development';
}
