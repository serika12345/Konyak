part of '../../konyak_cli.dart';

ProgramRunPlanner currentProgramRunPlanner() {
  final hostPlatform = _currentHostPlatform();
  return ProgramRunPlanner(
    hostPlatform: hostPlatform,
    environment: HostEnvironment(Platform.environment),
    macosMajorVersion: hostPlatform == KonyakHostPlatform.macos
        ? _currentMacosMajorVersion()
        : const Option.none(),
  );
}

Option<int> _currentMacosMajorVersion() {
  return _macosMajorVersionFromOperatingSystemVersion(
    Platform.operatingSystemVersion,
  );
}
