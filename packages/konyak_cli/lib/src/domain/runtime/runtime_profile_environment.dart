import 'package:fpdart/fpdart.dart';

import 'host_environment.dart';

Option<String> runtimeProfileEnvironmentValue(
  HostEnvironment environment, {
  required String developmentKey,
  required String releaseKey,
}) {
  if (isDevelopmentRuntimeProfile(environment)) {
    return environment.nonEmptyValue(developmentKey);
  }

  return environment.nonEmptyValue(releaseKey);
}

String runtimeDistributionKind(
  HostEnvironment environment,
  String defaultKind,
) {
  if (isDevelopmentRuntimeProfile(environment)) {
    return 'development';
  }

  return defaultKind;
}

bool isDevelopmentRuntimeProfile(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_RUNTIME_PROFILE')
      .match(() => false, (profile) => profile == 'development');
}
