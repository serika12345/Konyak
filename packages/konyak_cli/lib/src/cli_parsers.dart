part of '../konyak_cli.dart';

bool _isJsonFlagOnlyCommand(List<String> arguments, String command) {
  final results = _parseJsonCliCommand(arguments, command: command);
  return results != null && results.rest.isEmpty;
}

ArgResults? _parseJsonCliCommand(
  List<String> arguments, {
  required String command,
  Iterable<String> options = const <String>[],
  Iterable<String> multiOptions = const <String>[],
  Iterable<String> flags = const <String>[],
}) {
  if (arguments.length < 2 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return null;
  }

  final parser = ArgParser();
  for (final option in options) {
    parser.addOption(option);
  }
  for (final option in multiOptions) {
    parser.addMultiOption(option);
  }
  for (final flag in flags) {
    parser.addFlag(flag, negatable: false);
  }
  parser.addFlag('json', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments.sublist(1));
  } on FormatException {
    return null;
  }

  if (results['json'] != true) {
    return null;
  }

  return results;
}

String? _requiredCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  final value = results[name] as String?;
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _optionalCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return null;
  }

  return _requiredCliOption(results, name);
}

String? _requiredCliRest(ArgResults results, {int index = 0}) {
  if (results.rest.length <= index) {
    return null;
  }

  final value = results.rest[index].trim();
  return value.isEmpty ? null : value;
}

bool _hasRestCount(ArgResults results, int count) {
  return results.rest.length == count;
}

bool _hasEmptyParsedCliOption(ArgResults results, String name) {
  if (!results.wasParsed(name)) {
    return false;
  }

  final value = results[name] as String?;
  return value == null || value.trim().isEmpty;
}

bool _isJsonBottleListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-bottles');
}

bool _isJsonAppUpdateCheckCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'check-app-update');
}

bool _isJsonAppUpdateInstallCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'install-app-update');
}

bool _isJsonAppSettingsGetCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'get-app-settings');
}

bool _isJsonLinuxFileAssociationInstallCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'install-linux-file-associations');
}

AppSettingsRecord? _parseJsonAppSettingsUpdateRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-app-settings',
    options: const <String>['settings-json'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }
  final settingsJson = _requiredCliOption(results, 'settings-json');
  if (settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  final settings = AppSettingsRecord.fromJson(
    decoded,
    fallbackDefaultBottlePath: '',
  );
  if (settings == null || settings.defaultBottlePath.trim().isEmpty) {
    return null;
  }

  return settings;
}

bool _isJsonWineProcessListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-wine-processes');
}

WineProcessTerminationRequest? _parseJsonWineProcessTerminationRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'terminate-wine-process',
    options: const <String>['bottle', 'process'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final bottleId = _requiredCliOption(results, 'bottle');
  final processId = _requiredCliOption(results, 'process');
  if (bottleId == null || processId == null) {
    return null;
  }

  return WineProcessTerminationRequest(
    bottleId: bottleId,
    processId: processId,
  );
}

WineProcessGroupTerminationRequest?
_parseJsonWineProcessGroupTerminationRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'terminate-wine-processes',
    options: const <String>['bottle'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final bottleId = _optionalCliOption(results, 'bottle');
  if (bottleId == null) {
    return results.wasParsed('bottle')
        ? null
        : const WineProcessGroupTerminationRequest();
  }

  return WineProcessGroupTerminationRequest(bottleId: bottleId);
}

bool _isJsonBottleInspectCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(arguments, command: 'inspect-bottle');
  return results != null &&
      _hasRestCount(results, 1) &&
      _requiredCliRest(results) != null;
}

String? _parseJsonBottleProgramsListCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'list-bottle-programs',
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  return _requiredCliRest(results);
}

bool _isJsonWinetricksVerbListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-winetricks-verbs');
}

BottleCreateRequest? _parseJsonBottleCreateRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'create-bottle',
    options: const <String>['name', 'windows-version'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final name = _requiredCliOption(results, 'name');
  if (name == null) {
    return null;
  }

  final windowsVersion = _optionalCliOption(results, 'windows-version');
  if (windowsVersion == null) {
    if (results.wasParsed('windows-version')) {
      return null;
    }
    return BottleCreateRequest(name: name, windowsVersion: 'win10');
  }

  return BottleCreateRequest(name: name, windowsVersion: windowsVersion);
}

BottleArchiveExportRequest? _parseJsonBottleArchiveExportRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'export-bottle-archive',
    options: const <String>['archive'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final archivePath = _requiredCliOption(results, 'archive');
  if (bottleId == null || archivePath == null) {
    return null;
  }

  return BottleArchiveExportRequest(
    bottleId: bottleId,
    archivePath: archivePath,
  );
}

BottleArchiveImportRequest? _parseJsonBottleArchiveImportRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'import-bottle-archive',
    options: const <String>['archive'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final archivePath = _requiredCliOption(results, 'archive');
  if (archivePath == null) {
    return null;
  }

  return BottleArchiveImportRequest(archivePath: archivePath);
}

String? _parseJsonBottleDeleteCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(arguments, command: 'delete-bottle');
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  return _requiredCliRest(results);
}

BottleRenameRequest? _parseJsonBottleRenameRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'rename-bottle',
    options: const <String>['name'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final name = _requiredCliOption(results, 'name');
  if (bottleId == null || name == null) {
    return null;
  }

  return BottleRenameRequest(bottleId: bottleId, name: name);
}

BottleMoveRequest? _parseJsonBottleMoveRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'move-bottle',
    options: const <String>['path'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final path = _requiredCliOption(results, 'path');
  if (bottleId == null || path == null) {
    return null;
  }

  return BottleMoveRequest(bottleId: bottleId, path: path);
}

WindowsVersionUpdateRequest? _parseJsonWindowsVersionUpdateRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-windows-version',
    options: const <String>['windows-version'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final windowsVersion = _requiredCliOption(results, 'windows-version');
  if (bottleId == null || windowsVersion == null) {
    return null;
  }

  return WindowsVersionUpdateRequest(
    bottleId: bottleId,
    windowsVersion: windowsVersion,
  );
}

RuntimeSettingsUpdateRequest? _parseJsonRuntimeSettingsUpdateRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-runtime-settings',
    options: const <String>['settings-json'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final settingsJson = _requiredCliOption(results, 'settings-json');
  if (bottleId == null || settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  if (decoded == null) {
    return null;
  }

  final runtimeSettings = BottleRuntimeSettings.fromJson(decoded);
  if (runtimeSettings == null) {
    return null;
  }

  return RuntimeSettingsUpdateRequest(
    bottleId: bottleId,
    runtimeSettings: runtimeSettings,
  );
}

ProgramPinRequest? _parseJsonProgramPinRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'pin-program',
    options: const <String>['name', 'program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final name = _requiredCliOption(results, 'name');
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || name == null || programPath == null) {
    return null;
  }

  return ProgramPinRequest(
    bottleId: bottleId,
    name: name,
    programPath: programPath,
  );
}

ProgramUnpinRequest? _parseJsonProgramUnpinRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'unpin-program',
    options: const <String>['program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramUnpinRequest(bottleId: bottleId, programPath: programPath);
}

ProgramRenameRequest? _parseJsonProgramRenameRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'rename-pinned-program',
    options: const <String>['program', 'name'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  final name = _requiredCliOption(results, 'name');
  if (bottleId == null || programPath == null || name == null) {
    return null;
  }

  return ProgramRenameRequest(
    bottleId: bottleId,
    programPath: programPath,
    name: name,
  );
}

ProgramSettingsRequest? _parseJsonProgramSettingsRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'get-program-settings',
    options: const <String>['program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramSettingsRequest(bottleId: bottleId, programPath: programPath);
}

ProgramSettingsUpdateRequest? _parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-program-settings',
    options: const <String>['program', 'settings-json'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  final settingsJson = _requiredCliOption(results, 'settings-json');
  if (bottleId == null || programPath == null || settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  final settings = ProgramSettingsRecord.fromJson(decoded);
  if (settings == null) {
    return null;
  }

  return ProgramSettingsUpdateRequest(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

bool _isJsonRuntimeListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-runtimes');
}

bool _isJsonMacosSetupCheckCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'check-macos-setup');
}

GptkWineInstallRequest? _parseJsonGptkWineInstallRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'install-gptk-wine',
    options: const <String>['from'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final sourcePath = _requiredCliOption(results, 'from');
  if (sourcePath == null) {
    return null;
  }

  return GptkWineInstallRequest(sourcePath: sourcePath);
}

String? _parseJsonOpenUrlCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(arguments, command: 'open-url');
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final url = _requiredCliRest(results);
  if (url != null &&
      (url.startsWith('https://') || url.startsWith('http://'))) {
    return url;
  }

  return null;
}

String? _parseJsonRuntimeIdCommand(List<String> arguments, String command) {
  final results = _parseJsonCliCommand(arguments, command: command);
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  return _requiredCliRest(results);
}

MacosWineInstallRequest? _parseJsonMacosWineInstallRequest(
  List<String> arguments,
) {
  final options = _parseRuntimeInstallCliOptions(
    arguments,
    command: 'install-macos-wine',
  );
  if (options == null) {
    return null;
  }

  if (options.componentArchivePaths.isNotEmpty) {
    return MacosWineInstallRequest.componentInstall(
      archivePath: options.archivePath,
      archiveUrl: options.archiveUrl,
      archiveSha256: options.archiveSha256,
      componentArchivePaths: options.componentArchivePaths,
      emitProgress: options.emitProgress,
    );
  }

  return MacosWineInstallRequest.fullInstall(
    archivePath: options.archivePath,
    archiveUrl: options.archiveUrl,
    archiveSha256: options.archiveSha256,
    sourceManifest: options.sourceManifest,
    emitProgress: options.emitProgress,
  );
}

LinuxWineInstallRequest? _parseJsonLinuxWineInstallRequest(
  List<String> arguments,
) {
  final options = _parseRuntimeInstallCliOptions(
    arguments,
    command: 'install-linux-wine',
  );
  if (options == null) {
    return null;
  }

  if (options.componentArchivePaths.isNotEmpty) {
    return LinuxWineInstallRequest.componentInstall(
      archivePath: options.archivePath,
      archiveUrl: options.archiveUrl,
      archiveSha256: options.archiveSha256,
      componentArchivePaths: options.componentArchivePaths,
      emitProgress: options.emitProgress,
    );
  }

  return LinuxWineInstallRequest.fullInstall(
    archivePath: options.archivePath,
    archiveUrl: options.archiveUrl,
    archiveSha256: options.archiveSha256,
    sourceManifest: options.sourceManifest,
    emitProgress: options.emitProgress,
  );
}

class _RuntimeInstallCliOptions {
  _RuntimeInstallCliOptions({
    required this.componentArchivePaths,
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.emitProgress = false,
  });

  final String? archivePath;
  final String? archiveUrl;
  final String? archiveSha256;
  final List<String> componentArchivePaths;
  final String? sourceManifest;
  final bool emitProgress;
}

_RuntimeInstallCliOptions? _parseRuntimeInstallCliOptions(
  List<String> arguments, {
  required String command,
}) {
  if (arguments.length < 2 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return null;
  }

  final parser = ArgParser(allowTrailingOptions: false)
    ..addOption('archive')
    ..addOption('archive-url')
    ..addOption('archive-sha256')
    ..addMultiOption('component-archive')
    ..addOption('source-manifest')
    ..addFlag('progress-json', negatable: false)
    ..addFlag('json', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments.sublist(1));
  } on FormatException {
    return null;
  }

  if (results.rest.isNotEmpty || results['json'] != true) {
    return null;
  }

  for (final name in const <String>[
    'archive',
    'archive-url',
    'archive-sha256',
    'source-manifest',
  ]) {
    if (_hasEmptyParsedCliOption(results, name)) {
      return null;
    }
  }

  final archivePath = _nonEmptyCliOption(results, 'archive');
  final archiveUrl = _nonEmptyCliOption(results, 'archive-url');
  final archiveSha256 = _nonEmptyCliOption(results, 'archive-sha256');
  final sourceManifest = _nonEmptyCliOption(results, 'source-manifest');
  final componentArchivePaths = _nonEmptyCliMultiOption(
    results,
    'component-archive',
  );
  if (componentArchivePaths == null) {
    return null;
  }

  if (archivePath != null && archiveUrl != null) {
    return null;
  }
  if (archiveSha256 != null && !_isSha256Hex(archiveSha256)) {
    return null;
  }
  if (sourceManifest != null &&
      (archivePath != null ||
          archiveUrl != null ||
          archiveSha256 != null ||
          componentArchivePaths.isNotEmpty)) {
    return null;
  }

  return _RuntimeInstallCliOptions(
    archivePath: archivePath,
    archiveUrl: archiveUrl,
    archiveSha256: archiveSha256,
    componentArchivePaths: componentArchivePaths,
    sourceManifest: sourceManifest,
    emitProgress: results['progress-json'] == true,
  );
}

String? _nonEmptyCliOption(ArgResults results, String name) {
  final value = results[name] as String?;
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

List<String>? _nonEmptyCliMultiOption(ArgResults results, String name) {
  final values = results[name] as List<String>;
  final normalized = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    normalized.add(trimmed);
  }

  return List.unmodifiable(normalized);
}

class _ProgramRunCliRequest {
  const _ProgramRunCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

_ProgramRunCliRequest? _parseJsonProgramRunCliRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'run-program',
    options: const <String>['program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return _ProgramRunCliRequest(bottleId: bottleId, programPath: programPath);
}

class _PinnedProgramLaunchCliRequest {
  const _PinnedProgramLaunchCliRequest({required this.manifestPath});

  final String manifestPath;
}

_PinnedProgramLaunchCliRequest? _parseJsonPinnedProgramLaunchCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'launch-pinned-program',
    options: const <String>['manifest'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final manifestPath = _requiredCliOption(results, 'manifest');
  if (manifestPath == null) {
    return null;
  }

  return _PinnedProgramLaunchCliRequest(manifestPath: manifestPath);
}

class _WinetricksRunCliRequest {
  const _WinetricksRunCliRequest({required this.bottleId, required this.verb});

  final String bottleId;
  final String verb;
}

_WinetricksRunCliRequest? _parseJsonWinetricksRunCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'run-winetricks',
    options: const <String>['verb'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final verb = _requiredCliOption(results, 'verb');
  if (bottleId == null || verb == null) {
    return null;
  }

  return _WinetricksRunCliRequest(bottleId: bottleId, verb: verb);
}

class _BottleCommandRunCliRequest {
  const _BottleCommandRunCliRequest({
    required this.bottleId,
    required this.command,
  });

  final String bottleId;
  final String command;
}

_BottleCommandRunCliRequest? _parseJsonBottleCommandRunCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'run-bottle-command',
    options: const <String>['command'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final command = _requiredCliOption(results, 'command');
  if (bottleId == null || command == null) {
    return null;
  }

  return _BottleCommandRunCliRequest(bottleId: bottleId, command: command);
}

class _BottleLocationOpenCliRequest {
  const _BottleLocationOpenCliRequest({
    required this.bottleId,
    required this.location,
  });

  final String bottleId;
  final String location;
}

_BottleLocationOpenCliRequest? _parseJsonBottleLocationOpenCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'open-bottle-location',
    options: const <String>['location'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final location = _requiredCliOption(results, 'location');
  if (bottleId == null || location == null) {
    return null;
  }

  return _BottleLocationOpenCliRequest(bottleId: bottleId, location: location);
}

class _ProgramLocationOpenCliRequest {
  const _ProgramLocationOpenCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

_ProgramLocationOpenCliRequest? _parseJsonProgramLocationOpenCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'open-program-location',
    options: const <String>['program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return _ProgramLocationOpenCliRequest(
    bottleId: bottleId,
    programPath: programPath,
  );
}
