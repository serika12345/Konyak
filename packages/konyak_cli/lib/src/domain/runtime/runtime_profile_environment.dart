import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import 'host_environment.dart';

Option<String> runtimeProfileEnvironmentValue(
  HostEnvironment environment, {
  required ProgramEnvironmentVariableName developmentKey,
  required ProgramEnvironmentVariableName releaseKey,
}) {
  if (isDevelopmentRuntimeProfile(environment)) {
    return environment.nonEmptyValue(developmentKey.value);
  }

  return environment.nonEmptyValue(releaseKey.value);
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
