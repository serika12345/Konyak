part of '../konyak_cli.dart';

const _linuxWineRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine'],
          <String>['bin', 'winedbg'],
          <String>['bin', 'wineserver'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk',
        name: 'DXVK',
        role: 'd3d9-d3d11-vulkan-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['dxvk', 'x64', 'dxgi.dll'],
          <String>['dxvk', 'x64', 'd3d9.dll'],
          <String>['dxvk', 'x64', 'd3d10core.dll'],
          <String>['dxvk', 'x64', 'd3d11.dll'],
          <String>['dxvk', 'x86', 'dxgi.dll'],
          <String>['dxvk', 'x86', 'd3d9.dll'],
          <String>['dxvk', 'x86', 'd3d10core.dll'],
          <String>['dxvk', 'x86', 'd3d11.dll'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'vkd3d-proton',
        name: 'vkd3d-proton',
        role: 'd3d12-vulkan-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
          <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
          <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
          <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
        ],
      ),
    ];

const _macosKonyakRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine64'],
          <String>['bin', 'wineserver'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine32on64',
        name: 'Wine32-on-64 support',
        role: '32-bit-windows-support',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk-macos',
        name: 'DXVK-macOS',
        role: 'd3d9-d3d11-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['DXVK', 'x64', 'dxgi.dll'],
          <String>['DXVK', 'x64', 'd3d9.dll'],
          <String>['DXVK', 'x64', 'd3d10core.dll'],
          <String>['DXVK', 'x64', 'd3d11.dll'],
          <String>['DXVK', 'x32', 'dxgi.dll'],
          <String>['DXVK', 'x32', 'd3d9.dll'],
          <String>['DXVK', 'x32', 'd3d10core.dll'],
          <String>['DXVK', 'x32', 'd3d11.dll'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'moltenvk',
        name: 'MoltenVK',
        role: 'vulkan-metal-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libMoltenVK.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gstreamer',
        name: 'GStreamer runtime',
        role: 'media-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libgstreamer-1.0.0.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gptk-d3dmetal',
        name: 'GPTK/D3DMetal',
        role: 'd3d12-metal-translation',
        isRequired: false,
        relativePaths: <List<String>>[
          <String>['lib', 'external', 'D3DMetal.framework'],
          <String>['lib', 'external', 'libd3dshared.dylib'],
          <String>['lib', 'wine', 'x86_64-windows', 'd3d12.dll'],
          <String>['lib', 'wine', 'x86_64-windows', 'dxgi.dll'],
        ],
      ),
    ];

const _linuxWineRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: linuxWineRuntimeId,
  runtimeName: 'Konyak Linux Wine',
  platform: 'linux',
  architecture: 'x86_64',
  runnerKind: 'wine',
  stackId: 'linux-wine-runtime-stack',
  stackName: 'Linux Wine/Proton runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wine'],
  defaultArchiveFileName: 'linux-wine.tar.xz',
  archiveUrlEnvironmentKey: 'KONYAK_LINUX_WINE_ARCHIVE_URL',
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_SIGNATURE_URL',
  componentDefinitions: _linuxWineRuntimeComponentDefinitions,
);

const _macosKonyakRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: macosWineRuntimeId,
  runtimeName: 'Konyak macOS Wine',
  platform: 'macos',
  architecture: 'x86_64',
  runnerKind: 'macosWine',
  stackId: 'macos-konyak-runtime-stack',
  stackName: 'Konyak macOS runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wine64'],
  defaultArchiveUrl: macosWineArchiveUrl,
  defaultArchiveFileName: macosWineArchiveFileName,
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_MACOS_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_MACOS_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_MACOS_WINE_STACK_SIGNATURE_URL',
  layoutNormalization: _RuntimeLayoutNormalization.macosWineBundle,
  componentDefinitions: _macosKonyakRuntimeComponentDefinitions,
);

String? _runtimeSourceManifestForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceManifestEnvironmentKey,
    releaseKey: platformSpec.releaseSourceManifestEnvironmentKey,
  );
}

String? _runtimeSourceManifestSignatureForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceSignatureEnvironmentKey,
    releaseKey: platformSpec.releaseSourceSignatureEnvironmentKey,
  );
}

String? _runtimeDefaultArchiveUrl({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  final archiveUrlEnvironmentKey = platformSpec.archiveUrlEnvironmentKey;
  if (archiveUrlEnvironmentKey != null) {
    return _nonEmptyEnvironmentValue(environment, archiveUrlEnvironmentKey);
  }

  return platformSpec.defaultArchiveUrl;
}

RuntimeRecord _macosWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _macosKonyakRuntimePlatformSpec;
  final applicationSupportPath = _konyakApplicationSupportFolder(environment);
  final libraryPath = _macosWineRuntimeRoot(environment);
  final executablePath = _macosWineExecutable(environment);
  final isInstalled = fileStatusProbe.exists(executablePath);

  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: true,
      distributionKind: _runtimeDistributionKind(environment, 'bootstrap'),
      archiveUrl: platformSpec.defaultArchiveUrl,
      versionUrl: macosWineVersionUrl,
    ),
    installedState: InstalledRuntimeState(
      isInstalled: isInstalled,
      applicationSupportPath: applicationSupportPath,
      libraryPath: libraryPath,
      executablePath: executablePath,
    ),
    capabilities: RuntimeCapabilities(
      stack: _runtimeStackForPlatform(
        platformSpec: platformSpec,
        runtimeRoot: libraryPath,
        fileStatusProbe: fileStatusProbe,
        runtimeStackVersionProbe: runtimeStackVersionProbe,
      ),
    ),
  );
}

RuntimeRecord _linuxWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _linuxWineRuntimePlatformSpec;
  final runtimeRoot = _linuxWineRuntimeRoot(environment);
  final executablePath = _joinPath(runtimeRoot, const ['bin', 'wine']);
  final archiveUrl = _runtimeDefaultArchiveUrl(
    platformSpec: platformSpec,
    environment: environment,
  );
  final versionUrl = _nonEmptyEnvironmentValue(
    environment,
    'KONYAK_LINUX_WINE_VERSION_URL',
  );
  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: archiveUrl != null || versionUrl != null,
      distributionKind: _runtimeDistributionKind(environment, 'managed'),
      archiveUrl: archiveUrl,
      versionUrl: versionUrl,
    ),
    installedState: InstalledRuntimeState(
      isInstalled: fileStatusProbe.exists(executablePath),
      libraryPath: runtimeRoot,
      executablePath: executablePath,
    ),
    capabilities: RuntimeCapabilities(
      stack: _runtimeStackForPlatform(
        platformSpec: platformSpec,
        runtimeRoot: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
        runtimeStackVersionProbe: runtimeStackVersionProbe,
      ),
    ),
  );
}

RuntimeStack _runtimeStackForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  return RuntimeStack(
    id: platformSpec.stackId,
    name: platformSpec.stackName,
    compatibilityTarget: platformSpec.stackId,
    components: platformSpec.componentDefinitions
        .map(
          (definition) => _runtimeStackComponent(
            runtimeRoot: runtimeRoot,
            fileStatusProbe: fileStatusProbe,
            runtimeStackVersionProbe: runtimeStackVersionProbe,
            definition: definition,
          ),
        )
        .toList(growable: false),
  );
}

RuntimeStackComponent _runtimeStackComponent({
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
  required _RuntimeStackComponentDefinition definition,
}) {
  final paths = definition.relativePaths
      .map((pathSegments) => _joinPath(runtimeRoot, pathSegments))
      .toList(growable: false);
  final missingPaths = paths
      .where((path) => !fileStatusProbe.exists(path))
      .toList();
  if (definition.id == 'gptk-d3dmetal') {
    final frameworkBinary = _d3dMetalFrameworkBinary(paths.first);
    if (frameworkBinary == null || !_looksLikeMachO(File(frameworkBinary))) {
      if (!missingPaths.contains(paths.first)) {
        missingPaths.add(paths.first);
      }
    }
    if (!_looksLikeMachO(File(paths[1]))) {
      if (!missingPaths.contains(paths[1])) {
        missingPaths.add(paths[1]);
      }
    }
  }

  return RuntimeStackComponent(
    id: definition.id,
    name: definition.name,
    role: definition.role,
    isRequired: definition.isRequired,
    paths: paths,
    missingPaths: missingPaths,
    version: missingPaths.isEmpty
        ? runtimeStackVersionProbe.versionFor(
            runtimeRoot: runtimeRoot,
            componentId: definition.id,
          )
        : null,
  );
}

RuntimeSourceManifest? _runtimeStackSourceManifestFromPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return null;
  }

  final runtimeId = decoded['runtimeId'];
  final stackId = decoded['stackId'];
  final components = decoded['components'];
  if (runtimeId is! String ||
      runtimeId.trim().isEmpty ||
      stackId is! String ||
      stackId.trim().isEmpty ||
      components is! List<dynamic>) {
    return null;
  }

  final parsedComponents = <RuntimeSourceComponent>[];
  for (final component in components) {
    final parsedComponent = _runtimeStackSourceComponent(component);
    if (parsedComponent == null) {
      return null;
    }
    parsedComponents.add(parsedComponent);
  }

  if (parsedComponents.isEmpty) {
    return null;
  }

  return RuntimeSourceManifest(
    runtimeId: runtimeId,
    stackId: stackId,
    components: parsedComponents,
  );
}

RuntimeSourceComponent? _runtimeStackSourceComponent(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final id = value['id'];
  final version = value['version'];
  final archiveUrl = value['archiveUrl'];
  final sha256 = value['sha256'];

  if (id is! String ||
      id.trim().isEmpty ||
      version is! String ||
      version.trim().isEmpty ||
      archiveUrl is! String ||
      archiveUrl.trim().isEmpty ||
      sha256 is! String ||
      !_isSha256Hex(sha256)) {
    return null;
  }

  return RuntimeSourceComponent(
    id: id,
    version: version,
    archiveUrl: archiveUrl,
    sha256: sha256,
  );
}

_RuntimeStackSourceArchiveBundleResult _resolveRuntimeStackSourceArchiveBundle({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponent = manifest.componentById('wine');
  if (wineComponent == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    );
  }

  final archivePaths = <String, String>{};
  final componentCount = manifest.components.length;
  for (final component in manifest.components) {
    final fileName =
        _fileNameFromUrl(component.archiveUrl) ?? '${component.id}.tar.xz';
    final archivePath = _joinPath(tempDirectory.path, [
      '${archivePaths.length}-$fileName',
    ]);
    final componentIndex = archivePaths.length;
    final startFraction = 0.05 + (componentIndex / componentCount) * 0.55;
    final endFraction = 0.05 + ((componentIndex + 1) / componentCount) * 0.55;
    final downloadFailure = _downloadRuntimeStackSourceArchive(
      source: component.archiveUrl,
      targetPath: archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: 'Downloading ${component.id}...',
      startFraction: startFraction,
      endFraction: endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying ${component.id}...',
      fraction: endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(archivePath));
    if (actualSha256.toLowerCase() != component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${component.id}` checksum mismatch: '
        'expected ${component.sha256}, got $actualSha256.',
      );
    }

    archivePaths[component.id] = archivePath;
  }

  final wineArchivePath = archivePaths[wineComponent.id];
  if (wineArchivePath == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest did not resolve a Wine archive.',
    );
  }

  return _RuntimeStackSourceArchiveBundleResolved(
    _RuntimeStackSourceArchiveBundle(
      wineArchivePath: wineArchivePath,
      componentArchivePaths: <String>[
        for (final component in manifest.components)
          if (component.id != wineComponent.id) archivePaths[component.id]!,
      ],
      componentVersions: <String, String>{
        for (final component in manifest.components)
          component.id: component.version,
      },
    ),
  );
}

Future<_RuntimeStackSourceArchiveBundleResult>
_resolveRuntimeStackSourceArchiveBundleStreaming({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponent = manifest.componentById('wine');
  if (wineComponent == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    );
  }

  final archivePaths = <String, String>{};
  final componentCount = manifest.components.length;
  for (final component in manifest.components) {
    final fileName =
        _fileNameFromUrl(component.archiveUrl) ?? '${component.id}.tar.xz';
    final archivePath = _joinPath(tempDirectory.path, [
      '${archivePaths.length}-$fileName',
    ]);
    final componentIndex = archivePaths.length;
    final startFraction = 0.05 + (componentIndex / componentCount) * 0.55;
    final endFraction = 0.05 + ((componentIndex + 1) / componentCount) * 0.55;
    final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
      source: component.archiveUrl,
      targetPath: archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: 'Downloading ${component.id}...',
      startFraction: startFraction,
      endFraction: endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying ${component.id}...',
      fraction: endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(archivePath));
    if (actualSha256.toLowerCase() != component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${component.id}` checksum mismatch: '
        'expected ${component.sha256}, got $actualSha256.',
      );
    }

    archivePaths[component.id] = archivePath;
  }

  final wineArchivePath = archivePaths[wineComponent.id];
  if (wineArchivePath == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest did not resolve a Wine archive.',
    );
  }

  return _RuntimeStackSourceArchiveBundleResolved(
    _RuntimeStackSourceArchiveBundle(
      wineArchivePath: wineArchivePath,
      componentArchivePaths: <String>[
        for (final component in manifest.components)
          if (component.id != wineComponent.id) archivePaths[component.id]!,
      ],
      componentVersions: <String, String>{
        for (final component in manifest.components)
          component.id: component.version,
      },
    ),
  );
}

String? _downloadRuntimeStackSourceArchive({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  }

  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction,
  );
  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--output',
    targetPath,
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return _commandFailureMessage('download runtime stack component', result);
  }
  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: endFraction,
  );
  return null;
}

Future<String?> _downloadRuntimeStackSourceArchiveStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    return _copyRuntimeStackSourceArchiveStreaming(
      sourcePath: localPath,
      targetPath: targetPath,
      progressSink: progressSink,
      stage: stage,
      message: message,
      startFraction: startFraction,
      endFraction: endFraction,
    );
  }

  return _downloadRuntimeStackSourceUriStreaming(
    source: source,
    targetPath: targetPath,
    progressSink: progressSink,
    stage: stage,
    message: message,
    startFraction: startFraction,
    endFraction: endFraction,
  );
}

Future<String?> _copyRuntimeStackSourceArchiveStreaming({
  required String sourcePath,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) async {
  try {
    final source = File(sourcePath);
    final totalBytes = await source.length();
    var copiedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    try {
      await for (final chunk in source.openRead()) {
        copiedBytes += chunk.length;
        sink.add(chunk);
        _emitRuntimeInstallByteProgress(
          progressSink,
          stage: stage,
          message: message,
          copiedBytes: copiedBytes,
          totalBytes: totalBytes,
          startFraction: startFraction,
          endFraction: endFraction,
        );
      }
    } finally {
      await sink.close();
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  } on FileSystemException catch (error) {
    return error.message;
  }
}

Future<String?> _downloadRuntimeStackSourceUriStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) async {
  final uri = Uri.tryParse(source);
  if (uri == null || !uri.hasScheme) {
    return 'Runtime stack component URL is invalid: $source';
  }

  final client = HttpClient();
  try {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );

    final request = await client.getUrl(uri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Konyak/$konyakAppVersion',
    );
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'download runtime stack component failed with HTTP status '
          '${response.statusCode}.';
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();
    try {
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        _emitRuntimeInstallByteProgress(
          progressSink,
          stage: stage,
          message: message,
          copiedBytes: receivedBytes,
          totalBytes: totalBytes,
          startFraction: startFraction,
          endFraction: endFraction,
        );
      }
    } finally {
      await sink.close();
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  } on HttpException catch (error) {
    return error.message;
  } on IOException catch (error) {
    return error.toString();
  } finally {
    client.close(force: true);
  }
}

void _emitRuntimeInstallByteProgress(
  RuntimeInstallProgressSink? progressSink, {
  required String stage,
  required String message,
  required int copiedBytes,
  required int totalBytes,
  required double startFraction,
  required double endFraction,
}) {
  if (totalBytes <= 0) {
    return;
  }

  final byteFraction = copiedBytes / totalBytes;
  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction + (endFraction - startFraction) * byteFraction,
  );
}

void _emitRuntimeInstallProgress(
  RuntimeInstallProgressSink? progressSink, {
  required String stage,
  required String message,
  required double fraction,
}) {
  final normalizedFraction = fraction.clamp(0, 1).toDouble();
  progressSink?.emit(
    RuntimeInstallProgress(
      stage: stage,
      message: message,
      fraction: normalizedFraction,
    ),
  );
}

String? _runtimeStackComponentVersion(Object? decoded, String componentId) {
  final components = _runtimeStackComponentVersions(decoded);
  return components[componentId];
}

Map<String, String> _runtimeStackComponentVersions(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const <String, String>{};
  }
  if (decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return const <String, String>{};
  }

  final components = decoded['components'];
  if (components is! Map<String, dynamic>) {
    return const <String, String>{};
  }

  final versions = <String, String>{};
  for (final entry in components.entries) {
    final version = entry.value;
    if (version is String && version.isNotEmpty) {
      versions[entry.key] = version;
    }
  }

  return Map.unmodifiable(versions);
}

String? _installRuntimeArchives({
  required String runtimeLabel,
  required String archivePath,
  required String? archiveSha256,
  required List<String> componentArchivePaths,
  required Map<String, String> componentVersions,
  required Directory runtimeRoot,
  required List<String> requiredExecutableRelativePath,
  required String expectedExecutablePath,
  required bool preserveExistingRuntimeFiles,
  void Function(Directory runtimeRoot)? normalizeStagingRoot,
  void Function(Directory runtimeRoot)? afterManifestWrite,
  RuntimeInstallProgressSink? progressSink,
}) {
  final expectedSha256 = archiveSha256;
  if (expectedSha256 != null) {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying $runtimeLabel archive...',
      fraction: 0.62,
    );
    try {
      final archive = File(archivePath);
      if (!archive.existsSync()) {
        return '$runtimeLabel archive `$archivePath` was not found.';
      }
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        return '$runtimeLabel archive checksum mismatch: expected '
            '$expectedSha256, got $actualSha256.';
      }
    } on FileSystemException catch (error) {
      return error.message;
    }
  }

  final stagingRoot = Directory(
    _runtimeSiblingPathForInstall(runtimeRoot, 'install'),
  );
  final backupRoot = Directory(
    _runtimeSiblingPathForInstall(runtimeRoot, 'previous'),
  );
  final lockFile = File(_runtimeInstallLockPath(runtimeRoot));
  final resolvedComponentVersions = <String, String>{...componentVersions};
  final archivePaths = <String>[archivePath, ...componentArchivePaths];
  var lockCreated = false;

  try {
    runtimeRoot.parent.createSync(recursive: true);
    try {
      lockFile.createSync(exclusive: true);
      lockCreated = true;
    } on FileSystemException {
      return '$runtimeLabel installation is already running.';
    }
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    stagingRoot.createSync(recursive: true);

    for (var index = 0; index < archivePaths.length; index += 1) {
      final currentArchivePath = archivePaths[index];
      final archive = File(currentArchivePath);
      if (!archive.existsSync()) {
        return '$runtimeLabel archive `$currentArchivePath` was not found.';
      }

      final startFraction = 0.65 + (index / archivePaths.length) * 0.25;
      final endFraction = 0.65 + ((index + 1) / archivePaths.length) * 0.25;
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracting ${_basename(currentArchivePath)}...',
        fraction: startFraction,
      );
      final extraction = Process.runSync('tar', [
        '-xf',
        currentArchivePath,
        '-C',
        stagingRoot.path,
        '--strip-components',
        '1',
      ], runInShell: false);
      if (extraction.exitCode != 0) {
        return _commandFailureMessage('extract $runtimeLabel', extraction);
      }

      _mergeRuntimeStackManifest(
        runtimeRoot: stagingRoot,
        componentVersions: resolvedComponentVersions,
      );
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracted ${_basename(currentArchivePath)}.',
        fraction: endFraction,
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Finalizing $runtimeLabel install...',
      fraction: 0.92,
    );
    normalizeStagingRoot?.call(stagingRoot);
    if (preserveExistingRuntimeFiles && runtimeRoot.existsSync()) {
      _copyDirectoryContentsReplacing(
        source: runtimeRoot,
        destination: stagingRoot,
      );
      _mergeRuntimeStackManifest(
        runtimeRoot: runtimeRoot,
        componentVersions: resolvedComponentVersions,
      );
    }
    _writeRuntimeStackManifest(
      runtimeRoot: stagingRoot,
      componentVersions: resolvedComponentVersions,
    );
    afterManifestWrite?.call(stagingRoot);

    final stagedExecutable = File(
      _joinPath(stagingRoot.path, requiredExecutableRelativePath),
    );
    if (!stagedExecutable.existsSync()) {
      return '$runtimeLabel archive did not install `$expectedExecutablePath`.';
    }

    _replaceRuntimeRootInPlace(
      runtimeRoot: runtimeRoot,
      stagingRoot: stagingRoot,
      backupRoot: backupRoot,
    );
    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Installed $runtimeLabel files.',
      fraction: 0.98,
    );
  } on ProcessException catch (error) {
    return error.message;
  } on FileSystemException catch (error) {
    return error.message;
  } finally {
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    if (lockCreated && lockFile.existsSync()) {
      lockFile.deleteSync();
    }
  }

  return null;
}

String _runtimeInstallLockPath(Directory runtimeRoot) {
  return '${runtimeRoot.path}.install.lock';
}

void _mergeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return;
  }

  try {
    componentVersions.addAll(
      _runtimeStackComponentVersions(jsonDecode(manifest.readAsStringSync())),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  }
}

void _writeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  if (componentVersions.isEmpty) {
    return;
  }

  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  manifest.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schemaVersion': runtimeStackSchemaVersion,
      'components': componentVersions,
    }),
  );
}

void _upsertRuntimeStackComponentVersion({
  required Directory runtimeRoot,
  required String componentId,
  required String version,
}) {
  final componentVersions = <String, String>{};
  _mergeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
  componentVersions[componentId] = version;
  _writeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
}

Directory? _resolveGptkWineRoot(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  if (!_baseName(sourcePath).endsWith('.app')) {
    return null;
  }

  final candidate = Directory(
    _joinPath(sourcePath, const ['Contents', 'Resources', 'wine']),
  );
  if (_isGptkWineRootCandidate(candidate)) {
    return candidate;
  }

  return null;
}

bool _isGptkWineRootCandidate(Directory directory) {
  if (!directory.existsSync()) {
    return false;
  }
  final wine64 = File(_joinPath(directory.path, const ['bin', 'wine64']));
  final wineserver = File(
    _joinPath(directory.path, const ['bin', 'wineserver']),
  );
  final lib = Directory(_joinPath(directory.path, const ['lib']));
  final lib64 = Directory(_joinPath(directory.path, const ['lib64']));
  return wine64.existsSync() &&
      wineserver.existsSync() &&
      (lib.existsSync() || lib64.existsSync());
}

String? _validateGptkWineRoot(Directory sourceRoot) {
  final wine64 = File(_joinPath(sourceRoot.path, const ['bin', 'wine64']));
  final wineserver = File(
    _joinPath(sourceRoot.path, const ['bin', 'wineserver']),
  );
  if (!wine64.existsSync()) {
    return 'GPTK-compatible Wine source is missing bin/wine64.';
  }
  if (!wineserver.existsSync()) {
    return 'GPTK-compatible Wine source is missing bin/wineserver.';
  }
  if (!_looksLikeMachO(wine64)) {
    return 'bin/wine64 is not a Mach-O binary. Konyak rejects fixture text '
        'files and incomplete Wine copies.';
  }
  if (!_looksLikeMachO(wineserver)) {
    return 'bin/wineserver is not a Mach-O binary. Konyak rejects fixture text '
        'files and incomplete Wine copies.';
  }

  final lib = Directory(_joinPath(sourceRoot.path, const ['lib']));
  final lib64 = Directory(_joinPath(sourceRoot.path, const ['lib64']));
  if (!lib.existsSync() && !lib64.existsSync()) {
    return 'GPTK-compatible Wine source is missing lib or lib64.';
  }

  return null;
}

String? _validateGptkD3DMetalSource(_GptkD3DMetalSource source) {
  final frameworkBinary = _d3dMetalFrameworkBinary(source.framework.path);
  if (frameworkBinary == null || !File(frameworkBinary).existsSync()) {
    return 'D3DMetal.framework does not contain a D3DMetal binary.';
  }
  if (!_looksLikeMachO(File(frameworkBinary))) {
    return 'D3DMetal.framework is not a Mach-O framework binary. Konyak '
        'rejects fixture text files and incomplete GPTK copies.';
  }
  if (!_looksLikeMachO(source.dylib)) {
    return 'libd3dshared.dylib is not a Mach-O binary. Konyak rejects fixture '
        'text files and incomplete GPTK copies.';
  }
  if (!_looksLikePE(source.d3d12Dll)) {
    return 'd3d12.dll is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.';
  }
  if (!_looksLikePE(source.dxgiDll)) {
    return 'dxgi.dll is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.';
  }
  return null;
}

_GptkD3DMetalSource? _resolveGptkD3DMetalSource(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory &&
      _baseName(sourcePath) == 'D3DMetal.framework') {
    final framework = Directory(sourcePath);
    final siblingDylib = File(
      _joinPath(_dirname(sourcePath), const ['libd3dshared.dylib']),
    );
    final dllSource = _resolveGptkD3DMetalWindowsDlls(
      Directory(_dirname(sourcePath)),
    );
    if (siblingDylib.existsSync() && dllSource != null) {
      return _GptkD3DMetalSource(
        directory: Directory(_dirname(sourcePath)),
        framework: framework,
        dylib: siblingDylib,
        d3d12Dll: dllSource.d3d12Dll,
        dxgiDll: dllSource.dxgiDll,
      );
    }
    return null;
  }

  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  final candidate = Directory(_joinPath(sourcePath, const ['lib', 'external']));
  final framework = Directory(
    _joinPath(candidate.path, const ['D3DMetal.framework']),
  );
  final dylib = File(_joinPath(candidate.path, const ['libd3dshared.dylib']));
  final dllSource = _resolveGptkD3DMetalWindowsDlls(candidate);
  if (framework.existsSync() && dylib.existsSync() && dllSource != null) {
    return _GptkD3DMetalSource(
      directory: candidate,
      framework: framework,
      dylib: dylib,
      d3d12Dll: dllSource.d3d12Dll,
      dxgiDll: dllSource.dxgiDll,
    );
  }

  return null;
}

class _GptkD3DMetalWindowsDllSource {
  const _GptkD3DMetalWindowsDllSource({
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final File d3d12Dll;
  final File dxgiDll;
}

_GptkD3DMetalWindowsDllSource? _resolveGptkD3DMetalWindowsDlls(
  Directory sourceDirectory,
) {
  final d3d12 = File(
    _joinPath(sourceDirectory.path, const [
      '..',
      'wine',
      'x86_64-windows',
      'd3d12.dll',
    ]),
  );
  final dxgi = File(_joinPath(_dirname(d3d12.path), const ['dxgi.dll']));
  if (d3d12.existsSync() && dxgi.existsSync()) {
    return _GptkD3DMetalWindowsDllSource(d3d12Dll: d3d12, dxgiDll: dxgi);
  }

  return null;
}

String? _d3dMetalFrameworkBinary(String frameworkPath) {
  for (final relativePath in const <List<String>>[
    <String>['D3DMetal'],
    <String>['Versions', 'A', 'D3DMetal'],
  ]) {
    final path = _joinPath(frameworkPath, relativePath);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

bool _looksLikeMachO(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 4) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(4);
      if (header.length < 4) {
        return false;
      }
      final magic =
          header[0] << 24 | header[1] << 16 | header[2] << 8 | header[3];
      return magic == 0xfeedface ||
          magic == 0xcefaedfe ||
          magic == 0xfeedfacf ||
          magic == 0xcffaedfe ||
          magic == 0xcafebabe ||
          magic == 0xbebafeca;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

bool _looksLikePE(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 2) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(2);
      return header.length == 2 && header[0] == 0x4d && header[1] == 0x5a;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

RuntimeRecord? _runtimeById(List<RuntimeRecord> runtimes, String runtimeId) {
  for (final runtime in runtimes) {
    if (runtime.id == runtimeId) {
      return runtime;
    }
  }

  return null;
}

String? _runtimeWineVersion(RuntimeRecord runtime) {
  final stack = runtime.stack;
  if (stack == null) {
    return null;
  }

  for (final component in stack.components) {
    if (component.id == 'wine') {
      return component.version;
    }
  }

  return null;
}

String _updateStatus({
  required String? currentVersion,
  required String latestVersion,
}) {
  if (currentVersion == null || currentVersion.trim().isEmpty) {
    return 'unknown';
  }

  if (_normalizeRuntimeVersion(currentVersion) ==
      _normalizeRuntimeVersion(latestVersion)) {
    return 'current';
  }

  return 'available';
}

String _normalizeRuntimeVersion(String version) {
  return version
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^wine-devel-'), '')
      .replaceFirst(RegExp(r'^v'), '');
}

String? _runtimeReleaseVersion(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final tagName = decoded['tag_name'];
  if (tagName is String && tagName.trim().isNotEmpty) {
    return tagName;
  }

  final name = decoded['name'];
  if (name is String && name.trim().isNotEmpty) {
    return name;
  }

  return null;
}

String? _runtimeReleaseArchiveUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  final urls = <String>[];
  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        !_isReleaseMetadataAssetUrl(url)) {
      urls.add(url);
    }
  }

  if (urls.isEmpty) {
    return null;
  }

  for (final extension in const <String>[
    '.tar.xz',
    '.tar.gz',
    '.zip',
    '.dmg',
    '.appimage',
  ]) {
    for (final url in urls) {
      if (url.toLowerCase().contains(extension)) {
        return url;
      }
    }
  }

  return urls.first;
}

String? _runtimeReleaseSourceManifestUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final releaseAssetUrl = _runtimeReleaseMetadataAssetUrl(decoded);
  if (releaseAssetUrl == null) {
    return null;
  }

  final releaseMetadata = _runtimeReleaseEmbeddedMetadata(releaseAssetUrl);
  if (releaseMetadata == null) {
    return null;
  }

  final fileName = _runtimeReleaseSourceManifestFileName(releaseMetadata);
  if (fileName == null) {
    return null;
  }

  final assetUrl = _runtimeReleaseAssetUrlByFileName(decoded, fileName);
  if (assetUrl != null) {
    return assetUrl;
  }

  return _resolveReleaseMetadataAssetUrl(releaseAssetUrl, fileName);
}

String? _runtimeReleaseSourceManifestSignatureUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final releaseAssetUrl = _runtimeReleaseMetadataAssetUrl(decoded);
  if (releaseAssetUrl == null) {
    return null;
  }

  final releaseMetadata = _runtimeReleaseEmbeddedMetadata(releaseAssetUrl);
  if (releaseMetadata == null) {
    return null;
  }

  final fileName = _runtimeReleaseSourceManifestSignatureFileName(
    releaseMetadata,
  );
  if (fileName == null) {
    return null;
  }

  final assetUrl = _runtimeReleaseAssetUrlByFileName(decoded, fileName);
  if (assetUrl != null) {
    return assetUrl;
  }

  return _resolveReleaseMetadataAssetUrl(releaseAssetUrl, fileName);
}

String? _runtimeReleaseMetadataAssetUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        url.trim().toLowerCase().endsWith('.release.json')) {
      return url;
    }
  }

  return null;
}

Map<String, dynamic>? _runtimeReleaseEmbeddedMetadata(String assetUrl) {
  try {
    final result = Process.runSync('curl', [
      '--fail',
      '--location',
      '--silent',
      assetUrl,
    ], runInShell: false);
    if (result.exitCode != 0) {
      return null;
    }

    final decoded = jsonDecode(_processOutputToString(result.stdout));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException {
    return null;
  } on ProcessException {
    return null;
  }

  return null;
}

String? _runtimeReleaseSourceManifestFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return null;
  }

  final fileName = runtimeStack['sourceManifestFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return fileName;
  }

  return null;
}

String? _runtimeReleaseSourceManifestSignatureFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return null;
  }

  final fileName = runtimeStack['signatureFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return fileName;
  }

  return null;
}

String? _runtimeReleaseAssetUrlByFileName(Object? decoded, String fileName) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        _fileNameFromUrl(url) == fileName) {
      return url;
    }
  }

  return null;
}

String? _resolveReleaseMetadataAssetUrl(String metadataUrl, String fileName) {
  final metadataUri = Uri.tryParse(metadataUrl);
  if (metadataUri == null) {
    return null;
  }

  final segments = List<String>.from(metadataUri.pathSegments);
  if (segments.isEmpty) {
    return null;
  }

  segments[segments.length - 1] = fileName;
  return metadataUri.replace(pathSegments: segments).toString();
}

bool _isReleaseMetadataAssetUrl(String url) {
  final normalized = url.trim().toLowerCase();
  return normalized.endsWith('.sha256') ||
      normalized.endsWith('.sha256sum') ||
      normalized.endsWith('.sha256sums') ||
      normalized.endsWith('/sha256sums') ||
      normalized.endsWith('/sha256sum') ||
      normalized.endsWith('.release.json');
}

String? _runtimeReleaseArchiveSha256(Object? decoded, String? archiveUrl) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  for (final key in const <String>['archiveSha256', 'archive_sha256']) {
    final value = decoded[key];
    if (value is String && _isSha256Hex(value)) {
      return value;
    }
  }

  final body = decoded['body'];
  if (body is! String || body.trim().isEmpty) {
    return null;
  }

  final archiveFileName = archiveUrl == null
      ? null
      : _fileNameFromUrl(archiveUrl);
  final digestPattern = RegExp(r'\b[0-9a-fA-F]{64}\b');
  for (final line in const LineSplitter().convert(body)) {
    if (archiveFileName != null && !line.contains(archiveFileName)) {
      continue;
    }

    final digest = digestPattern.firstMatch(line)?.group(0);
    if (digest != null && _isSha256Hex(digest)) {
      return digest;
    }
  }

  if (archiveFileName == null) {
    return digestPattern.firstMatch(body)?.group(0);
  }

  return null;
}

RuntimeValidationCheck _runtimePathCheck({
  required String id,
  required String name,
  required String path,
  required FileStatusProbe fileStatusProbe,
}) {
  final exists = fileStatusProbe.exists(path);
  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: exists,
    message: exists ? 'Found $path.' : 'Missing $path.',
  );
}

RuntimeValidationCheck _runtimeAnyPathCheck({
  required String id,
  required String name,
  required List<String> paths,
  required FileStatusProbe fileStatusProbe,
}) {
  final existingPath = paths
      .where((path) => fileStatusProbe.exists(path))
      .cast<String?>()
      .firstWhere((path) => path != null, orElse: () => null);

  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: existingPath != null,
    message: existingPath != null
        ? 'Found $existingPath.'
        : 'Missing one of: ${paths.join(', ')}.',
  );
}

List<String> _macosWineLoaderLibraryPaths(String runtimeRoot) {
  return <String>[
    _joinPath(runtimeRoot, const ['lib']),
    _joinPath(runtimeRoot, const ['lib64']),
  ];
}

String _runtimeLoaderFailureMessage(RuntimeExecutableProbeResult result) {
  final stderr = result.stderr.trim();
  if (stderr.isNotEmpty) {
    return stderr;
  }

  final stdout = result.stdout.trim();
  if (stdout.isNotEmpty) {
    return stdout;
  }

  return 'wine64 --version exited with code ${result.exitCode}.';
}

bool _isSha256Hex(String value) {
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);
}

String _sha256HexDigest(File file) {
  final outputSink = _DigestSink();
  final inputSink = sha256.startChunkedConversion(outputSink);
  final inputFile = file.openSync();

  try {
    final buffer = Uint8List(64 * 1024);
    while (true) {
      final length = inputFile.readIntoSync(buffer);
      if (length == 0) {
        break;
      }
      inputSink.add(Uint8List.sublistView(buffer, 0, length));
    }
    inputSink.close();
  } finally {
    inputFile.closeSync();
  }

  final digest = outputSink.digest;
  if (digest == null) {
    throw const FormatException('SHA-256 digest was not produced.');
  }

  return digest.toString();
}
