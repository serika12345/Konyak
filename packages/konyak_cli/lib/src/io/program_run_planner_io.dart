import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/shared/domain_value_objects.dart';
import 'platform_host_paths.dart';

ProgramRunPlanner currentProgramRunPlanner() {
  final hostPlatform = currentHostPlatform();
  return ProgramRunPlanner(
    hostPlatform: hostPlatform,
    environment: HostEnvironment(Platform.environment),
    macosMajorVersion: hostPlatform == KonyakHostPlatform.macos
        ? currentMacosMajorVersion()
        : const Option.none(),
  );
}

Option<MacosMajorVersion> currentMacosMajorVersion() {
  return macosMajorVersionFromOperatingSystemVersion(
    Platform.operatingSystemVersion,
  );
}
