class RuntimeSummary {
  const RuntimeSummary({
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
  final RuntimeStackSummary? stack;
}

class RuntimeStackSummary {
  RuntimeStackSummary({
    required this.id,
    required this.name,
    required this.compatibilityTarget,
    required this.isComplete,
    required List<RuntimeStackComponentSummary> components,
  }) : components = List.unmodifiable(components);

  final String id;
  final String name;
  final String compatibilityTarget;
  final bool isComplete;
  final List<RuntimeStackComponentSummary> components;
}

class RuntimeStackComponentSummary {
  RuntimeStackComponentSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required this.isInstalled,
    required List<String> paths,
    required List<String> missingPaths,
    this.version,
  }) : paths = List.unmodifiable(paths),
       missingPaths = List.unmodifiable(missingPaths);

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final bool isInstalled;
  final List<String> paths;
  final List<String> missingPaths;
  final String? version;
}
