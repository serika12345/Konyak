part of 'konyak_cli_client.dart';

const _bundleResourcesToken = '__KONYAK_BUNDLE_RESOURCES__';

final class _KonyakCliLaunchDefines {
  const _KonyakCliLaunchDefines({
    required this.dartExecutable,
    required this.cliScript,
    required this.cliExecutable,
    required this.appExecutable,
    required this.runtimeProfile,
    required this.macosWineHome,
    required this.linuxWineHome,
    required this.linuxWineLibraryPath,
    required this.macosWineStackManifest,
    required this.linuxWineStackManifest,
    required this.macosDevRuntimePrepareScript,
    required this.bundleResources,
    required this.repoRoot,
    required this.flutterRoot,
  });

  final String dartExecutable;
  final String cliScript;
  final String cliExecutable;
  final String appExecutable;
  final String runtimeProfile;
  final String macosWineHome;
  final String linuxWineHome;
  final String linuxWineLibraryPath;
  final String macosWineStackManifest;
  final String linuxWineStackManifest;
  final String macosDevRuntimePrepareScript;
  final String bundleResources;
  final String repoRoot;
  final String flutterRoot;
}

final class _KonyakCliLaunchConfig {
  _KonyakCliLaunchConfig({
    required this.executable,
    required List<String> baseArguments,
    required Map<String, String> environment,
    required this.workingDirectory,
  }) : baseArguments = List.unmodifiable(baseArguments),
       environment = Map.unmodifiable(environment);

  final String executable;
  final List<String> baseArguments;
  final Map<String, String> environment;
  final String? workingDirectory;
}

_KonyakCliLaunchConfig _konyakCliLaunchConfig({
  required Map<String, String> environment,
  required String resolvedExecutable,
  required _KonyakCliLaunchDefines defines,
}) {
  final configuredCliExecutable = _firstNonEmpty(
    defines.cliExecutable,
    environment['KONYAK_CLI_EXECUTABLE'],
  );
  final bundleResources = _resolveBundleResources(
    configuredCliExecutable,
    environment,
    defines: defines,
    resolvedExecutable: resolvedExecutable,
  );
  final runtimeEnvironment = _runtimeEnvironmentOverrides(
    environment,
    defines: defines,
    bundleResources: bundleResources,
  );

  final cliExecutable = _resolvePackagedCliExecutable(
    configuredCliExecutable,
    bundleResources: bundleResources,
  );
  if (cliExecutable != null) {
    return _KonyakCliLaunchConfig(
      executable: cliExecutable,
      baseArguments: const <String>[],
      environment: runtimeEnvironment,
      workingDirectory: null,
    );
  }

  final cliScriptPath = _resolveCliScriptPath(environment, defines: defines);
  final cliScriptWorkingDirectory = _resolveCliScriptWorkingDirectory(
    cliScriptPath,
  );
  final cliScriptRunTarget = _resolveCliScriptRunTarget(cliScriptPath);

  return _KonyakCliLaunchConfig(
    executable: _resolveDartExecutable(environment, defines: defines),
    baseArguments:
        cliScriptWorkingDirectory == null || cliScriptRunTarget == null
        ? <String>[cliScriptPath]
        : <String>['run', cliScriptRunTarget],
    environment: runtimeEnvironment,
    workingDirectory: cliScriptWorkingDirectory,
  );
}

String? _resolvePackagedCliExecutable(
  String? executable, {
  required String? bundleResources,
}) {
  if (executable == null || !executable.contains(_bundleResourcesToken)) {
    return executable;
  }

  if (bundleResources == null) {
    return executable;
  }

  return executable.replaceAll(_bundleResourcesToken, bundleResources);
}

String? _resolveBundleResources(
  String? executable,
  Map<String, String> environment, {
  required _KonyakCliLaunchDefines defines,
  required String resolvedExecutable,
}) {
  if (executable == null || !executable.contains(_bundleResourcesToken)) {
    return _firstNonEmpty(
      defines.bundleResources,
      environment['KONYAK_BUNDLE_RESOURCES'],
    );
  }

  final bundleResources = _firstNonEmpty(
    defines.bundleResources,
    environment['KONYAK_BUNDLE_RESOURCES'],
    _bundleResourcesPathFromAppExecutable(
      _firstNonEmpty(
        defines.appExecutable,
        environment['KONYAK_APP_EXECUTABLE'],
        resolvedExecutable,
      ),
    ),
  );
  if (bundleResources == null) {
    return null;
  }

  return bundleResources;
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
  required _KonyakCliLaunchDefines defines,
}) {
  final override = _firstNonEmpty(
    defines.dartExecutable,
    environment['KONYAK_DART_EXECUTABLE'],
  );
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final flutterRoot = _firstNonEmpty(
    defines.flutterRoot,
    environment['FLUTTER_ROOT'],
  );
  if (flutterRoot != null && flutterRoot.trim().isNotEmpty) {
    return _joinPath(flutterRoot, const ['bin', 'dart']);
  }

  return 'dart';
}

String _resolveCliScriptPath(
  Map<String, String> environment, {
  required _KonyakCliLaunchDefines defines,
}) {
  final override = _firstNonEmpty(
    defines.cliScript,
    environment['KONYAK_CLI_SCRIPT'],
  );
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final repoRoot = _firstNonEmpty(
    defines.repoRoot,
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
  required _KonyakCliLaunchDefines defines,
  required String? bundleResources,
}) {
  final runtimeProfile = _firstNonEmpty(
    defines.runtimeProfile,
    environment['KONYAK_RUNTIME_PROFILE'],
  );
  final repoRoot = _firstNonEmpty(
    defines.repoRoot,
    environment['KONYAK_REPO_ROOT'],
  );
  final isDevelopment = runtimeProfile == 'development';
  final macosWineHome = _firstNonEmpty(
    defines.macosWineHome,
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
    defines.linuxWineHome,
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
    defines.linuxWineLibraryPath,
    environment['KONYAK_LINUX_WINE_LIBRARY_PATH'],
  );
  final macosStackManifest = _firstNonEmpty(
    defines.macosWineStackManifest,
    environment['KONYAK_DEV_MACOS_WINE_STACK_MANIFEST'],
  );
  final linuxStackManifest = _firstNonEmpty(
    defines.linuxWineStackManifest,
    environment['KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST'],
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
    defines.macosDevRuntimePrepareScript,
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
  addIfPresent(
    'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST',
    linuxStackManifest,
  );
  addIfPresent('KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT', macosPrepareScript);
  addIfPresent('KONYAK_BUNDLE_RESOURCES', bundleResources);
  if (bundleResources != null && bundleResources.trim().isNotEmpty) {
    overrides['PATH'] = _prependPathEntry(bundleResources, environment['PATH']);
  }

  return Map.unmodifiable(overrides);
}

String _prependPathEntry(String path, String? existingPath) {
  final trimmedPath = path.trim();
  if (existingPath == null || existingPath.trim().isEmpty) {
    return trimmedPath;
  }

  return '$trimmedPath:$existingPath';
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
