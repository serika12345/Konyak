part of 'konyak_cli_client.dart';

KonyakCliClient createDefaultKonyakCliClient({
  Map<String, String> environment = const <String, String>{},
  String dartExecutableDefine = const String.fromEnvironment(
    'KONYAK_DART_EXECUTABLE',
  ),
  String cliScriptDefine = const String.fromEnvironment('KONYAK_CLI_SCRIPT'),
  String cliExecutableDefine = const String.fromEnvironment(
    'KONYAK_CLI_EXECUTABLE',
  ),
  String appExecutableDefine = const String.fromEnvironment(
    'KONYAK_APP_EXECUTABLE',
  ),
  String runtimeProfileDefine = const String.fromEnvironment(
    'KONYAK_RUNTIME_PROFILE',
  ),
  String macosWineHomeDefine = const String.fromEnvironment(
    'KONYAK_MACOS_WINE_HOME',
  ),
  String linuxWineHomeDefine = const String.fromEnvironment(
    'KONYAK_LINUX_WINE_HOME',
  ),
  String linuxWineLibraryPathDefine = const String.fromEnvironment(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  ),
  String macosWineStackManifestDefine = const String.fromEnvironment(
    'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST',
  ),
  String linuxWineStackManifestDefine = const String.fromEnvironment(
    'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST',
  ),
  String macosDevRuntimePrepareScriptDefine = const String.fromEnvironment(
    'KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT',
  ),
  String bundleResourcesDefine = const String.fromEnvironment(
    'KONYAK_BUNDLE_RESOURCES',
  ),
  String repoRootDefine = const String.fromEnvironment('KONYAK_REPO_ROOT'),
  String flutterRootDefine = const String.fromEnvironment('FLUTTER_ROOT'),
  ProcessRunner processRunner = const DartIoProcessRunner(),
}) {
  final activeEnvironment = environment.isEmpty
      ? Platform.environment
      : environment;
  final launchConfig = _konyakCliLaunchConfig(
    environment: activeEnvironment,
    resolvedExecutable: Platform.resolvedExecutable,
    defines: _KonyakCliLaunchDefines(
      dartExecutable: dartExecutableDefine,
      cliScript: cliScriptDefine,
      cliExecutable: cliExecutableDefine,
      appExecutable: appExecutableDefine,
      runtimeProfile: runtimeProfileDefine,
      macosWineHome: macosWineHomeDefine,
      linuxWineHome: linuxWineHomeDefine,
      linuxWineLibraryPath: linuxWineLibraryPathDefine,
      macosWineStackManifest: macosWineStackManifestDefine,
      linuxWineStackManifest: linuxWineStackManifestDefine,
      macosDevRuntimePrepareScript: macosDevRuntimePrepareScriptDefine,
      bundleResources: bundleResourcesDefine,
      repoRoot: repoRootDefine,
      flutterRoot: flutterRootDefine,
    ),
  );

  return KonyakCliClient(
    executable: launchConfig.executable,
    environment: launchConfig.environment,
    baseArguments: launchConfig.baseArguments,
    workingDirectory: launchConfig.workingDirectory,
    processRunner: processRunner,
  );
}
