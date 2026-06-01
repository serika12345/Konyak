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
  final runtimeEnvironment = _runtimeEnvironmentOverrides(
    activeEnvironment,
    repoRootDefine: repoRootDefine,
    runtimeProfileDefine: runtimeProfileDefine,
    macosWineHomeDefine: macosWineHomeDefine,
    linuxWineHomeDefine: linuxWineHomeDefine,
    linuxWineLibraryPathDefine: linuxWineLibraryPathDefine,
    macosWineStackManifestDefine: macosWineStackManifestDefine,
    linuxWineStackManifestDefine: linuxWineStackManifestDefine,
    macosDevRuntimePrepareScriptDefine: macosDevRuntimePrepareScriptDefine,
  );

  final cliExecutable = _resolvePackagedCliExecutable(
    _firstNonEmpty(
      cliExecutableDefine,
      activeEnvironment['KONYAK_CLI_EXECUTABLE'],
    ),
    activeEnvironment,
    appExecutableDefine: appExecutableDefine,
    bundleResourcesDefine: bundleResourcesDefine,
  );
  if (cliExecutable != null) {
    return KonyakCliClient(
      executable: cliExecutable,
      environment: runtimeEnvironment,
      processRunner: processRunner,
    );
  }

  final cliScriptPath = _resolveCliScriptPath(
    activeEnvironment,
    cliScriptDefine: cliScriptDefine,
    repoRootDefine: repoRootDefine,
  );
  final cliScriptWorkingDirectory = _resolveCliScriptWorkingDirectory(
    cliScriptPath,
  );
  final cliScriptRunTarget = _resolveCliScriptRunTarget(cliScriptPath);

  return KonyakCliClient(
    executable: _resolveDartExecutable(
      activeEnvironment,
      dartExecutableDefine: dartExecutableDefine,
      flutterRootDefine: flutterRootDefine,
    ),
    environment: runtimeEnvironment,
    baseArguments:
        cliScriptWorkingDirectory == null || cliScriptRunTarget == null
        ? <String>[cliScriptPath]
        : <String>['run', cliScriptRunTarget],
    workingDirectory: cliScriptWorkingDirectory,
    processRunner: processRunner,
  );
}

const _bundleResourcesToken = '__KONYAK_BUNDLE_RESOURCES__';

String? _resolvePackagedCliExecutable(
  String? executable,
  Map<String, String> environment, {
  required String appExecutableDefine,
  required String bundleResourcesDefine,
}) {
  if (executable == null || !executable.contains(_bundleResourcesToken)) {
    return executable;
  }

  final bundleResources = _firstNonEmpty(
    bundleResourcesDefine,
    environment['KONYAK_BUNDLE_RESOURCES'],
    _bundleResourcesPathFromAppExecutable(
      _firstNonEmpty(
        appExecutableDefine,
        environment['KONYAK_APP_EXECUTABLE'],
        Platform.resolvedExecutable,
      ),
    ),
  );
  if (bundleResources == null) {
    return executable;
  }

  return executable.replaceAll(_bundleResourcesToken, bundleResources);
}

String? _bundleResourcesPathFromAppExecutable(String? executable) {
  if (executable == null || executable.trim().isEmpty) {
    return null;
  }

  final normalized = executable.replaceAll('\\', '/');
  final marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  final bundleRootEnd = markerIndex + '.app/Contents/'.length;
  return '${normalized.substring(0, bundleRootEnd)}Resources';
}

String _resolveDartExecutable(
  Map<String, String> environment, {
  required String dartExecutableDefine,
  required String flutterRootDefine,
}) {
  final override = _firstNonEmpty(
    dartExecutableDefine,
    environment['KONYAK_DART_EXECUTABLE'],
  );
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final flutterRoot = _firstNonEmpty(
    flutterRootDefine,
    environment['FLUTTER_ROOT'],
  );
  if (flutterRoot != null && flutterRoot.trim().isNotEmpty) {
    return _joinPath(flutterRoot, const ['bin', 'dart']);
  }

  return 'dart';
}

String _resolveCliScriptPath(
  Map<String, String> environment, {
  required String cliScriptDefine,
  required String repoRootDefine,
}) {
  final override = _firstNonEmpty(
    cliScriptDefine,
    environment['KONYAK_CLI_SCRIPT'],
  );
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final repoRoot = _firstNonEmpty(
    repoRootDefine,
    environment['KONYAK_REPO_ROOT'],
  );
  if (repoRoot != null && repoRoot.trim().isNotEmpty) {
    return _joinPath(repoRoot, const [
      'packages',
      'konyak_cli',
      'bin',
      'konyak.dart',
    ]);
  }

  return '../../packages/konyak_cli/bin/konyak.dart';
}

Map<String, String> _runtimeEnvironmentOverrides(
  Map<String, String> environment, {
  required String repoRootDefine,
  required String runtimeProfileDefine,
  required String macosWineHomeDefine,
  required String linuxWineHomeDefine,
  required String linuxWineLibraryPathDefine,
  required String macosWineStackManifestDefine,
  required String linuxWineStackManifestDefine,
  required String macosDevRuntimePrepareScriptDefine,
}) {
  final runtimeProfile = _firstNonEmpty(
    runtimeProfileDefine,
    environment['KONYAK_RUNTIME_PROFILE'],
  );
  final repoRoot = _firstNonEmpty(
    repoRootDefine,
    environment['KONYAK_REPO_ROOT'],
  );
  final isDevelopment = runtimeProfile == 'development';
  final macosWineHome = _firstNonEmpty(
    macosWineHomeDefine,
    environment['KONYAK_MACOS_WINE_HOME'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            '.dart_tool',
            'konyak',
            'dev-runtime',
            'macos-wine',
          ])
        : null,
  );
  final linuxWineHome = _firstNonEmpty(
    linuxWineHomeDefine,
    environment['KONYAK_LINUX_WINE_HOME'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            '.dart_tool',
            'konyak',
            'dev-runtime',
            'linux-wine',
          ])
        : null,
  );
  final linuxWineLibraryPath = _firstNonEmpty(
    linuxWineLibraryPathDefine,
    environment['KONYAK_LINUX_WINE_LIBRARY_PATH'],
  );
  final macosStackManifest = _firstNonEmpty(
    macosWineStackManifestDefine,
    environment['KONYAK_DEV_MACOS_WINE_STACK_MANIFEST'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            '.dart_tool',
            'konyak',
            'dev-runtime-source',
            'macos-wine-stack',
            'konyak-macos-wine-runtime-stack-source.json',
          ])
        : null,
  );
  final linuxStackManifest = _firstNonEmpty(
    linuxWineStackManifestDefine,
    environment['KONYAK_DEV_LINUX_WINE_STACK_MANIFEST'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            '.dart_tool',
            'konyak',
            'dev-runtime-source',
            'linux-wine-stack',
            'konyak-linux-wine-runtime-stack-source.json',
          ])
        : null,
  );
  final macosPrepareScript = _firstNonEmpty(
    macosDevRuntimePrepareScriptDefine,
    environment['KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            'scripts',
            'prepare_macos_dev_runtime_stack.zsh',
          ])
        : null,
  );

  final overrides = <String, String>{};
  void addIfPresent(String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      overrides[key] = value.trim();
    }
  }

  addIfPresent('KONYAK_RUNTIME_PROFILE', runtimeProfile);
  addIfPresent('KONYAK_MACOS_WINE_HOME', macosWineHome);
  addIfPresent('KONYAK_LINUX_WINE_HOME', linuxWineHome);
  addIfPresent('KONYAK_LINUX_WINE_LIBRARY_PATH', linuxWineLibraryPath);
  addIfPresent('KONYAK_DEV_MACOS_WINE_STACK_MANIFEST', macosStackManifest);
  addIfPresent('KONYAK_DEV_LINUX_WINE_STACK_MANIFEST', linuxStackManifest);
  addIfPresent('KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT', macosPrepareScript);

  return Map.unmodifiable(overrides);
}

String? _resolveCliScriptWorkingDirectory(String cliScriptPath) {
  final pathSegments = _splitPathSegments(cliScriptPath);
  if (pathSegments.length < 2 ||
      pathSegments[pathSegments.length - 2] != 'bin') {
    return null;
  }

  return _joinPath(
    _pathPrefixForSegmentCount(cliScriptPath, pathSegments.length - 2),
    const <String>[],
  );
}

String? _resolveCliScriptRunTarget(String cliScriptPath) {
  final pathSegments = _splitPathSegments(cliScriptPath);
  if (pathSegments.length < 2 ||
      pathSegments[pathSegments.length - 2] != 'bin') {
    return null;
  }

  return pathSegments.skip(pathSegments.length - 2).join('/');
}

List<String> _splitPathSegments(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').where((segment) => segment.isNotEmpty).toList();
}

String _pathPrefixForSegmentCount(String path, int segmentCount) {
  final normalized = path.replaceAll('\\', '/');
  final isAbsolute = normalized.startsWith('/');
  final segments = _splitPathSegments(path);
  final prefixSegments = segments.take(segmentCount).toList();
  if (prefixSegments.isEmpty) {
    return isAbsolute ? '/' : '.';
  }

  final prefix = prefixSegments.join('/');
  return isAbsolute ? '/$prefix' : prefix;
}
