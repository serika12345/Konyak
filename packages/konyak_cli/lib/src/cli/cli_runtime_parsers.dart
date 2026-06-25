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

  return MacosWineInstallRequest.fullInstall(
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
    allowReinstall: true,
  );
  if (options == null) {
    return null;
  }

  return LinuxWineInstallRequest.fullInstall(
    sourceManifest: options.sourceManifest,
    force: options.reinstall,
    emitProgress: options.emitProgress,
  );
}

class _RuntimeInstallCliOptions {
  _RuntimeInstallCliOptions({
    this.sourceManifest,
    this.reinstall = false,
    this.emitProgress = false,
  });

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

  for (final name in const <String>['source-manifest']) {
    if (_hasEmptyParsedCliOption(results, name)) {
      return null;
    }
  }

  final sourceManifest = _nonEmptyCliOption(results, 'source-manifest');
  final reinstall = results['reinstall'] == true;
  if (reinstall && !allowReinstall) {
    return null;
  }

  return _RuntimeInstallCliOptions(
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
