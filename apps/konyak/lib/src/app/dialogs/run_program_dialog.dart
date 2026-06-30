import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../cli/konyak_cli_client.dart';
import '../../files/file_path_pick_result.dart';
import '../../files/file_picker_arguments.dart';
import '../../files/log_file_picker.dart';
import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../programs/program_settings_controls.dart';
import '../programs/program_settings_form_controller.dart';

part 'run_program_dialog.freezed.dart';

typedef GraphicsBackendHintsLoader =
    Future<GraphicsBackendHintsLoadResult> Function(String programPath);

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RunProgramDialogDecision with _$RunProgramDialogDecision {
  const factory RunProgramDialogDecision.run({
    required String programPath,
    required ProgramRunSettingsArgument settings,
  }) = RunProgramFromDialog;

  const factory RunProgramDialogDecision.cancelled() =
      CancelledRunProgramDialog;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RunProgramGraphicsBackendHintState
    with _$RunProgramGraphicsBackendHintState {
  const factory RunProgramGraphicsBackendHintState.none() =
      NoRunProgramGraphicsBackendHint;

  const factory RunProgramGraphicsBackendHintState.loading() =
      LoadingRunProgramGraphicsBackendHint;

  const factory RunProgramGraphicsBackendHintState.loaded(
    ProgramGraphicsBackendHintsSummary hints,
  ) = LoadedRunProgramGraphicsBackendHint;

  const factory RunProgramGraphicsBackendHintState.failed(String message) =
      FailedRunProgramGraphicsBackendHint;
}

RunProgramDialogDecision runProgramDialogDecisionFromNullable(
  RunProgramDialogDecision? decision,
) {
  return decision ?? const RunProgramDialogDecision.cancelled();
}

RunProgramGraphicsBackendHintState
runProgramGraphicsBackendHintStateFromLoadResult(
  GraphicsBackendHintsLoadResult result,
) {
  return switch (result) {
    LoadedGraphicsBackendHints(:final hints) =>
      RunProgramGraphicsBackendHintState.loaded(hints),
    GraphicsBackendHintsLoadFailure(:final message) =>
      RunProgramGraphicsBackendHintState.failed(message),
  };
}

bool runProgramGraphicsBackendHintPanelVisible(
  RunProgramGraphicsBackendHintState state,
) {
  return switch (state) {
    LoadedRunProgramGraphicsBackendHint() ||
    FailedRunProgramGraphicsBackendHint() => true,
    NoRunProgramGraphicsBackendHint() ||
    LoadingRunProgramGraphicsBackendHint() => false,
  };
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
  final ProgramSettingsFormController _settingsController =
      ProgramSettingsFormController();
  bool _optionsExpanded = false;
  RunProgramGraphicsBackendHintState _graphicsBackendHintState =
      const RunProgramGraphicsBackendHintState.none();

  @override
  void dispose() {
    _programPathController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  void _submit() {
    final programPath = _programPathController.text.trim();
    if (programPath.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      RunProgramDialogDecision.run(
        programPath: programPath,
        settings: _runSettingsArgument(),
      ),
    );
  }

  Future<void> _chooseProgramFile() async {
    final selection = await widget.programFilePicker.pickProgramPath(
      initialDirectory: filePickerInitialDirectoryFromPath(
        widget.initialDirectory,
      ),
    );
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        setState(() {
          _programPathController.text = path;
          _clearGraphicsBackendHints();
        });
      case CancelledFilePathPick():
        return;
    }
  }

  Future<void> _loadGraphicsBackendHints() async {
    final loader = widget.graphicsBackendHintsLoader;
    final programPath = _programPathController.text.trim();
    if (loader == null || programPath.isEmpty) {
      return;
    }

    setState(() {
      _graphicsBackendHintState =
          const RunProgramGraphicsBackendHintState.loading();
    });

    final result = await loader(programPath);
    if (!mounted || _programPathController.text.trim() != programPath) {
      return;
    }

    setState(() {
      _graphicsBackendHintState =
          runProgramGraphicsBackendHintStateFromLoadResult(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final programPath = _programPathController.text.trim();
    final canSubmit = programPath.isNotEmpty;
    final localizations = KonyakLocalizations.of(context);
    final canInspectGraphicsBackend =
        widget.graphicsBackendHintsLoader != null && programPath.isNotEmpty;
    final isLoadingGraphicsBackendHints = switch (_graphicsBackendHintState) {
      LoadingRunProgramGraphicsBackendHint() => true,
      NoRunProgramGraphicsBackendHint() ||
      LoadedRunProgramGraphicsBackendHint() ||
      FailedRunProgramGraphicsBackendHint() => false,
    };

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
                      onPressed: isLoadingGraphicsBackendHints
                          ? null
                          : _loadGraphicsBackendHints,
                      icon: isLoadingGraphicsBackendHints
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.manage_search),
                      label: Text(localizations.detectGraphicsBackend),
                    ),
                  ),
                ),
              if (runProgramGraphicsBackendHintPanelVisible(
                _graphicsBackendHintState,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _GraphicsBackendHintPanel(
                    state: _graphicsBackendHintState,
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
                  locale: _settingsController.locale,
                  argumentsController: _settingsController.argumentsController,
                  environmentControllers:
                      _settingsController.environmentControllers,
                  createLogFile: _settingsController.createLogFile,
                  wineLoggingChannelsController:
                      _settingsController.wineLoggingChannelsController,
                  logFilePathController:
                      _settingsController.logFilePathController,
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
          onPressed: () {
            Navigator.of(
              context,
            ).pop(const RunProgramDialogDecision.cancelled());
          },
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
    setState(_settingsController.addEnvironmentVariable);
  }

  void _removeEnvironmentVariable(int index) {
    setState(() {
      _settingsController.removeEnvironmentVariable(index);
    });
  }

  void _setCreateLogFile(bool createLogFile) {
    setState(() {
      _settingsController.setCreateLogFile(createLogFile);
    });
  }

  void _setLocale(String locale) {
    setState(() {
      _settingsController.setLocale(locale);
    });
  }

  Future<void> _chooseLogFile() async {
    final currentPath = _settingsController.effectiveLogPath(
      defaultLogPath: widget.defaultLogPath,
    );
    final selection = await widget.logFilePicker.pickLogFilePath(
      initialDirectory: programPathInitialDirectory(currentPath),
      suggestedName: programPathSuggestedLogName(currentPath),
    );
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        setState(() {
          _settingsController.logFilePathController.text = path;
        });
      case CancelledFilePathPick():
        return;
    }
  }

  void _handleProgramPathChanged(String _) {
    setState(_clearGraphicsBackendHints);
  }

  void _clearGraphicsBackendHints() {
    _graphicsBackendHintState = const RunProgramGraphicsBackendHintState.none();
  }

  ProgramRunSettingsArgument _runSettingsArgument() {
    return _settingsController.toRunSettingsArgument();
  }
}

class _GraphicsBackendHintPanel extends StatelessWidget {
  const _GraphicsBackendHintPanel({required this.state});

  final RunProgramGraphicsBackendHintState state;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return switch (state) {
      LoadedRunProgramGraphicsBackendHint(:final hints) =>
        _GraphicsBackendHintFrame(
          icon: Icons.auto_awesome_motion,
          iconColor: colorScheme.primary,
          children: [
            Text(
              localizations.graphicsBackendHint,
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            switch (hints.suggestions) {
              [final suggestion, ...] => Text(
                localizations.recommendedGraphicsBackend(
                  _graphicsBackendLabel(
                    suggestion: suggestion,
                    hints: hints,
                    localizations: localizations,
                  ),
                ),
              ),
              _ => Text(localizations.graphicsBackendHintUnavailable),
            },
            if (hints.signals.map((signal) => signal.value).join(', ')
                case final signalText when signalText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                localizations.detectedGraphicsSignals(signalText),
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      FailedRunProgramGraphicsBackendHint(:final message) =>
        _GraphicsBackendHintFrame(
          icon: Icons.warning,
          iconColor: colorScheme.error,
          children: [
            Text(
              localizations.graphicsBackendHint,
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(message, style: TextStyle(color: colorScheme.error)),
          ],
        ),
      NoRunProgramGraphicsBackendHint() ||
      LoadingRunProgramGraphicsBackendHint() => const SizedBox.shrink(),
    };
  }
}

class _GraphicsBackendHintFrame extends StatelessWidget {
  const _GraphicsBackendHintFrame({
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children,
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
