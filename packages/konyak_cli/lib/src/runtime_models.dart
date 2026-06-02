part of '../konyak_cli.dart';

class RuntimeDefinition {
  RuntimeDefinition({
    required this.id,
    required this.name,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    Option<String> distributionKind = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> versionUrl = const Option.none(),
  }) : distributionKind = _optionalRuntimeModelValue(
         distributionKind,
         'distributionKind',
       ),
       archiveUrl = _optionalRuntimeModelValue(archiveUrl, 'archiveUrl'),
       versionUrl = _optionalRuntimeModelValue(versionUrl, 'versionUrl');

  final String id;
  final String name;
  final String platform;
  final String architecture;
  final String runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final Option<String> distributionKind;
  final Option<String> archiveUrl;
  final Option<String> versionUrl;
}

class InstalledRuntimeState {
  InstalledRuntimeState({
    this.isInstalled = const Option.none(),
    Option<String> applicationSupportPath = const Option.none(),
    Option<String> libraryPath = const Option.none(),
    Option<String> executablePath = const Option.none(),
  }) : applicationSupportPath = _optionalRuntimeModelValue(
         applicationSupportPath,
         'applicationSupportPath',
       ),
       libraryPath = _optionalRuntimeModelValue(libraryPath, 'libraryPath'),
       executablePath = _optionalRuntimeModelValue(
         executablePath,
         'executablePath',
       );

  const InstalledRuntimeState.unknown()
    : isInstalled = const Option.none(),
      applicationSupportPath = const Option.none(),
      libraryPath = const Option.none(),
      executablePath = const Option.none();

  final Option<bool> isInstalled;
  final Option<String> applicationSupportPath;
  final Option<String> libraryPath;
  final Option<String> executablePath;
}

class RuntimeCapabilities {
  RuntimeCapabilities({RuntimeStack? stack})
    : stack = Option.fromNullable(stack);

  const RuntimeCapabilities.empty() : stack = const Option.none();

  final Option<RuntimeStack> stack;
}

class RuntimeRecord {
  RuntimeRecord({
    required this.id,
    required this.name,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    String? distributionKind,
    bool? isInstalled,
    String? applicationSupportPath,
    String? libraryPath,
    String? executablePath,
    String? archiveUrl,
    String? versionUrl,
    RuntimeStack? stack,
  }) : distributionKind = _optionalNullableRuntimeModelValue(
         distributionKind,
         'distributionKind',
       ),
       isInstalled = Option.fromNullable(isInstalled),
       applicationSupportPath = _optionalNullableRuntimeModelValue(
         applicationSupportPath,
         'applicationSupportPath',
       ),
       libraryPath = _optionalNullableRuntimeModelValue(
         libraryPath,
         'libraryPath',
       ),
       executablePath = _optionalNullableRuntimeModelValue(
         executablePath,
         'executablePath',
       ),
       archiveUrl = _optionalNullableRuntimeModelValue(
         archiveUrl,
         'archiveUrl',
       ),
       versionUrl = _optionalNullableRuntimeModelValue(
         versionUrl,
         'versionUrl',
       ),
       stack = Option.fromNullable(stack);

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
  final Option<String> distributionKind;
  final Option<bool> isInstalled;
  final Option<String> applicationSupportPath;
  final Option<String> libraryPath;
  final Option<String> executablePath;
  final Option<String> archiveUrl;
  final Option<String> versionUrl;
  final Option<RuntimeStack> stack;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'platform': platform,
      'architecture': architecture,
      'runnerKind': runnerKind,
      'isBundled': isBundled,
      'isUpdateable': isUpdateable,
      ..._runtimeJsonStringField('distributionKind', distributionKind),
      ...isInstalled.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'isInstalled': value},
      ),
      ..._runtimeJsonStringField(
        'applicationSupportPath',
        applicationSupportPath,
      ),
      ..._runtimeJsonStringField('libraryPath', libraryPath),
      ..._runtimeJsonStringField('executablePath', executablePath),
      ...stack.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'stack': value.toJson()},
      ),
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
    String? version,
  }) : paths = List.unmodifiable(paths),
       missingPaths = List.unmodifiable(missingPaths),
       version = _optionalNullableRuntimeModelValue(version, 'version');

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final List<String> paths;
  final List<String> missingPaths;
  final Option<String> version;

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
      ..._runtimeJsonStringField('version', version),
    };
  }
}

Map<String, Object?> _runtimeJsonStringField(String key, Option<String> value) {
  return value.match(
    () => const <String, Object?>{},
    (item) => <String, Object?>{key: item},
  );
}

Option<String> _optionalRuntimeModelValue(
  Option<String> value,
  String fieldName,
) {
  return value.map((item) => _requiredNonBlankDomainString(item, fieldName));
}

Option<String> _optionalNullableRuntimeModelValue(
  String? value,
  String fieldName,
) {
  return _optionalRuntimeModelValue(Option.fromNullable(value), fieldName);
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

  Option<RuntimeSourceComponent> componentById(String id) {
    for (final component in components) {
      if (component.id == id) {
        return Option.of(component);
      }
    }

    return const Option.none();
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
