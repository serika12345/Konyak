part of '../home_loader/home_loader.dart';

const _macosMenuChannel = MethodChannel('konyak/menu');

class _MacosNativeMenuLocalizer extends StatefulWidget {
  const _MacosNativeMenuLocalizer();

  @override
  State<_MacosNativeMenuLocalizer> createState() =>
      _MacosNativeMenuLocalizerState();
}

class _MacosNativeMenuLocalizerState extends State<_MacosNativeMenuLocalizer> {
  Map<String, String>? _lastPayload;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronizeNativeMenu();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  void _synchronizeNativeMenu() {
    final payload = _macosNativeMenuLocalizationPayload(
      KonyakLocalizations.of(context),
    );
    if (_sameStringMap(_lastPayload, payload)) {
      return;
    }

    _lastPayload = Map<String, String>.unmodifiable(payload);
    unawaited(_sendMacosNativeMenuLocalization(payload));
  }
}

Map<String, String> _macosNativeMenuLocalizationPayload(
  KonyakLocalizations localizations,
) {
  return <String, String>{
    'appMenu': 'Konyak',
    'aboutKonyak': localizations.aboutKonyak,
    'settings': localizations.settingsEllipsisMenu,
    'checkForUpdates': localizations.checkForUpdatesMenuItem,
    'reinstallRuntime': localizations.reinstallMacosRuntime,
    'hideKonyak': localizations.hideKonyak,
    'hideOthers': localizations.hideOthers,
    'showAll': localizations.showAll,
    'quitKonyak': localizations.quitKonyak,
    'file': localizations.file,
    'importBottle': localizations.importBottle,
  };
}

Future<void> _sendMacosNativeMenuLocalization(
  Map<String, String> payload,
) async {
  try {
    await _macosMenuChannel.invokeMethod<void>('setMenuLocalization', payload);
  } on MissingPluginException {
    return;
  }
}

bool _sameStringMap(Map<String, String>? left, Map<String, String> right) {
  if (left == null || left.length != right.length) {
    return false;
  }

  for (final entry in right.entries) {
    if (left[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

List<String> _validExecutableOpenPathsFromChannel(Object? arguments) {
  if (arguments is! List<Object?>) {
    return const <String>[];
  }

  return _validExecutableOpenPaths(arguments.whereType<String>());
}

List<String> _validExecutableOpenPaths(Iterable<String> paths) {
  final validPaths = <String>[];
  for (final path in paths) {
    final trimmedPath = path.trim();
    if (_isWindowsExecutablePath(trimmedPath)) {
      validPaths.add(trimmedPath);
    }
  }

  return validPaths;
}

bool _isWindowsExecutablePath(String path) {
  return path.isNotEmpty && path.toLowerCase().endsWith('.exe');
}

String _installGptkFailureMessage(
  ProcessRunResult result, {
  required String command,
}) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }
  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return '$command failed with exit code ${result.exitCode}.';
  }
  return '$command failed with exit code ${result.exitCode}: $diagnostic';
}

String _openUrlFailureMessage(ProcessRunResult result) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }
  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return 'open-url failed with exit code ${result.exitCode}.';
  }
  return 'open-url failed with exit code ${result.exitCode}: $diagnostic';
}

String? _jsonErrorMessage(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final error = decoded['error'];
    if (error is! Map<String, dynamic>) {
      return null;
    }
    final message = error['message'];
    return message is String && message.isNotEmpty ? message : null;
  } on FormatException {
    return null;
  }
}
