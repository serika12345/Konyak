import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_client.dart';
import '../cli/runtime_install_contract.dart';
import '../files/bottle_archive_picker.dart';
import '../files/directory_picker.dart';
import '../files/gptk_wine_source_picker.dart';
import '../files/program_file_picker.dart';
import '../logs/log_reader.dart';
import '../runtimes/runtime_summary.dart';
import '../settings/app_settings_summary.dart';
import 'app_platform.dart';
import 'dialogs/app_settings_dialog.dart';
import 'dialogs/bottle_management_dialogs.dart';
import 'dialogs/bottle_programs_dialog.dart';
import 'dialogs/create_bottle_dialog.dart';
import 'dialogs/open_executable_dialog.dart';
import 'dialogs/pin_program_dialog.dart';
import 'dialogs/process_manager_dialog.dart';
import 'dialogs/run_program_dialog.dart';
import 'dialogs/winetricks_dialog.dart';
import 'home/home_screen.dart';
import 'runtime/runtime_platform.dart';
import 'startup/startup_update_checker.dart';
import 'utils/bottle_lists.dart';
import 'utils/program_labels.dart';
import 'utils/program_run_feedback.dart';
import 'widgets/blocking_progress_overlay.dart';

const _macosMenuChannel = MethodChannel('konyak/menu');

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

class KonyakHomeLoader extends StatefulWidget {
  const KonyakHomeLoader({
    super.key,
    required this.platform,
    required this.cliClient,
    required this.logReader,
    required this.programFilePicker,
    required this.directoryPicker,
    required this.gptkWineSourcePicker,
    required this.bottleArchivePicker,
    this.initialExecutablePaths = const <String>[],
    required this.enableBackgroundServices,
    required this.onAppSettingsLoaded,
    required this.onAppearanceModeChanged,
  });

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;
  final LogReader logReader;
  final ProgramFilePicker programFilePicker;
  final DirectoryPicker directoryPicker;
  final GptkWineSourcePicker gptkWineSourcePicker;
  final BottleArchivePicker bottleArchivePicker;
  final List<String> initialExecutablePaths;
  final bool enableBackgroundServices;
  final ValueChanged<AppSettingsSummary> onAppSettingsLoaded;
  final ValueChanged<AppAppearanceMode> onAppearanceModeChanged;

  @override
  State<KonyakHomeLoader> createState() => _KonyakHomeLoaderState();
}

class _KonyakHomeLoaderState extends State<KonyakHomeLoader>
    with WidgetsBindingObserver {
  List<BottleSummary> _bottles = const <BottleSummary>[];
  bool _isLoading = true;
  bool _isCreatingBottle = false;
  bool _isLoadingWinetricks = false;
  String? _winetricksInstallProgressMessage;
  String? _archiveProgressMessage;
  String? _runtimeInstallProgressMessage;
  double? _runtimeInstallProgressFraction;
  bool _isShowingSettings = false;
  bool _hasTerminatedWineProcesses = false;
  AppSettingsSummary? _appSettings;
  String? _errorMessage;
  String? _latestRunLogPath;
  List<RuntimeSummary> _knownRuntimes = const <RuntimeSummary>[];
  bool _hasLoadedKnownRuntimes = false;
  final List<String> _pendingExecutableOpenPaths = <String>[];
  bool _isHandlingExecutableOpen = false;
  final Map<String, ProgramSettingsSummary> _programSettings =
      <String, ProgramSettingsSummary>{};
  final Set<String> _loadingProgramSettings = <String>{};
  final Map<String, String> _pendingRuntimeSettingsControls =
      <String, String>{};

  @override
  void initState() {
    super.initState();
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.addObserver(this);
    }
    _pendingExecutableOpenPaths.addAll(
      _validExecutableOpenPaths(widget.initialExecutablePaths),
    );
    _macosMenuChannel.setMethodCallHandler(_handleMacosMenuMethodCall);
    unawaited(_loadPendingExecutableOpenPathsFromPlatform());
    _loadBottles();
    if (widget.enableBackgroundServices) {
      unawaited(_initializeBackgroundServices());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _terminateWineProcessesOnClose();
    }
  }

  @override
  void dispose() {
    _terminateWineProcessesOnClose();
    _macosMenuChannel.setMethodCallHandler(null);
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  Future<void> _handleMacosMenuMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'openSettings':
        unawaited(_showSettings());
        return;
      case 'importBottleArchive':
        unawaited(_importBottleArchive());
        return;
      case 'openExecutableFiles':
        _pendingExecutableOpenPaths.addAll(
          _validExecutableOpenPathsFromChannel(call.arguments),
        );
        unawaited(_drainPendingExecutableOpenPaths());
        return;
      default:
        throw MissingPluginException(
          'Unsupported macOS menu method: ${call.method}',
        );
    }
  }

  Future<void> _loadPendingExecutableOpenPathsFromPlatform() async {
    if (!widget.platform.isMacOS) {
      return;
    }

    try {
      final arguments = await _macosMenuChannel.invokeMethod<Object?>(
        'takePendingExecutableOpenPaths',
      );
      if (!mounted) {
        return;
      }

      _pendingExecutableOpenPaths.addAll(
        _validExecutableOpenPathsFromChannel(arguments),
      );
      unawaited(_drainPendingExecutableOpenPaths());
    } on MissingPluginException {
      return;
    }
  }

  Future<void> _loadBottles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.cliClient.listBottles();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;

      switch (result) {
        case LoadedBottleList(:final bottles):
          _bottles = bottles;
          _errorMessage = null;
        case BottleListLoadFailure(:final message):
          _errorMessage = message;
      }
    });

    unawaited(_drainPendingExecutableOpenPaths());
  }

  Future<void> _initializeBackgroundServices() async {
    if (widget.platform.isLinux) {
      await widget.cliClient.installLinuxFileAssociations();
      if (!mounted) {
        return;
      }
    }

    final result = await widget.cliClient.getAppSettings();

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedAppSettings(:final settings):
        _appSettings = settings;
        widget.onAppSettingsLoaded(settings);
        await _checkConfiguredUpdates(settings);
        await _promptForMissingManagedRuntime();
      case AppSettingsLoadFailure():
        break;
    }
  }

  Future<void> _checkConfiguredUpdates(AppSettingsSummary settings) async {
    final result = await StartupUpdateChecker(
      platform: widget.platform,
      cliClient: widget.cliClient,
    ).check(settings);

    if (!mounted) {
      return;
    }

    final knownRuntimes = result.knownRuntimes;
    if (knownRuntimes != null) {
      _setKnownRuntimes(knownRuntimes);
    }

    if (result.availableUpdateLabels.isEmpty) {
      return;
    }

    _showSnackBar(
      'Updates available: ${result.availableUpdateLabels.join(', ')}',
    );
  }

  void _setKnownRuntimes(List<RuntimeSummary> runtimes) {
    if (!mounted) {
      return;
    }

    setState(() {
      _knownRuntimes = List.unmodifiable(runtimes);
      _hasLoadedKnownRuntimes = true;
    });
  }

  Future<List<RuntimeSummary>?> _loadKnownRuntimes() async {
    final runtimeResult = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return null;
    }

    switch (runtimeResult) {
      case LoadedRuntimeList(:final runtimes):
        _setKnownRuntimes(runtimes);
        return runtimes;
      case RuntimeListLoadFailure():
        _setKnownRuntimes(const <RuntimeSummary>[]);
        return null;
    }
  }

  Future<RuntimeSummary?> _ensureRuntimeForPlatformLoaded() async {
    if (!_hasLoadedKnownRuntimes) {
      final runtimes = await _loadKnownRuntimes();
      if (!mounted) {
        return null;
      }

      if (runtimes == null) {
        return null;
      }

      return runtimeForPlatform(widget.platform, runtimes);
    }

    return runtimeForPlatform(widget.platform, _knownRuntimes);
  }

  Future<void> _promptForMissingManagedRuntime() async {
    final managedRuntime = managedRuntimePlatform(widget.platform);
    if (managedRuntime == null) {
      return;
    }

    final runtime = await _ensureRuntimeForPlatformLoaded();
    if (!mounted || runtime?.isInstalled == true) {
      return;
    }

    final installResult = await _confirmAndInstallManagedRuntime(
      runtimeName: runtime?.name ?? managedRuntime.displayName,
      installRuntime: _installManagedRuntimeForPlatform,
    );

    if (!mounted || installResult == null) {
      return;
    }

    switch (installResult) {
      case InstalledRuntime(:final runtime):
        setState(() {
          _knownRuntimes = upsertRuntimeSummary(_knownRuntimes, runtime);
          _hasLoadedKnownRuntimes = true;
        });
        _showSnackBar('Installed ${runtime.name}');
      case RuntimeInstallLoadFailure(:final message):
        _showSnackBar('Runtime install failed: $message');
    }
  }

  Future<RuntimeInstallLoadResult> _installManagedRuntimeForPlatform() {
    return widget.platform.isMacOS
        ? widget.cliClient.installMacosWine(onProgress: _setRuntimeProgress)
        : widget.cliClient.installLinuxWine(onProgress: _setRuntimeProgress);
  }

  void _setRuntimeProgress(RuntimeInstallProgress progress) {
    if (!mounted) {
      return;
    }

    setState(() {
      _runtimeInstallProgressMessage = progress.message;
      _runtimeInstallProgressFraction = progress.fraction;
    });
  }

  Future<RuntimeInstallLoadResult?> _confirmAndInstallManagedRuntime({
    required String runtimeName,
    required Future<RuntimeInstallLoadResult> Function() installRuntime,
  }) async {
    final confirmed = await _confirmRuntimeDownload(runtimeName);
    if (!mounted || !confirmed) {
      return null;
    }

    setState(() {
      _runtimeInstallProgressMessage = 'Downloading $runtimeName...';
      _runtimeInstallProgressFraction = 0;
    });

    try {
      return await installRuntime();
    } finally {
      if (mounted) {
        setState(() {
          _runtimeInstallProgressMessage = null;
          _runtimeInstallProgressFraction = null;
        });
      }
    }
  }

  Future<bool> _confirmRuntimeDownload(String runtimeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $runtimeName?'),
        content: Text(
          'Konyak will download $runtimeName into your Konyak runtime directory. '
          'The runtime is separate from the application and remains under its own license.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _terminateWineProcessesOnClose() {
    if (!widget.enableBackgroundServices || _hasTerminatedWineProcesses) {
      return;
    }

    final settings = _appSettings;
    if (settings == null || !settings.terminateWineProcessesOnClose) {
      return;
    }

    _hasTerminatedWineProcesses = true;
    unawaited(widget.cliClient.terminateWineProcesses());
  }

  Future<void> _terminateBottleProcesses(BottleSummary bottle) async {
    final result = await widget.cliClient.terminateWineProcesses(
      bottleId: bottle.id,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      TerminatedWineProcesses() => 'Stopped processes in ${bottle.name}',
      WineProcessTerminationLoadFailure(:final message) => message,
    };

    _showSnackBar(message);
  }

  Future<void> _createBottle() async {
    await _createBottleFromDialog();
  }

  Future<BottleSummary?> _createBottleFromDialog() async {
    final input = await showDialog<CreateBottleInput>(
      context: context,
      builder: (context) => const CreateBottleDialog(),
    );

    if (input == null) {
      return null;
    }

    return _createBottleFromInput(input);
  }

  Future<BottleSummary?> _createBottleFromInput(CreateBottleInput input) async {
    setState(() {
      _isCreatingBottle = true;
    });

    late final BottleCreateLoadResult result;
    try {
      result = await widget.cliClient.createBottle(
        name: input.name,
        windowsVersion: input.windowsVersion,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBottle = false;
        });
      }
    }

    if (!mounted) {
      return null;
    }

    switch (result) {
      case CreatedBottle(:final bottle):
        _storeBottle(bottle);
        return bottle;
      case ExistingBottle(:final message) ||
          BottleCreateLoadFailure(:final message):
        _showSnackBar(message);
        return null;
    }
  }

  void _storeBottle(BottleSummary bottle, {String? oldBottleId}) {
    setState(() {
      _bottles = oldBottleId == null
          ? upsertBottle(_bottles, bottle)
          : replaceBottle(_bottles, oldBottleId: oldBottleId, bottle: bottle);
      _errorMessage = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBottleUpdateResult(
    BottleUpdateLoadResult result, {
    String? oldBottleId,
    String Function(BottleSummary bottle)? successMessage,
  }) {
    switch (result) {
      case UpdatedBottle(:final bottle):
        _storeBottle(bottle, oldBottleId: oldBottleId);
        final message = successMessage?.call(bottle);
        if (message != null) {
          _showSnackBar(message);
        }
      case MissingBottleUpdate(:final message) ||
          BottleUpdateLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _drainPendingExecutableOpenPaths() async {
    if (!mounted || _isLoading || _isHandlingExecutableOpen) {
      return;
    }

    _isHandlingExecutableOpen = true;
    try {
      while (mounted && !_isLoading && _pendingExecutableOpenPaths.isNotEmpty) {
        final programPath = _pendingExecutableOpenPaths.removeAt(0);
        await _showOpenExecutable(programPath);
      }
    } finally {
      _isHandlingExecutableOpen = false;
      if (mounted && !_isLoading && _pendingExecutableOpenPaths.isNotEmpty) {
        unawaited(_drainPendingExecutableOpenPaths());
      }
    }
  }

  Future<void> _showOpenExecutable(String programPath) async {
    final decision = await showDialog<OpenExecutableDecision>(
      context: context,
      builder: (context) =>
          OpenExecutableDialog(programPath: programPath, bottles: _bottles),
    );

    if (!mounted || decision == null) {
      return;
    }

    switch (decision) {
      case RunExecutableInBottle(:final bottle):
        await _runProgramPath(bottle: bottle, programPath: programPath);
      case CreateBottleForExecutable():
        final bottle = await _createBottleFromDialog();
        if (!mounted || bottle == null) {
          return;
        }
        await _runProgramPath(bottle: bottle, programPath: programPath);
    }
  }

  Future<void> _setRuntimeSettings({
    required BottleSummary bottle,
    required BottleRuntimeSettingsSummary runtimeSettings,
    required String controlKey,
  }) async {
    if (_pendingRuntimeSettingsControls.containsKey(bottle.id)) {
      return;
    }

    setState(() {
      _pendingRuntimeSettingsControls[bottle.id] = controlKey;
      _errorMessage = null;
    });

    final BottleUpdateLoadResult result;
    try {
      result = await widget.cliClient.setRuntimeSettings(
        bottleId: bottle.id,
        runtimeSettings: runtimeSettings,
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingRuntimeSettingsControls.remove(bottle.id);
        });
      }
    }

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(result);
  }

  Future<void> _loadBottleConfiguration(BottleSummary bottle) async {
    final result = await widget.cliClient.inspectBottle(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedBottleDetail(:final bottle):
        _storeBottle(bottle);
      case MissingBottleDetail(:final message) ||
          BottleDetailLoadFailure(:final message):
        _showSnackBar(message);
    }

    await _loadRuntimeCapabilities();
  }

  Future<void> _loadRuntimeCapabilities() async {
    final result = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedRuntimeList(:final runtimes):
        _setKnownRuntimes(runtimes);
      case RuntimeListLoadFailure():
        _setKnownRuntimes(const <RuntimeSummary>[]);
    }
  }

  Future<void> _deleteBottle(BottleSummary bottle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteBottleDialog(bottleName: bottle.name),
    );

    if (confirmed != true) {
      return;
    }

    final result = await widget.cliClient.deleteBottle(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case DeletedBottle(:final bottle):
        setState(() {
          _bottles = removeBottle(_bottles, bottle.id);
          _errorMessage = null;
        });
        _showSnackBar('Deleted ${bottle.name}');
      case MissingBottleDelete(:final message) ||
          BottleDeleteLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _renameBottle(BottleSummary bottle) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => RenameBottleDialog(bottleName: bottle.name),
    );

    if (name == null) {
      return;
    }

    final result = await widget.cliClient.renameBottle(
      bottleId: bottle.id,
      name: name,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(
      result,
      oldBottleId: bottle.id,
      successMessage: (bottle) => 'Renamed ${bottle.name}',
    );
  }

  Future<void> _moveBottle(BottleSummary bottle) async {
    final path = await showDialog<String>(
      context: context,
      builder: (context) => MoveBottleDialog(
        bottleName: bottle.name,
        initialPath: bottle.path,
        directoryPicker: widget.directoryPicker,
      ),
    );

    if (path == null) {
      return;
    }

    final result = await widget.cliClient.moveBottle(
      bottleId: bottle.id,
      path: path,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(
      result,
      successMessage: (bottle) => 'Moved ${bottle.name}',
    );
  }

  Future<void> _exportBottleArchive(BottleSummary bottle) async {
    final archivePath = await widget.bottleArchivePicker.pickArchiveExportPath(
      suggestedName: '${bottle.id}.konyak-bottle.tar',
    );
    if (archivePath == null) {
      return;
    }

    setState(() {
      _archiveProgressMessage = 'Exporting bottle archive...';
    });

    late final BottleArchiveExportLoadResult result;
    try {
      result = await widget.cliClient.exportBottleArchive(
        bottleId: bottle.id,
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        setState(() {
          _archiveProgressMessage = null;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case ExportedBottleArchive():
        _showSnackBar('Exported ${bottle.name}');
      case BottleArchiveExportLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _importBottleArchive() async {
    final archivePath = await widget.bottleArchivePicker.pickArchiveToImport();
    if (archivePath == null) {
      return;
    }

    setState(() {
      _archiveProgressMessage = 'Importing bottle archive...';
    });

    late final BottleArchiveImportLoadResult result;
    try {
      result = await widget.cliClient.importBottleArchive(
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        setState(() {
          _archiveProgressMessage = null;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case ImportedBottleArchive(:final bottle):
        _storeBottle(bottle);
        _showSnackBar('Imported ${bottle.name}');
      case BottleArchiveImportLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _runProgram(BottleSummary bottle) async {
    final programPath = await showDialog<String>(
      context: context,
      builder: (context) => RunProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
      ),
    );

    if (programPath == null) {
      return;
    }

    await _runProgramPath(bottle: bottle, programPath: programPath);
  }

  Future<void> _runProgramPath({
    required BottleSummary bottle,
    required String programPath,
  }) async {
    final result = await widget.cliClient.runProgram(
      bottleId: bottle.id,
      programPath: programPath,
    );

    if (!mounted) {
      return;
    }

    _handleProgramRunResult(result);
  }

  void _handleProgramRunResult(ProgramRunLoadResult result) {
    switch (result) {
      case CompletedProgramRun(:final run):
        setState(() {
          _latestRunLogPath = run.logPath;
        });
      case FailedProgramRun(:final logPath):
        setState(() {
          _latestRunLogPath = logPath;
        });
      case UnsupportedProgramRun() ||
          MissingProgramRunBottle() ||
          ProgramRunLoadFailure():
        break;
    }

    final feedbackMessage = programRunFeedback(result);
    if (feedbackMessage != null) {
      _showSnackBar(feedbackMessage);
    }
  }

  Future<void> _pinProgram(BottleSummary bottle) async {
    final input = await showDialog<PinProgramInput>(
      context: context,
      builder: (context) => PinProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
      ),
    );

    if (input == null) {
      return;
    }

    await _pinProgramPath(
      bottle: bottle,
      name: input.name,
      programPath: input.programPath,
    );
  }

  Future<void> _pinProgramPath({
    required BottleSummary bottle,
    required String name,
    required String programPath,
  }) async {
    final result = await widget.cliClient.pinProgram(
      bottleId: bottle.id,
      name: name,
      programPath: programPath,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(result, successMessage: (_) => 'Pinned $name');
  }

  Future<void> _unpinProgram({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final result = await widget.cliClient.unpinProgram(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(
      result,
      successMessage: (_) => 'Unpinned ${program.name}',
    );
  }

  Future<void> _renamePinnedProgram({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          RenamePinnedProgramDialog(programName: program.name),
    );

    if (name == null) {
      return;
    }

    final result = await widget.cliClient.renamePinnedProgram(
      bottleId: bottle.id,
      programPath: program.path,
      name: name,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(result, successMessage: (_) => 'Renamed $name');
  }

  Future<void> _openPinnedProgramLocation({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final result = await widget.cliClient.openProgramLocation(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      OpenedProgramLocation() => 'Opened ${program.name} location',
      ProgramLocationOpenFailure(:final message) => message,
    };

    _showSnackBar(message);
  }

  Future<void> _loadPinnedProgramSettings({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final key = programSettingsKey(
      bottleId: bottle.id,
      programPath: program.path,
    );
    setState(() {
      _loadingProgramSettings.add(key);
    });

    final result = await widget.cliClient.getProgramSettings(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingProgramSettings.remove(key);
      switch (result) {
        case LoadedProgramSettings(:final settings):
          _programSettings[key] = settings;
        case MissingProgramSettingsBottle() || ProgramSettingsLoadFailure():
          _programSettings.remove(key);
      }
    });

    switch (result) {
      case LoadedProgramSettings():
        break;
      case MissingProgramSettingsBottle(:final message) ||
          ProgramSettingsLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _setPinnedProgramSettings({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
    required ProgramSettingsSummary settings,
  }) async {
    final result = await widget.cliClient.setProgramSettings(
      bottleId: bottle.id,
      programPath: program.path,
      settings: settings,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedProgramSettings(:final settings):
        setState(() {
          _programSettings[programSettingsKey(
                bottleId: bottle.id,
                programPath: program.path,
              )] =
              settings;
        });
        _showSnackBar('Saved ${program.name} configuration');
      case MissingProgramSettingsBottle(:final message) ||
          ProgramSettingsLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _runBottleCommand({
    required BottleSummary bottle,
    required String command,
  }) async {
    final result = await widget.cliClient.runBottleCommand(
      bottleId: bottle.id,
      command: command,
    );

    if (!mounted) {
      return;
    }

    _handleProgramRunResult(result);

    if (shouldRefreshBottleAfterCommand(command) &&
        result is CompletedProgramRun) {
      await _loadBottleConfiguration(bottle);
    }
  }

  Future<void> _showWinetricks(BottleSummary bottle) async {
    setState(() {
      _isLoadingWinetricks = true;
    });

    late final WinetricksVerbListLoadResult listResult;
    try {
      listResult = await widget.cliClient.listWinetricksVerbs();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWinetricks = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (listResult) {
      case LoadedWinetricksVerbs(:final categories):
        final verb = await showDialog<String>(
          context: context,
          builder: (context) =>
              WinetricksDialog(bottleName: bottle.name, categories: categories),
        );

        if (!mounted || verb == null) {
          return;
        }

        setState(() {
          _winetricksInstallProgressMessage = 'Installing $verb...';
        });

        late final ProgramRunLoadResult runResult;
        try {
          runResult = await widget.cliClient.runWinetricksVerb(
            bottleId: bottle.id,
            verb: verb,
          );
        } finally {
          if (mounted) {
            setState(() {
              _winetricksInstallProgressMessage = null;
            });
          }
        }

        if (!mounted) {
          return;
        }

        _handleProgramRunResult(runResult);
      case WinetricksVerbListLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _openBottleLocation({
    required BottleSummary bottle,
    required String location,
  }) async {
    final result = await widget.cliClient.openBottleLocation(
      bottleId: bottle.id,
      location: location,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      OpenedBottleLocation(:final location) =>
        'Opened ${locationLabel(location)}',
      BottleLocationOpenFailure(:final message) => message,
    };

    _showSnackBar(message);
  }

  Future<void> _showBottlePrograms(BottleSummary bottle) async {
    final result = await widget.cliClient.listBottlePrograms(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedBottlePrograms(:final programs):
        await showDialog<void>(
          context: context,
          builder: (context) => BottleProgramsDialog(
            bottleName: bottle.name,
            programs: programs,
            onPinProgram: (program) {
              Navigator.of(context).pop();
              unawaited(
                _pinProgramPath(
                  bottle: bottle,
                  name: programDisplayName(program),
                  programPath: program.path,
                ),
              );
            },
            onRunProgram: (program) {
              Navigator.of(context).pop();
              _runProgramPath(bottle: bottle, programPath: program.path);
            },
          ),
        );
      case BottleProgramListLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _showProcessManager() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ProcessManagerDialog(
        bottles: _bottles,
        onLoadProcesses: widget.cliClient.listWineProcesses,
        onTerminateProcess: (process) {
          return widget.cliClient.terminateWineProcess(
            bottleId: process.bottleId,
            processId: process.processId,
          );
        },
      ),
    );
  }

  Future<void> _showLatestLog() async {
    final logPath = _latestRunLogPath;
    if (logPath == null) {
      return;
    }

    final result = await widget.logReader.readLog(logPath);

    if (!mounted) {
      return;
    }

    switch (result) {
      case ReadLog(:final content):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Latest run log'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(child: SelectableText(content)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      case LogReadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _showSettings() async {
    if (_isShowingSettings) {
      return;
    }

    _isShowingSettings = true;
    try {
      final result = await widget.cliClient.getAppSettings();

      if (!mounted) {
        return;
      }

      switch (result) {
        case LoadedAppSettings(:final settings):
          _appSettings = settings;
          widget.onAppSettingsLoaded(settings);
          var knownRuntimes = const <RuntimeSummary>[];
          String? runtimeLoadError;
          final managedRuntime = managedRuntimePlatform(widget.platform);
          if (managedRuntime != null) {
            final runtimeResult = await widget.cliClient.listKnownRuntimes();
            if (!mounted) {
              return;
            }
            switch (runtimeResult) {
              case LoadedRuntimeList(:final runtimes):
                knownRuntimes = runtimesForPlatform(widget.platform, runtimes);
                _knownRuntimes = runtimes;
              case RuntimeListLoadFailure(:final message):
                runtimeLoadError = message;
            }
          }
          await showDialog<void>(
            context: context,
            builder: (context) => AppSettingsDialog(
              platform: widget.platform,
              initialSettings: settings,
              directoryPicker: widget.directoryPicker,
              runtimes: knownRuntimes,
              runtimeLoadError: runtimeLoadError,
              onInstallRuntime: managedRuntime != null
                  ? _installSettingsRuntime
                  : null,
              onInstallGptkWine: widget.platform.isMacOS
                  ? _installGptkWine
                  : null,
              onOpenGptkPage: widget.platform.isMacOS ? _openGptkPage : null,
              onSettingsChanged: _setAppSettings,
            ),
          );
        case AppSettingsLoadFailure(:final message):
          _showSnackBar(message);
      }
    } finally {
      _isShowingSettings = false;
    }
  }

  Future<RuntimeInstallLoadResult> _installSettingsRuntime() async {
    final managedRuntime = managedRuntimePlatform(widget.platform);
    if (managedRuntime == null) {
      return const RuntimeInstallLoadFailure(
        exitCode: 64,
        message: 'Managed runtime installation is not supported.',
        diagnostic: '',
      );
    }

    setState(() {
      _runtimeInstallProgressMessage =
          'Downloading ${managedRuntime.displayName}...';
      _runtimeInstallProgressFraction = 0;
    });

    final RuntimeInstallLoadResult result;
    try {
      result = widget.platform.isMacOS
          ? await widget.cliClient.installMacosWine(
              onProgress: _setRuntimeProgress,
            )
          : await widget.cliClient.installLinuxWine(
              onProgress: _setRuntimeProgress,
            );
    } finally {
      if (mounted) {
        setState(() {
          _runtimeInstallProgressMessage = null;
          _runtimeInstallProgressFraction = null;
        });
      }
    }

    if (!mounted) {
      return result;
    }

    switch (result) {
      case InstalledRuntime(:final runtime):
        setState(() {
          _knownRuntimes = upsertRuntimeSummary(_knownRuntimes, runtime);
          _hasLoadedKnownRuntimes = true;
        });
      case RuntimeInstallLoadFailure():
        break;
    }

    return result;
  }

  Future<RuntimeInstallLoadResult> _installGptkWine() async {
    final sourcePath = await widget.gptkWineSourcePicker.pickSourcePath();
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return const RuntimeInstallLoadFailure(
        exitCode: 64,
        message: 'GPTK-compatible Wine source was not selected.',
        diagnostic: '',
      );
    }

    setState(() {
      _runtimeInstallProgressMessage = 'Installing GPTK-compatible Wine...';
      _runtimeInstallProgressFraction = 0;
    });

    final ProcessRunResult installResult;
    try {
      installResult = await widget.cliClient.installGptkWine(
        sourcePath: sourcePath,
      );
    } finally {
      if (mounted) {
        setState(() {
          _runtimeInstallProgressMessage = null;
          _runtimeInstallProgressFraction = null;
        });
      }
    }

    if (installResult.exitCode != 0) {
      return RuntimeInstallLoadFailure(
        exitCode: installResult.exitCode,
        message: _installGptkFailureMessage(
          installResult,
          command: 'install-gptk-wine',
        ),
        diagnostic: installResult.stderr,
      );
    }

    final runtimesResult = await widget.cliClient.listKnownRuntimes();
    switch (runtimesResult) {
      case LoadedRuntimeList(:final runtimes):
        if (mounted) {
          setState(() {
            _knownRuntimes = runtimes;
            _hasLoadedKnownRuntimes = true;
          });
        }
        return installedRuntimeForPlatform(runtimes, widget.platform);
      case RuntimeListLoadFailure(
        :final exitCode,
        :final message,
        :final diagnostic,
      ):
        return RuntimeInstallLoadFailure(
          exitCode: exitCode,
          message: message,
          diagnostic: diagnostic,
        );
    }
  }

  Future<void> _openGptkPage() async {
    const url = 'https://github.com/Gcenx/game-porting-toolkit/releases';
    final result = await widget.cliClient.openUrl(url);
    if (!mounted || result.exitCode == 0) {
      return;
    }
    _showSnackBar(_openUrlFailureMessage(result));
  }

  Future<void> _showAbout() async {
    showAboutDialog(
      context: context,
      applicationName: 'Konyak',
      applicationVersion: 'Linux preview',
      applicationLegalese: 'MIT License',
      applicationIcon: Image.asset(
        'assets/icons/konyak.png',
        width: 48,
        height: 48,
      ),
      children: const [
        Text('Flutter desktop UI for Konyak.'),
        SizedBox(height: 10),
        Text(
          'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.',
        ),
      ],
    );
  }

  Future<AppSettingsSummary?> _setAppSettings(
    AppSettingsSummary settings,
  ) async {
    final result = await widget.cliClient.setAppSettings(settings: settings);

    if (!mounted) {
      return null;
    }

    switch (result) {
      case LoadedAppSettings(:final settings):
        _appSettings = settings;
        widget.onAppearanceModeChanged(settings.appearanceMode);
        return settings;
      case AppSettingsLoadFailure(:final message):
        _showSnackBar(message);
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        KonyakHome(
          platform: widget.platform,
          runtime: runtimeForPlatform(widget.platform, _knownRuntimes),
          bottles: _bottles,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onRefresh: _loadBottles,
          onShowSettings: _showSettings,
          onShowAbout: _showAbout,
          onCreateBottle: _createBottle,
          onImportBottleArchive: _importBottleArchive,
          onExportBottleArchive: _exportBottleArchive,
          onViewLatestLog: _latestRunLogPath == null ? null : _showLatestLog,
          pendingRuntimeSettingsControls: _pendingRuntimeSettingsControls,
          onRuntimeSettingsChanged: (bottle, runtimeSettings, controlKey) {
            _setRuntimeSettings(
              bottle: bottle,
              runtimeSettings: runtimeSettings,
              controlKey: controlKey,
            );
          },
          onLoadBottleConfiguration: _loadBottleConfiguration,
          onDeleteBottle: _deleteBottle,
          onRenameBottle: _renameBottle,
          onMoveBottle: _moveBottle,
          onRunProgram: _runProgram,
          onRunProgramPath: (bottle, programPath) {
            _runProgramPath(bottle: bottle, programPath: programPath);
          },
          onPinProgram: _pinProgram,
          programSettings: _programSettings,
          loadingProgramSettings: _loadingProgramSettings,
          isRuntimeCapabilitiesLoading: !_hasLoadedKnownRuntimes,
          onLoadPinnedProgramSettings: (bottle, program) {
            _loadPinnedProgramSettings(bottle: bottle, program: program);
          },
          onProgramSettingsChanged: (bottle, program, settings) {
            _setPinnedProgramSettings(
              bottle: bottle,
              program: program,
              settings: settings,
            );
          },
          onUnpinProgram: (bottle, program) {
            _unpinProgram(bottle: bottle, program: program);
          },
          onRenamePinnedProgram: (bottle, program) {
            _renamePinnedProgram(bottle: bottle, program: program);
          },
          onOpenPinnedProgramLocation: (bottle, program) {
            _openPinnedProgramLocation(bottle: bottle, program: program);
          },
          onRunBottleCommand: (bottle, command) {
            _runBottleCommand(bottle: bottle, command: command);
          },
          onShowWinetricks: _showWinetricks,
          onOpenBottleLocation: (bottle, location) {
            _openBottleLocation(bottle: bottle, location: location);
          },
          onShowBottlePrograms: _showBottlePrograms,
          onShowProcessManager: _showProcessManager,
          onTerminateBottleProcesses: _terminateBottleProcesses,
        ),
        if (_isCreatingBottle)
          const BlockingProgressOverlay(
            key: ValueKey('create-bottle-progress'),
            message: 'Creating bottle...',
          ),
        if (_isLoadingWinetricks)
          const BlockingProgressOverlay(
            key: ValueKey('winetricks-progress'),
            message: 'Loading winetricks packages...',
          ),
        if (_winetricksInstallProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('winetricks-progress'),
            message: message,
          ),
        if (_archiveProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('bottle-archive-progress'),
            message: message,
          ),
        if (_runtimeInstallProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('runtime-install-progress'),
            message: message,
            progress: _runtimeInstallProgressFraction,
          ),
      ],
    );
  }
}
