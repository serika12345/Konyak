import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../cli/konyak_cli_client.dart';
import '../../files/log_file_picker.dart';
import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../programs/program_configuration_settings.dart';
import '../programs/program_environment_editor.dart';
import '../programs/program_settings_controls.dart';

typedef GraphicsBackendHintsLoader =
    Future<GraphicsBackendHintsLoadResult> Function(String programPath);

class RunProgramDialogResult {
  RunProgramDialogResult({required this.programPath, this.settings});

  final String programPath;
  final ProgramSettingsSummary? settings;
}

class RunProgramDialog extends StatefulWidget {
  const RunProgramDialog({
    super.key,
    required this.bottleName,
    required this.programFilePicker,
    required this.initialDirectory,
    this.defaultLogPath = '',
    this.logFilePicker = const FileSelectorLogFilePicker(),
    this.graphicsBackendHintsLoader,
  });

  final String bottleName;
  final ProgramFilePicker programFilePicker;
  final String initialDirectory;
  final String defaultLogPath;
  final LogFilePicker logFilePicker;
  final GraphicsBackendHintsLoader? graphicsBackendHintsLoader;

  @override
  State<RunProgramDialog> createState() => _RunProgramDialogState();
}

class _RunProgramDialogState extends State<RunProgramDialog> {
  final TextEditingController _programPathController = TextEditingController();
  final TextEditingController _argumentsController = TextEditingController();
  final TextEditingController _wineLoggingChannelsController =
      TextEditingController();
  final TextEditingController _logFilePathController = TextEditingController();
  final List<ProgramEnvironmentControllers> _environmentControllers =
      <ProgramEnvironmentControllers>[];
  bool _optionsExpanded = false;
  String _locale = '';
  bool _createLogFile = true;
  bool _isLoadingGraphicsBackendHints = false;
  ProgramGraphicsBackendHintsSummary? _graphicsBackendHints;
  String? _graphicsBackendHintError;

  @override
  void dispose() {
    _programPathController.dispose();
    _argumentsController.dispose();
    _wineLoggingChannelsController.dispose();
    _logFilePathController.dispose();
    for (final controllers in _environmentControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final programPath = _programPathController.text.trim();
    if (programPath.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      RunProgramDialogResult(
        programPath: programPath,
        settings: _oneTimeSettings(),
      ),
    );
  }

  Future<void> _chooseProgramFile() async {
    final selectedPath = await widget.programFilePicker.pickProgramPath(
      initialDirectory: widget.initialDirectory,
    );
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _programPathController.text = selectedPath;
      _clearGraphicsBackendHints();
    });
  }

  Future<void> _loadGraphicsBackendHints() async {
    final loader = widget.graphicsBackendHintsLoader;
    final programPath = _programPathController.text.trim();
    if (loader == null || programPath.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingGraphicsBackendHints = true;
      _graphicsBackendHints = null;
      _graphicsBackendHintError = null;
    });

    final result = await loader(programPath);
    if (!mounted || _programPathController.text.trim() != programPath) {
      return;
    }

    setState(() {
      _isLoadingGraphicsBackendHints = false;
      switch (result) {
        case LoadedGraphicsBackendHints(:final hints):
          _graphicsBackendHints = hints;
        case GraphicsBackendHintsLoadFailure(:final message):
          _graphicsBackendHintError = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final programPath = _programPathController.text.trim();
    final canSubmit = programPath.isNotEmpty;
    final localizations = KonyakLocalizations.of(context);
    final canInspectGraphicsBackend =
        widget.graphicsBackendHintsLoader != null && programPath.isNotEmpty;

    return AlertDialog(
      title: Text(localizations.runProgramIn(widget.bottleName)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _programPathController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: localizations.programPath,
                  suffixIcon: IconButton(
                    tooltip: localizations.chooseProgramFile,
                    onPressed: _chooseProgramFile,
                    icon: const Icon(Icons.folder_open),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onChanged: _handleProgramPathChanged,
                onSubmitted: (_) => _submit(),
              ),
              if (canInspectGraphicsBackend)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('run-program-graphics-hint-button'),
                      onPressed: _isLoadingGraphicsBackendHints
                          ? null
                          : _loadGraphicsBackendHints,
                      icon: _isLoadingGraphicsBackendHints
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.manage_search),
                      label: Text(localizations.detectGraphicsBackend),
                    ),
                  ),
                ),
              if (_graphicsBackendHints != null ||
                  _graphicsBackendHintError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _GraphicsBackendHintPanel(
                    hints: _graphicsBackendHints,
                    errorMessage: _graphicsBackendHintError,
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('run-program-options-toggle'),
                  onPressed: () {
                    setState(() {
                      _optionsExpanded = !_optionsExpanded;
                    });
                  },
                  icon: Icon(
                    _optionsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  label: Text(localizations.options),
                ),
              ),
              if (_optionsExpanded)
                ProgramSettingsControls(
                  keyPrefix: 'run-program',
                  locale: _locale,
                  argumentsController: _argumentsController,
                  environmentControllers: _environmentControllers,
                  createLogFile: _createLogFile,
                  wineLoggingChannelsController: _wineLoggingChannelsController,
                  logFilePathController: _logFilePathController,
                  defaultLogPath: widget.defaultLogPath,
                  onLocaleChanged: _setLocale,
                  onCreateLogFileChanged: _setCreateLogFile,
                  onChooseLogFile: _chooseLogFile,
                  onAddEnvironmentVariable: _addEnvironmentVariable,
                  onRemoveEnvironmentVariable: _removeEnvironmentVariable,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.run),
        ),
      ],
    );
  }

  void _addEnvironmentVariable() {
    setState(() {
      _environmentControllers.add(ProgramEnvironmentControllers());
    });
  }

  void _removeEnvironmentVariable(int index) {
    setState(() {
      _environmentControllers.removeAt(index).dispose();
    });
  }

  void _setCreateLogFile(bool createLogFile) {
    setState(() {
      _createLogFile = createLogFile;
    });
  }

  void _setLocale(String locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<void> _chooseLogFile() async {
    final currentPath = _effectiveLogPath();
    final selectedPath = await widget.logFilePicker.pickLogFilePath(
      initialDirectory: programPathDirectory(currentPath),
      suggestedName: programPathFileName(currentPath) ?? 'latest.log',
    );
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _logFilePathController.text = selectedPath;
    });
  }

  void _handleProgramPathChanged(String _) {
    setState(_clearGraphicsBackendHints);
  }

  void _clearGraphicsBackendHints() {
    _graphicsBackendHints = null;
    _graphicsBackendHintError = null;
    _isLoadingGraphicsBackendHints = false;
  }

  ProgramSettingsSummary? _oneTimeSettings() {
    final arguments = _argumentsController.text;
    final environment = programEnvironmentFromEntries(
      _environmentControllers.map((controller) => controller.toEntry()),
    );
    final logging = ProgramLoggingSettingsSummary(
      createLogFile: _createLogFile,
      additionalWineLoggingChannels: _wineLoggingChannelsController.text,
      logFilePath: _logFilePathController.text,
    );
    if (_locale.trim().isEmpty &&
        arguments.trim().isEmpty &&
        environment.isEmpty &&
        logging.isDefault) {
      return null;
    }

    return ProgramSettingsSummary(
      locale: _locale,
      arguments: arguments,
      environment: environment,
      logging: logging,
    );
  }

  String _effectiveLogPath() {
    return effectiveProgramLogPath(
      selectedLogPath: _logFilePathController.text,
      defaultLogPath: widget.defaultLogPath,
    );
  }
}

class _GraphicsBackendHintPanel extends StatelessWidget {
  const _GraphicsBackendHintPanel({required this.hints, this.errorMessage});

  final ProgramGraphicsBackendHintsSummary? hints;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final error = errorMessage;
    final currentHints = hints;
    final suggestion = currentHints?.suggestions.firstOrNull;
    final signalText = currentHints == null
        ? ''
        : currentHints.signals.map((signal) => signal.value).join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error == null ? Icons.auto_awesome_motion : Icons.warning,
              size: 18,
              color: error == null ? colorScheme.primary : colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations.graphicsBackendHint,
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  if (error != null)
                    Text(error, style: TextStyle(color: colorScheme.error))
                  else if (currentHints != null && suggestion != null)
                    Text(
                      localizations.recommendedGraphicsBackend(
                        _graphicsBackendLabel(
                          suggestion: suggestion,
                          hints: currentHints,
                          localizations: localizations,
                        ),
                      ),
                    )
                  else
                    Text(localizations.graphicsBackendHintUnavailable),
                  if (error == null && signalText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      localizations.detectedGraphicsSignals(signalText),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _graphicsBackendLabel({
  required ProgramGraphicsBackendSuggestionSummary suggestion,
  required ProgramGraphicsBackendHintsSummary hints,
  required KonyakLocalizations localizations,
}) {
  return switch (suggestion.backend) {
    'wineDefault' => localizations.defaultLabel,
    'dxvk' => hints.hostPlatform == 'macos' ? 'DXVK-macOS' : 'DXVK',
    'dxmt' => 'DXMT',
    'd3dMetal' => 'GPTK/D3DMetal',
    'vkd3dProton' => 'vkd3d-proton',
    _ => suggestion.backend,
  };
}
