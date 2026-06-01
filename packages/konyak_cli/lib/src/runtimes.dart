part of '../konyak_cli.dart';

class RuntimeDefinition {
  const RuntimeDefinition({
    required this.id,
    required this.name,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    this.distributionKind,
    this.archiveUrl,
    this.versionUrl,
  });

  final String id;
  final String name;
  final String platform;
  final String architecture;
  final String runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final String? distributionKind;
  final String? archiveUrl;
  final String? versionUrl;
}

class InstalledRuntimeState {
  const InstalledRuntimeState({
    this.isInstalled,
    this.applicationSupportPath,
    this.libraryPath,
    this.executablePath,
  });

  const InstalledRuntimeState.unknown()
    : isInstalled = null,
      applicationSupportPath = null,
      libraryPath = null,
      executablePath = null;

  final bool? isInstalled;
  final String? applicationSupportPath;
  final String? libraryPath;
  final String? executablePath;
}

class RuntimeCapabilities {
  const RuntimeCapabilities({this.stack});

  const RuntimeCapabilities.empty() : stack = null;

  final RuntimeStack? stack;
}

class RuntimeRecord {
  const RuntimeRecord({
    required this.id,
    required this.name,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    this.distributionKind,
    this.isInstalled,
    this.applicationSupportPath,
    this.libraryPath,
    this.executablePath,
    this.archiveUrl,
    this.versionUrl,
    this.stack,
  });

  RuntimeRecord.fromParts({
    required RuntimeDefinition definition,
    InstalledRuntimeState installedState =
        const InstalledRuntimeState.unknown(),
    RuntimeCapabilities capabilities = const RuntimeCapabilities.empty(),
  }) : id = definition.id,
       name = definition.name,
       platform = definition.platform,
       architecture = definition.architecture,
       runnerKind = definition.runnerKind,
       isBundled = definition.isBundled,
       isUpdateable = definition.isUpdateable,
       distributionKind = definition.distributionKind,
       isInstalled = installedState.isInstalled,
       applicationSupportPath = installedState.applicationSupportPath,
       libraryPath = installedState.libraryPath,
       executablePath = installedState.executablePath,
       archiveUrl = definition.archiveUrl,
       versionUrl = definition.versionUrl,
       stack = capabilities.stack;

  final String id;
  final String name;
  final String platform;
  final String architecture;
  final String runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final String? distributionKind;
  final bool? isInstalled;
  final String? applicationSupportPath;
  final String? libraryPath;
  final String? executablePath;
  final String? archiveUrl;
  final String? versionUrl;
  final RuntimeStack? stack;

  Map<String, Object?> toJson() {
    final runtimeStack = stack;

    return <String, Object?>{
      'id': id,
      'name': name,
      'platform': platform,
      'architecture': architecture,
      'runnerKind': runnerKind,
      'isBundled': isBundled,
      'isUpdateable': isUpdateable,
      if (distributionKind != null) 'distributionKind': distributionKind,
      if (isInstalled != null) 'isInstalled': isInstalled,
      if (applicationSupportPath != null)
        'applicationSupportPath': applicationSupportPath,
      if (libraryPath != null) 'libraryPath': libraryPath,
      if (executablePath != null) 'executablePath': executablePath,
      if (runtimeStack != null) 'stack': runtimeStack.toJson(),
    };
  }
}

class RuntimeStack {
  RuntimeStack({
    required this.id,
    required this.name,
    required this.compatibilityTarget,
    required Iterable<RuntimeStackComponent> components,
  }) : components = List.unmodifiable(components);

  final String id;
  final String name;
  final String compatibilityTarget;
  final List<RuntimeStackComponent> components;

  bool get isComplete {
    return components
        .where((component) => component.isRequired)
        .every((component) => component.isInstalled);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': runtimeStackSchemaVersion,
      'id': id,
      'name': name,
      'compatibilityTarget': compatibilityTarget,
      'isComplete': isComplete,
      'components': components
          .map((component) => component.toJson())
          .toList(growable: false),
    };
  }
}

class RuntimeStackComponent {
  RuntimeStackComponent({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required Iterable<String> paths,
    required Iterable<String> missingPaths,
    this.version,
  }) : paths = List.unmodifiable(paths),
       missingPaths = List.unmodifiable(missingPaths);

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final List<String> paths;
  final List<String> missingPaths;
  final String? version;

  bool get isInstalled {
    return missingPaths.isEmpty;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'role': role,
      'isRequired': isRequired,
      'isInstalled': isInstalled,
      'paths': paths,
      'missingPaths': missingPaths,
      if (version != null) 'version': version,
    };
  }
}

class RuntimeSourceManifest {
  RuntimeSourceManifest({
    required this.runtimeId,
    required this.stackId,
    required Iterable<RuntimeSourceComponent> components,
  }) : components = List.unmodifiable(components);

  final String runtimeId;
  final String stackId;
  final List<RuntimeSourceComponent> components;

  RuntimeSourceComponent? componentById(String id) {
    for (final component in components) {
      if (component.id == id) {
        return component;
      }
    }

    return null;
  }
}

class RuntimeSourceComponent {
  const RuntimeSourceComponent({
    required this.id,
    required this.version,
    required this.archiveUrl,
    required this.sha256,
  });

  final String id;
  final String version;
  final String archiveUrl;
  final String sha256;
}

class _RuntimeStackSourceArchiveBundle {
  const _RuntimeStackSourceArchiveBundle({
    required this.wineArchivePath,
    required this.componentArchivePaths,
    required this.componentVersions,
  });

  final String wineArchivePath;
  final List<String> componentArchivePaths;
  final Map<String, String> componentVersions;
}

sealed class _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleResult();
}

class _RuntimeStackSourceArchiveBundleResolved
    extends _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleResolved(this.bundle);

  final _RuntimeStackSourceArchiveBundle bundle;
}

class _RuntimeStackSourceArchiveBundleFailed
    extends _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleFailed(this.message);

  final String message;
}

abstract interface class RuntimeCatalog {
  List<RuntimeRecord> listRuntimes();
}

class StaticRuntimeCatalog implements RuntimeCatalog {
  const StaticRuntimeCatalog(this._runtimes);

  final List<RuntimeRecord> _runtimes;

  @override
  List<RuntimeRecord> listRuntimes() {
    return List.unmodifiable(_runtimes);
  }
}

abstract interface class FileStatusProbe {
  bool exists(String path);
}

abstract interface class RuntimeStackVersionProbe {
  String? versionFor({
    required String runtimeRoot,
    required String componentId,
  });
}

class DartIoFileStatusProbe implements FileStatusProbe {
  const DartIoFileStatusProbe();

  @override
  bool exists(String path) {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }
}

class DartIoRuntimeStackVersionProbe implements RuntimeStackVersionProbe {
  const DartIoRuntimeStackVersionProbe();

  @override
  String? versionFor({
    required String runtimeRoot,
    required String componentId,
  }) {
    final manifest = File(
      _joinPath(runtimeRoot, const [runtimeStackManifestFileName]),
    );
    if (!manifest.existsSync()) {
      return null;
    }

    try {
      final decoded = jsonDecode(manifest.readAsStringSync());
      return _runtimeStackComponentVersion(decoded, componentId);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }
}

class MacosWineRuntimeCatalog implements RuntimeCatalog {
  MacosWineRuntimeCatalog({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe;

  factory MacosWineRuntimeCatalog.current() {
    return MacosWineRuntimeCatalog(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        _macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => const <RuntimeRecord>[],
    };
  }
}

class KonyakRuntimeCatalog implements RuntimeCatalog {
  KonyakRuntimeCatalog({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe;

  factory KonyakRuntimeCatalog.current() {
    return KonyakRuntimeCatalog(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        _macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => <RuntimeRecord>[
        _linuxWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
    };
  }
}
