part of '../../konyak_cli.dart';

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
    allowReinstall: true,
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
    force: options.reinstall,
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
    required List<String> componentArchivePaths,
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.reinstall = false,
    this.emitProgress = false,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths);

  final String? archivePath;
  final String? archiveUrl;
  final String? archiveSha256;
  final List<String> componentArchivePaths;
  final String? sourceManifest;
  final bool reinstall;
  final bool emitProgress;
}

_RuntimeInstallCliOptions? _parseRuntimeInstallCliOptions(
  List<String> arguments, {
  required String command,
  bool allowReinstall = false,
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
    ..addFlag('reinstall', negatable: false)
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
  final reinstall = results['reinstall'] == true;
  if (reinstall && !allowReinstall) {
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
  if (reinstall && componentArchivePaths.isNotEmpty) {
    return null;
  }

  return _RuntimeInstallCliOptions(
    archivePath: archivePath,
    archiveUrl: archiveUrl,
    archiveSha256: archiveSha256,
    componentArchivePaths: componentArchivePaths,
    sourceManifest: sourceManifest,
    reinstall: reinstall,
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
