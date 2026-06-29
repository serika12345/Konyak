import 'konyak_cli_process_runner.dart';
import 'konyak_cli_result_helpers.dart';

const bundleResourcesToken = '__KONYAK_BUNDLE_RESOURCES__';

final class KonyakCliLaunchDefines {
  const KonyakCliLaunchDefines({
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

final class KonyakCliLaunchConfig {
  KonyakCliLaunchConfig({
    required this.executable,
    required List<String> baseArguments,
    required Map<String, String> environment,
    required this.workingDirectory,
  }) : baseArguments = List.unmodifiable(baseArguments),
       environment = Map.unmodifiable(environment);

  final String executable;
  final List<String> baseArguments;
  final Map<String, String> environment;
  final ProcessWorkingDirectory workingDirectory;
}

sealed class _NonEmptyStringSelection {
  const _NonEmptyStringSelection();
}

final class _SelectedNonEmptyString extends _NonEmptyStringSelection {
  const _SelectedNonEmptyString(this.value);

  final String value;
}

final class _NoNonEmptyString extends _NonEmptyStringSelection {
  const _NoNonEmptyString();
}

sealed class _CliScriptInvocation {
  const _CliScriptInvocation();
}

final class _DirectCliScriptInvocation extends _CliScriptInvocation {
  const _DirectCliScriptInvocation(this.scriptPath);

  final String scriptPath;
}

final class _DartRunCliScriptInvocation extends _CliScriptInvocation {
  const _DartRunCliScriptInvocation({
    required this.workingDirectory,
    required this.runTarget,
  });

  final String workingDirectory;
  final String runTarget;
}

KonyakCliLaunchConfig konyakCliLaunchConfig({
  required Map<String, String> environment,
  required String resolvedExecutable,
  required KonyakCliLaunchDefines defines,
}) {
  final configuredCliExecutable = _firstNonEmptyString([
    defines.cliExecutable,
    _environmentValue(environment, 'KONYAK_CLI_EXECUTABLE'),
  ]);
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
  switch (cliExecutable) {
    case _SelectedNonEmptyString(:final value):
      return KonyakCliLaunchConfig(
        executable: value,
        baseArguments: const <String>[],
        environment: runtimeEnvironment,
        workingDirectory: const InheritedProcessWorkingDirectory(),
      );
    case _NoNonEmptyString():
      break;
  }

  final cliScriptPath = resolveCliScriptPath(environment, defines: defines);
  final cliScriptInvocation = _resolveCliScriptInvocation(cliScriptPath);

  return switch (cliScriptInvocation) {
    _DirectCliScriptInvocation(:final scriptPath) => KonyakCliLaunchConfig(
      executable: resolveDartExecutable(environment, defines: defines),
      baseArguments: <String>[scriptPath],
      environment: runtimeEnvironment,
      workingDirectory: const InheritedProcessWorkingDirectory(),
    ),
    _DartRunCliScriptInvocation(:final workingDirectory, :final runTarget) =>
      KonyakCliLaunchConfig(
        executable: resolveDartExecutable(environment, defines: defines),
        baseArguments: <String>['run', runTarget],
        environment: runtimeEnvironment,
        workingDirectory: ConfiguredProcessWorkingDirectory(workingDirectory),
      ),
  };
}

_NonEmptyStringSelection _resolvePackagedCliExecutable(
  _NonEmptyStringSelection executable, {
  required _NonEmptyStringSelection bundleResources,
}) {
  return switch (executable) {
    _NoNonEmptyString() => const _NoNonEmptyString(),
    _SelectedNonEmptyString(:final value)
        when !value.contains(bundleResourcesToken) =>
      _SelectedNonEmptyString(value),
    _SelectedNonEmptyString(:final value) => switch (bundleResources) {
      _SelectedNonEmptyString(value: final resources) =>
        _SelectedNonEmptyString(
          value.replaceAll(bundleResourcesToken, resources),
        ),
      _NoNonEmptyString() => _SelectedNonEmptyString(value),
    },
  };
}

_NonEmptyStringSelection _resolveBundleResources(
  _NonEmptyStringSelection executable,
  Map<String, String> environment, {
  required KonyakCliLaunchDefines defines,
  required String resolvedExecutable,
}) {
  final configuredBundleResources = _firstNonEmptyString([
    defines.bundleResources,
    _environmentValue(environment, 'KONYAK_BUNDLE_RESOURCES'),
  ]);

  return switch (executable) {
    _NoNonEmptyString() => configuredBundleResources,
    _SelectedNonEmptyString(:final value)
        when !value.contains(bundleResourcesToken) =>
      configuredBundleResources,
    _SelectedNonEmptyString() => _firstPresentNonEmptyString([
      configuredBundleResources,
      _bundleResourcesPathFromAppExecutable(
        _firstNonEmptyString([
          defines.appExecutable,
          _environmentValue(environment, 'KONYAK_APP_EXECUTABLE'),
          resolvedExecutable,
        ]),
      ),
    ]),
  };
}

_NonEmptyStringSelection _bundleResourcesPathFromAppExecutable(
  _NonEmptyStringSelection executable,
) {
  return switch (executable) {
    _NoNonEmptyString() => const _NoNonEmptyString(),
    _SelectedNonEmptyString(:final value) => () {
      final normalized = value.replaceAll('\\', '/');
      final marker = '.app/Contents/MacOS/';
      final markerIndex = normalized.indexOf(marker);
      if (markerIndex < 0) {
        return const _NoNonEmptyString();
      }

      final bundleRootEnd = markerIndex + '.app/Contents/'.length;
      return _SelectedNonEmptyString(
        '${normalized.substring(0, bundleRootEnd)}Resources',
      );
    }(),
  };
}

String resolveDartExecutable(
  Map<String, String> environment, {
  required KonyakCliLaunchDefines defines,
}) {
  switch (_firstNonEmptyString([
    defines.dartExecutable,
    _environmentValue(environment, 'KONYAK_DART_EXECUTABLE'),
  ])) {
    case _SelectedNonEmptyString(:final value):
      return value;
    case _NoNonEmptyString():
      break;
  }

  return switch (_firstNonEmptyString([
    defines.flutterRoot,
    _environmentValue(environment, 'FLUTTER_ROOT'),
  ])) {
    _SelectedNonEmptyString(:final value) => joinPath(value, const [
      'bin',
      'dart',
    ]),
    _NoNonEmptyString() => 'dart',
  };
}

String resolveCliScriptPath(
  Map<String, String> environment, {
  required KonyakCliLaunchDefines defines,
}) {
  switch (_firstNonEmptyString([
    defines.cliScript,
    _environmentValue(environment, 'KONYAK_CLI_SCRIPT'),
  ])) {
    case _SelectedNonEmptyString(:final value):
      return value;
    case _NoNonEmptyString():
      break;
  }

  return switch (_firstNonEmptyString([
    defines.repoRoot,
    _environmentValue(environment, 'KONYAK_REPO_ROOT'),
  ])) {
    _SelectedNonEmptyString(:final value) => joinPath(value, const [
      'packages',
      'konyak_cli',
      'bin',
      'konyak.dart',
    ]),
    _NoNonEmptyString() => '../../packages/konyak_cli/bin/konyak.dart',
  };
}

Map<String, String> _runtimeEnvironmentOverrides(
  Map<String, String> environment, {
  required KonyakCliLaunchDefines defines,
  required _NonEmptyStringSelection bundleResources,
}) {
  final runtimeProfile = _firstNonEmptyString([
    defines.runtimeProfile,
    _environmentValue(environment, 'KONYAK_RUNTIME_PROFILE'),
  ]);
  final repoRoot = _firstNonEmptyString([
    defines.repoRoot,
    _environmentValue(environment, 'KONYAK_REPO_ROOT'),
  ]);
  final isDevelopment = switch (runtimeProfile) {
    _SelectedNonEmptyString(value: 'development') => true,
    _SelectedNonEmptyString() || _NoNonEmptyString() => false,
  };
  final macosWineHome = _firstNonEmptyString([
    defines.macosWineHome,
    _environmentValue(environment, 'KONYAK_MACOS_WINE_HOME'),
    _developmentPathFromRepo(
      repoRoot,
      isDevelopment: isDevelopment,
      components: const ['.dart_tool', 'konyak', 'dev-runtime', 'macos-wine'],
    ),
  ]);
  final linuxWineHome = _firstNonEmptyString([
    defines.linuxWineHome,
    _environmentValue(environment, 'KONYAK_LINUX_WINE_HOME'),
    _developmentPathFromRepo(
      repoRoot,
      isDevelopment: isDevelopment,
      components: const ['.dart_tool', 'konyak', 'dev-runtime', 'linux-wine'],
    ),
  ]);
  final linuxWineLibraryPath = _firstNonEmptyString([
    defines.linuxWineLibraryPath,
    _environmentValue(environment, 'KONYAK_LINUX_WINE_LIBRARY_PATH'),
  ]);
  final macosStackManifest = _firstNonEmptyString([
    defines.macosWineStackManifest,
    _environmentValue(environment, 'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST'),
  ]);
  final linuxStackManifest = _firstNonEmptyString([
    defines.linuxWineStackManifest,
    _environmentValue(
      environment,
      'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST',
    ),
    _developmentPathFromRepo(
      repoRoot,
      isDevelopment: isDevelopment,
      components: const [
        '.dart_tool',
        'konyak',
        'dev-runtime-source',
        'linux-wine-stack',
        'konyak-linux-wine-runtime-stack-source.json',
      ],
    ),
  ]);
  final macosPrepareScript = _firstNonEmptyString([
    defines.macosDevRuntimePrepareScript,
    _environmentValue(environment, 'KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT'),
    _developmentPathFromRepo(
      repoRoot,
      isDevelopment: isDevelopment,
      components: const ['scripts', 'prepare_macos_dev_runtime_stack.zsh'],
    ),
  ]);

  final overrides = <String, String>{};
  void addIfPresent(String key, _NonEmptyStringSelection value) {
    switch (value) {
      case _SelectedNonEmptyString(:final value):
        overrides[key] = value.trim();
      case _NoNonEmptyString():
        break;
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
  switch (bundleResources) {
    case _SelectedNonEmptyString(:final value):
      overrides['PATH'] = _prependPathEntry(
        value,
        _environmentValue(environment, 'PATH'),
      );
    case _NoNonEmptyString():
      break;
  }

  return Map.unmodifiable(overrides);
}

String _environmentValue(Map<String, String> environment, String key) {
  if (!environment.containsKey(key)) {
    return '';
  }

  return environment[key]!;
}

_NonEmptyStringSelection _firstNonEmptyString(Iterable<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) {
      return _SelectedNonEmptyString(value);
    }
  }

  return const _NoNonEmptyString();
}

_NonEmptyStringSelection _firstPresentNonEmptyString(
  Iterable<_NonEmptyStringSelection> values,
) {
  for (final value in values) {
    switch (value) {
      case _SelectedNonEmptyString():
        return value;
      case _NoNonEmptyString():
        break;
    }
  }

  return const _NoNonEmptyString();
}

String _developmentPathFromRepo(
  _NonEmptyStringSelection repoRoot, {
  required bool isDevelopment,
  required List<String> components,
}) {
  if (!isDevelopment) {
    return '';
  }

  return switch (repoRoot) {
    _SelectedNonEmptyString(:final value) => joinPath(value, components),
    _NoNonEmptyString() => '',
  };
}

String _prependPathEntry(String path, String existingPath) {
  final trimmedPath = path.trim();
  if (existingPath.trim().isEmpty) {
    return trimmedPath;
  }

  return '$trimmedPath:$existingPath';
}

_CliScriptInvocation _resolveCliScriptInvocation(String cliScriptPath) {
  final pathSegments = splitPathSegments(cliScriptPath);
  if (pathSegments.length < 2 ||
      pathSegments[pathSegments.length - 2] != 'bin') {
    return _DirectCliScriptInvocation(cliScriptPath);
  }

  return _DartRunCliScriptInvocation(
    workingDirectory: joinPath(
      pathPrefixForSegmentCount(cliScriptPath, pathSegments.length - 2),
      const <String>[],
    ),
    runTarget: pathSegments.skip(pathSegments.length - 2).join('/'),
  );
}

List<String> splitPathSegments(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').where((segment) => segment.isNotEmpty).toList();
}

String pathPrefixForSegmentCount(String path, int segmentCount) {
  final normalized = path.replaceAll('\\', '/');
  final isAbsolute = normalized.startsWith('/');
  final segments = splitPathSegments(path);
  final prefixSegments = segments.take(segmentCount).toList();
  if (prefixSegments.isEmpty) {
    return isAbsolute ? '/' : '.';
  }

  final prefix = prefixSegments.join('/');
  return isAbsolute ? '/$prefix' : prefix;
}
