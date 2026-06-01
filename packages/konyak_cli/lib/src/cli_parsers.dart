part of '../konyak_cli.dart';

bool _isJsonBottleListCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'list-bottles' &&
      arguments.last == '--json';
}

bool _isJsonAppUpdateCheckCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'check-app-update' &&
      arguments.last == '--json';
}

bool _isJsonAppUpdateInstallCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'install-app-update' &&
      arguments.last == '--json';
}

bool _isJsonAppSettingsGetCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'get-app-settings' &&
      arguments.last == '--json';
}

bool _isJsonLinuxFileAssociationInstallCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'install-linux-file-associations' &&
      arguments.last == '--json';
}

AppSettingsRecord? _parseJsonAppSettingsUpdateRequest(List<String> arguments) {
  if (arguments.length != 4 ||
      arguments.first != 'set-app-settings' ||
      arguments[1] != '--settings-json' ||
      arguments.last != '--json') {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(arguments[2]);
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
  return arguments.length == 2 &&
      arguments.first == 'list-wine-processes' &&
      arguments.last == '--json';
}

WineProcessTerminationRequest? _parseJsonWineProcessTerminationRequest(
  List<String> arguments,
) {
  if (arguments.length != 6 ||
      arguments.first != 'terminate-wine-process' ||
      arguments[1] != '--bottle' ||
      arguments[3] != '--process' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[2].trim();
  final processId = arguments[4].trim();
  if (bottleId.isEmpty || processId.isEmpty) {
    return null;
  }

  return WineProcessTerminationRequest(
    bottleId: bottleId,
    processId: processId,
  );
}

WineProcessGroupTerminationRequest?
_parseJsonWineProcessGroupTerminationRequest(List<String> arguments) {
  if (arguments.length == 2 &&
      arguments.first == 'terminate-wine-processes' &&
      arguments.last == '--json') {
    return const WineProcessGroupTerminationRequest();
  }

  if (arguments.length != 4 ||
      arguments.first != 'terminate-wine-processes' ||
      arguments[1] != '--bottle' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[2].trim();
  if (bottleId.isEmpty) {
    return null;
  }

  return WineProcessGroupTerminationRequest(bottleId: bottleId);
}

bool _isJsonBottleInspectCommand(List<String> arguments) {
  return arguments.length == 3 &&
      arguments.first == 'inspect-bottle' &&
      arguments[1].isNotEmpty &&
      arguments.last == '--json';
}

String? _parseJsonBottleProgramsListCommand(List<String> arguments) {
  if (arguments.length != 3 ||
      arguments.first != 'list-bottle-programs' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  return bottleId.isEmpty ? null : bottleId;
}

bool _isJsonWinetricksVerbListCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'list-winetricks-verbs' &&
      arguments.last == '--json';
}

BottleCreateRequest? _parseJsonBottleCreateRequest(List<String> arguments) {
  if (arguments.length != 4 && arguments.length != 6) {
    return null;
  }

  if (arguments.first != 'create-bottle' ||
      arguments[1] != '--name' ||
      arguments.last != '--json') {
    return null;
  }

  final name = arguments[2].trim();
  if (name.isEmpty) {
    return null;
  }

  if (arguments.length == 4) {
    return BottleCreateRequest(name: name, windowsVersion: 'win10');
  }

  if (arguments[3] != '--windows-version') {
    return null;
  }

  final windowsVersion = arguments[4].trim();
  if (windowsVersion.isEmpty) {
    return null;
  }

  return BottleCreateRequest(name: name, windowsVersion: windowsVersion);
}

BottleArchiveExportRequest? _parseJsonBottleArchiveExportRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'export-bottle-archive' ||
      arguments[2] != '--archive' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final archivePath = arguments[3].trim();
  if (bottleId.isEmpty || archivePath.isEmpty) {
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
  if (arguments.length != 4 ||
      arguments.first != 'import-bottle-archive' ||
      arguments[1] != '--archive' ||
      arguments.last != '--json') {
    return null;
  }

  final archivePath = arguments[2].trim();
  if (archivePath.isEmpty) {
    return null;
  }

  return BottleArchiveImportRequest(archivePath: archivePath);
}

String? _parseJsonBottleDeleteCommand(List<String> arguments) {
  if (arguments.length != 3 ||
      arguments.first != 'delete-bottle' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  return bottleId.isEmpty ? null : bottleId;
}

BottleRenameRequest? _parseJsonBottleRenameRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'rename-bottle' ||
      arguments[2] != '--name' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final name = arguments[3].trim();
  if (bottleId.isEmpty || name.isEmpty) {
    return null;
  }

  return BottleRenameRequest(bottleId: bottleId, name: name);
}

BottleMoveRequest? _parseJsonBottleMoveRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'move-bottle' ||
      arguments[2] != '--path' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final path = arguments[3].trim();
  if (bottleId.isEmpty || path.isEmpty) {
    return null;
  }

  return BottleMoveRequest(bottleId: bottleId, path: path);
}

WindowsVersionUpdateRequest? _parseJsonWindowsVersionUpdateRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'set-windows-version' ||
      arguments[2] != '--windows-version' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final windowsVersion = arguments[3].trim();

  if (bottleId.isEmpty || windowsVersion.isEmpty) {
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
  if (arguments.length != 5 ||
      arguments.first != 'set-runtime-settings' ||
      arguments[2] != '--settings-json' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  if (bottleId.isEmpty) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(arguments[3]);
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
  if (arguments.length != 7 ||
      arguments.first != 'pin-program' ||
      arguments[2] != '--name' ||
      arguments[4] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final name = arguments[3].trim();
  final programPath = arguments[5].trim();
  if (bottleId.isEmpty || name.isEmpty || programPath.isEmpty) {
    return null;
  }

  return ProgramPinRequest(
    bottleId: bottleId,
    name: name,
    programPath: programPath,
  );
}

ProgramUnpinRequest? _parseJsonProgramUnpinRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'unpin-program' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return ProgramUnpinRequest(bottleId: bottleId, programPath: programPath);
}

ProgramRenameRequest? _parseJsonProgramRenameRequest(List<String> arguments) {
  if (arguments.length != 7 ||
      arguments.first != 'rename-pinned-program' ||
      arguments[2] != '--program' ||
      arguments[4] != '--name' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  final name = arguments[5].trim();
  if (bottleId.isEmpty || programPath.isEmpty || name.isEmpty) {
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
  if (arguments.length != 5 ||
      arguments.first != 'get-program-settings' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return ProgramSettingsRequest(bottleId: bottleId, programPath: programPath);
}

ProgramSettingsUpdateRequest? _parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  if (arguments.length != 7 ||
      arguments.first != 'set-program-settings' ||
      arguments[2] != '--program' ||
      arguments[4] != '--settings-json' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(arguments[5]);
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
  return arguments.length == 2 &&
      arguments.first == 'list-runtimes' &&
      arguments.last == '--json';
}

bool _isJsonMacosSetupCheckCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'check-macos-setup' &&
      arguments.last == '--json';
}

GptkWineInstallRequest? _parseJsonGptkWineInstallRequest(
  List<String> arguments,
) {
  if (arguments.length != 4 ||
      arguments.first != 'install-gptk-wine' ||
      arguments[1] != '--from' ||
      arguments.last != '--json') {
    return null;
  }

  final sourcePath = arguments[2].trim();
  if (sourcePath.isEmpty) {
    return null;
  }

  return GptkWineInstallRequest(sourcePath: sourcePath);
}

String? _parseJsonOpenUrlCommand(List<String> arguments) {
  if (arguments.length != 3 ||
      arguments.first != 'open-url' ||
      arguments.last != '--json') {
    return null;
  }

  final url = arguments[1].trim();
  if (url.startsWith('https://') || url.startsWith('http://')) {
    return url;
  }

  return null;
}

String? _parseJsonRuntimeIdCommand(List<String> arguments, String command) {
  if (arguments.length != 3 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return null;
  }

  final runtimeId = arguments[1].trim();
  if (runtimeId.isEmpty) {
    return null;
  }

  return runtimeId;
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
  if (arguments.length != 5 ||
      arguments.first != 'run-program' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();

  if (bottleId.isEmpty || programPath.isEmpty) {
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
  if (arguments.length != 4 ||
      arguments.first != 'launch-pinned-program' ||
      arguments[1] != '--manifest' ||
      arguments.last != '--json') {
    return null;
  }

  final manifestPath = arguments[2].trim();
  if (manifestPath.isEmpty) {
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
  if (arguments.length != 5 ||
      arguments.first != 'run-winetricks' ||
      arguments[2] != '--verb' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final verb = arguments[3].trim();

  if (bottleId.isEmpty || verb.isEmpty) {
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
  if (arguments.length != 5 ||
      arguments.first != 'run-bottle-command' ||
      arguments[2] != '--command' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final command = arguments[3].trim();

  if (bottleId.isEmpty || command.isEmpty) {
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
  if (arguments.length != 5 ||
      arguments.first != 'open-bottle-location' ||
      arguments[2] != '--location' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final location = arguments[3].trim();

  if (bottleId.isEmpty || location.isEmpty) {
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
  if (arguments.length != 5 ||
      arguments.first != 'open-program-location' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();

  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return _ProgramLocationOpenCliRequest(
    bottleId: bottleId,
    programPath: programPath,
  );
}
