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
  final RuntimeStackSummary? stack;
}

class RuntimeStackSummary {
  RuntimeStackSummary({
    required this.id,
    required this.name,
    required this.compatibilityTarget,
    required List<RuntimeStackComponentSummary> components,
    List<RuntimeStackBackendSummary> backends =
        const <RuntimeStackBackendSummary>[],
  }) : components = List.unmodifiable(components),
       backends = List.unmodifiable(backends);

  final String id;
  final String name;
  final String compatibilityTarget;
  final List<RuntimeStackComponentSummary> components;
  final List<RuntimeStackBackendSummary> backends;

  bool get isComplete {
    return components
        .where((component) => component.isRequired)
        .every((component) => component.isInstalled);
  }
}

class RuntimeStackBackendSummary {
  RuntimeStackBackendSummary({
    required this.id,
    required this.name,
    required this.role,
    required List<String> componentIds,
    required List<String> missingComponentIds,
    required List<String> missingPaths,
  }) : componentIds = List.unmodifiable(componentIds),
       missingComponentIds = List.unmodifiable(missingComponentIds),
       missingPaths = List.unmodifiable(missingPaths);

  final String id;
  final String name;
  final String role;
  final List<String> componentIds;
  final List<String> missingComponentIds;
  final List<String> missingPaths;

  bool get isAvailable {
    return missingComponentIds.isEmpty && missingPaths.isEmpty;
  }
}

class RuntimeStackComponentSummary {
  RuntimeStackComponentSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required List<String> paths,
    required List<String> missingPaths,
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
}
