part of 'konyak_cli_client.dart';

sealed class _BottleDeleteParseResult {
  const _BottleDeleteParseResult();
}

BottleArchiveExportLoadResult _parseBottleArchiveExportPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle archive export payload.',
      diagnostic: '',
    );
  }

  final archive = decoded['bottleArchive'];
  if (archive is! Map<String, Object?>) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Missing bottleArchive payload.',
      diagnostic: '',
    );
  }

  final bottleId = archive['bottleId'];
  final archivePath = archive['archivePath'];
  if (bottleId is! String || archivePath is! String) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Invalid bottleArchive payload.',
      diagnostic: '',
    );
  }

  return ExportedBottleArchive(bottleId: bottleId, archivePath: archivePath);
}

final class _ParsedBottleDelete extends _BottleDeleteParseResult {
  const _ParsedBottleDelete(this.bottle);

  final BottleSummary bottle;
}

final class _BottleDeleteNotFound extends _BottleDeleteParseResult {
  const _BottleDeleteNotFound({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class _BottleDeleteParseFailure extends _BottleDeleteParseResult {
  const _BottleDeleteParseFailure(this.message);

  final String message;
}

_BottleDeleteParseResult _parseBottleDeletePayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload must be an object.',
    );
  }

  if (decoded['schemaVersion'] != 1) {
    return const _BottleDeleteParseFailure(
      'Unsupported bottle delete schema version.',
    );
  }

  final notFound = _parseBottleDeleteNotFound(decoded['error']);
  if (notFound != null) {
    return notFound;
  }

  final bottle = parseBottleSummary(decoded['deletedBottle']);
  if (bottle == null) {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload contains an invalid bottle record.',
    );
  }

  return _ParsedBottleDelete(bottle);
}

_BottleDeleteNotFound? _parseBottleDeleteNotFound(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleNotFound' || message is! String || bottleId is! String) {
    return null;
  }

  return _BottleDeleteNotFound(bottleId: bottleId, message: message);
}

BottleLocationOpenResult _parseBottleLocationOpenPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleLocationOpenFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Unsupported bottle location open payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleLocationOpenFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle location open failed.',
      diagnostic: '',
    );
  }

  final openedLocation = decoded['openedLocation'];
  if (openedLocation is! Map<String, Object?>) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Missing openedLocation payload.',
      diagnostic: '',
    );
  }

  final bottleId = openedLocation['bottleId'];
  final location = openedLocation['location'];
  final path = openedLocation['path'];
  if (bottleId is! String || location is! String || path is! String) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Invalid openedLocation payload.',
      diagnostic: '',
    );
  }

  return OpenedBottleLocation(
    bottleId: bottleId,
    location: location,
    path: path,
  );
}

ProgramLocationOpenResult _parseProgramLocationOpenPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramLocationOpenFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Unsupported program location open payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return ProgramLocationOpenFailure(
      exitCode: 0,
      message: message is String ? message : 'Program location open failed.',
      diagnostic: '',
    );
  }

  final openedLocation = decoded['openedProgramLocation'];
  if (openedLocation is! Map<String, Object?>) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Missing openedProgramLocation payload.',
      diagnostic: '',
    );
  }

  final bottleId = openedLocation['bottleId'];
  final programPath = openedLocation['programPath'];
  final path = openedLocation['path'];
  if (bottleId is! String || programPath is! String || path is! String) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Invalid openedProgramLocation payload.',
      diagnostic: '',
    );
  }

  return OpenedProgramLocation(
    bottleId: bottleId,
    programPath: programPath,
    path: path,
  );
}

ProgramSettingsLoadResult _parseProgramSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported program settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final code = error['code'];
    final bottleId = error['bottleId'];
    final message = error['message'];
    if (code == 'bottleNotFound' && bottleId is String && message is String) {
      return MissingProgramSettingsBottle(bottleId: bottleId, message: message);
    }

    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Program settings failed.',
      diagnostic: '',
    );
  }

  final programSettings = decoded['programSettings'];
  if (programSettings is! Map<String, Object?>) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Missing programSettings payload.',
      diagnostic: '',
    );
  }

  final bottleId = programSettings['bottleId'];
  final programPath = programSettings['programPath'];
  final settings = _parseProgramSettingsSummary(programSettings['settings']);
  if (bottleId is! String || programPath is! String || settings == null) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid programSettings payload.',
      diagnostic: '',
    );
  }

  return LoadedProgramSettings(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

AppSettingsLoadResult _parseAppSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported app settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'App settings failed.',
      diagnostic: '',
    );
  }

  final settings = _parseAppSettingsSummary(decoded['appSettings']);
  if (settings == null) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid appSettings payload.',
      diagnostic: '',
    );
  }

  return LoadedAppSettings(settings);
}

UpdateCheckLoadResult _parseUpdateCheckPayload({
  required String payload,
  required String payloadKey,
  required String idKey,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return UpdateCheckLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Unsupported update check payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return UpdateCheckLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Update check failed.',
      diagnostic: '',
    );
  }

  final update = decoded[payloadKey];
  if (update is! Map<String, Object?>) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Missing update check payload.',
      diagnostic: '',
    );
  }

  final parsedUpdate = _parseUpdateCheckSummary(update, idKey: idKey);
  if (parsedUpdate == null) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Invalid update check payload.',
      diagnostic: '',
    );
  }

  return LoadedUpdateCheck(parsedUpdate);
}

UpdateInstallLoadResult _parseUpdateInstallPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return UpdateInstallLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Unsupported update install payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return UpdateInstallLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Update install failed.',
      diagnostic: '',
    );
  }

  final install = decoded['appUpdateInstall'];
  if (install is! Map<String, Object?>) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Missing update install payload.',
      diagnostic: '',
    );
  }

  final parsedInstall = _parseUpdateInstallSummary(install);
  if (parsedInstall == null) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Invalid update install payload.',
      diagnostic: '',
    );
  }

  return InstalledUpdate(parsedInstall);
}

UpdateCheckSummary? _parseUpdateCheckSummary(
  Map<String, Object?> value, {
  required String idKey,
}) {
  final id = value[idKey];
  final status = value['status'];
  final currentVersion = value['currentVersion'];
  final latestVersion = value['latestVersion'];
  final versionUrl = value['versionUrl'];
  final archiveUrl = value['archiveUrl'];

  if (id is! String || status is! String) {
    return null;
  }

  if (!_isOptionalString(currentVersion) ||
      !_isOptionalString(latestVersion) ||
      !_isOptionalString(versionUrl) ||
      !_isOptionalString(archiveUrl)) {
    return null;
  }

  return UpdateCheckSummary(
    id: id,
    status: status,
    currentVersion: currentVersion as String?,
    latestVersion: latestVersion as String?,
    versionUrl: versionUrl as String?,
    archiveUrl: archiveUrl as String?,
  );
}

UpdateInstallSummary? _parseUpdateInstallSummary(Map<String, Object?> value) {
  final id = value['appId'];
  final status = value['status'];
  final currentVersion = value['currentVersion'];
  final installedVersion = value['installedVersion'];
  final archiveUrl = value['archiveUrl'];
  final installPath = value['installPath'];

  if (id is! String || status is! String) {
    return null;
  }

  if (!_isOptionalString(currentVersion) ||
      !_isOptionalString(installedVersion) ||
      !_isOptionalString(archiveUrl) ||
      !_isOptionalString(installPath)) {
    return null;
  }

  return UpdateInstallSummary(
    id: id,
    status: status,
    currentVersion: currentVersion as String?,
    installedVersion: installedVersion as String?,
    archiveUrl: archiveUrl as String?,
    installPath: installPath as String?,
  );
}

AppSettingsSummary? _parseAppSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final terminateWineProcessesOnClose = value['terminateWineProcessesOnClose'];
  final defaultBottlePath = value['defaultBottlePath'];
  final appearanceMode = appAppearanceModeFromJson(value['appearanceMode']);
  final automaticallyCheckForKonyakUpdates =
      value['automaticallyCheckForKonyakUpdates'];
  final automaticallyCheckForWineUpdates =
      value['automaticallyCheckForWineUpdates'];

  if (terminateWineProcessesOnClose is! bool ||
      defaultBottlePath is! String ||
      defaultBottlePath.trim().isEmpty ||
      appearanceMode == null ||
      automaticallyCheckForKonyakUpdates is! bool ||
      automaticallyCheckForWineUpdates is! bool) {
    return null;
  }

  return AppSettingsSummary(
    terminateWineProcessesOnClose: terminateWineProcessesOnClose,
    defaultBottlePath: defaultBottlePath,
    appearanceMode: appearanceMode,
    automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
    automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
  );
}

ProgramSettingsSummary? _parseProgramSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final locale = value['locale'];
  final arguments = value['arguments'];
  final environment = _parseStringMap(value['environment']);
  if (locale is! String || arguments is! String || environment == null) {
    return null;
  }

  return ProgramSettingsSummary(
    locale: locale,
    arguments: arguments,
    environment: environment,
  );
}

Map<String, String>? _parseStringMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final environment = <String, String>{};
  for (final entry in value.entries) {
    if (entry.value is! String) {
      return null;
    }
    environment[entry.key] = entry.value as String;
  }

  return Map.unmodifiable(environment);
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}

BottleProgramListLoadResult _parseBottleProgramListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle program list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle program list failed.',
      diagnostic: '',
    );
  }

  final bottlePrograms = decoded['bottlePrograms'];
  if (bottlePrograms is! Map<String, Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Missing bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final bottleId = bottlePrograms['bottleId'];
  final programs = bottlePrograms['programs'];
  if (bottleId is! String || programs is! List<Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Invalid bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final parsedPrograms = <BottleProgramSummary>[];
  for (final program in programs) {
    if (program is! Map<String, Object?>) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final id = program['id'];
    final name = program['name'];
    final path = program['path'];
    final source = program['source'];
    if (id is! String ||
        name is! String ||
        path is! String ||
        source is! String) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final metadata = _parseProgramMetadata(program['metadata']);

    parsedPrograms.add(
      BottleProgramSummary(
        id: id,
        name: name,
        path: path,
        source: source,
        metadata: metadata,
      ),
    );
  }

  return LoadedBottlePrograms(
    bottleId: bottleId,
    programs: List.unmodifiable(parsedPrograms),
  );
}

WineProcessListLoadResult _parseWineProcessListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return WineProcessListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Unsupported Wine process list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return WineProcessListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Wine process list failed.',
      diagnostic: '',
    );
  }

  final wineProcesses = decoded['wineProcesses'];
  if (wineProcesses is! Map<String, Object?>) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Missing wineProcesses payload.',
      diagnostic: '',
    );
  }

  final processes = wineProcesses['processes'];
  if (processes is! List<Object?>) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Invalid wineProcesses payload.',
      diagnostic: '',
    );
  }

  final parsedProcesses = <WineProcessSummary>[];
  for (final process in processes) {
    if (process is! Map<String, Object?>) {
      return const WineProcessListLoadFailure(
        exitCode: 0,
        message: 'Invalid Wine process record.',
        diagnostic: '',
      );
    }

    final bottleId = process['bottleId'];
    final processId = process['processId'];
    final executable = process['executable'];
    final hostPath = process['hostPath'];
    if (bottleId is! String ||
        processId is! String ||
        executable is! String ||
        (hostPath != null && hostPath is! String)) {
      return const WineProcessListLoadFailure(
        exitCode: 0,
        message: 'Invalid Wine process record.',
        diagnostic: '',
      );
    }

    parsedProcesses.add(
      WineProcessSummary(
        bottleId: bottleId,
        processId: processId,
        executable: executable,
        hostPath: hostPath is String ? hostPath : null,
        metadata: _parseProgramMetadata(process['metadata']),
      ),
    );
  }

  return LoadedWineProcesses(processes: parsedProcesses);
}

ProgramMetadataSummary? _parseProgramMetadata(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map<String, Object?>) {
    return null;
  }

  final architecture = value['architecture'];
  final fileDescription = value['fileDescription'];
  final productName = value['productName'];
  final companyName = value['companyName'];
  final fileVersion = value['fileVersion'];
  final productVersion = value['productVersion'];
  final iconPath = value['iconPath'];

  return ProgramMetadataSummary(
    architecture: architecture is String ? architecture : null,
    fileDescription: fileDescription is String ? fileDescription : null,
    productName: productName is String ? productName : null,
    companyName: companyName is String ? companyName : null,
    fileVersion: fileVersion is String ? fileVersion : null,
    productVersion: productVersion is String ? productVersion : null,
    iconPath: iconPath is String ? iconPath : null,
  );
}

WinetricksVerbListLoadResult _parseWinetricksVerbListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Unsupported winetricks verb list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Winetricks verb list failed.',
      diagnostic: '',
    );
  }

  final winetricks = decoded['winetricks'];
  if (winetricks is! Map<String, Object?>) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Missing winetricks payload.',
      diagnostic: '',
    );
  }

  final categories = winetricks['categories'];
  if (categories is! List<Object?>) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Invalid winetricks categories payload.',
      diagnostic: '',
    );
  }

  final parsedCategories = <WinetricksCategorySummary>[];
  for (final category in categories) {
    final parsedCategory = _parseWinetricksCategorySummary(category);
    if (parsedCategory == null) {
      return const WinetricksVerbListLoadFailure(
        exitCode: 0,
        message: 'Invalid winetricks category record.',
        diagnostic: '',
      );
    }

    parsedCategories.add(parsedCategory);
  }

  return LoadedWinetricksVerbs(categories: parsedCategories);
}

WinetricksCategorySummary? _parseWinetricksCategorySummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final id = value['id'];
  final name = value['name'];
  final verbs = value['verbs'];
  if (id is! String || name is! String || verbs is! List<Object?>) {
    return null;
  }

  final parsedVerbs = <WinetricksVerbSummary>[];
  for (final verb in verbs) {
    final parsedVerb = _parseWinetricksVerbSummary(verb);
    if (parsedVerb == null) {
      return null;
    }

    parsedVerbs.add(parsedVerb);
  }

  return WinetricksCategorySummary(id: id, name: name, verbs: parsedVerbs);
}

WinetricksVerbSummary? _parseWinetricksVerbSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final id = value['id'];
  final name = value['name'];
  final description = value['description'];
  if (id is! String || name is! String || description is! String) {
    return null;
  }

  return WinetricksVerbSummary(id: id, name: name, description: description);
}
