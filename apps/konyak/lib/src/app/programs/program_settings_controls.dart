import 'package:flutter/material.dart';

import '../../files/file_picker_arguments.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import 'program_environment_editor.dart';
import 'wine_logging_channel_menu.dart';

class ProgramSettingsControls extends StatelessWidget {
  const ProgramSettingsControls({
    super.key,
    required this.keyPrefix,
    required this.locale,
    required this.argumentsController,
    required this.environmentControllers,
    required this.createLogFile,
    required this.wineLoggingChannelsController,
    required this.logFilePathController,
    required this.defaultLogPath,
    required this.onLocaleChanged,
    required this.onCreateLogFileChanged,
    required this.onChooseLogFile,
    required this.onAddEnvironmentVariable,
    required this.onRemoveEnvironmentVariable,
  });

  final String keyPrefix;
  final String locale;
  final TextEditingController argumentsController;
  final List<ProgramEnvironmentControllers> environmentControllers;
  final bool createLogFile;
  final TextEditingController wineLoggingChannelsController;
  final TextEditingController logFilePathController;
  final String defaultLogPath;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<bool> onCreateLogFileChanged;
  final VoidCallback onChooseLogFile;
  final VoidCallback onAddEnvironmentVariable;
  final ValueChanged<int> onRemoveEnvironmentVariable;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottleConfigurationSection(
          title: localizations.program,
          children: [
            BottleConfigurationRow(
              label: localizations.locale,
              trailing: ConfigurationDropdown(
                key: ValueKey('$keyPrefix-locale'),
                value: locale,
                labels: localizedProgramLocaleLabels(localizations),
                onChanged: onLocaleChanged,
              ),
            ),
            BottleConfigurationRow(
              label: localizations.arguments,
              trailing: ConfigurationTextField(
                key: ValueKey('$keyPrefix-arguments-field'),
                controller: argumentsController,
                hintText: '-windowed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        BottleConfigurationSection(
          title: localizations.environment,
          children: [
            ProgramEnvironmentEditor(
              keyPrefix: keyPrefix,
              controllers: environmentControllers,
              onAdd: onAddEnvironmentVariable,
              onRemove: onRemoveEnvironmentVariable,
            ),
          ],
        ),
        const SizedBox(height: 14),
        BottleConfigurationSection(
          title: localizations.logging,
          children: [
            BottleConfigurationSwitchRow(
              switchKey: ValueKey('$keyPrefix-create-log-file'),
              label: localizations.createLogFile,
              value: createLogFile,
              onChanged: onCreateLogFileChanged,
            ),
            BottleConfigurationRow(
              label: localizations.additionalWineLoggingChannels,
              trailing: ConfigurationTextField(
                key: ValueKey('$keyPrefix-wine-logging-channels-field'),
                controller: wineLoggingChannelsController,
                hintText: '+seh,+relay',
                suffixIcon: WineLoggingChannelMenu(
                  key: ValueKey('$keyPrefix-wine-logging-channel-menu'),
                  onSelected: (channels) {
                    appendWineLoggingChannels(
                      wineLoggingChannelsController,
                      channels,
                    );
                  },
                ),
              ),
            ),
            BottleConfigurationRow(
              label: localizations.logFile,
              trailing: ProgramLogFilePathControl(
                keyPrefix: keyPrefix,
                controller: logFilePathController,
                defaultLogPath: defaultLogPath,
                onChooseLogFile: onChooseLogFile,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProgramLogFilePathControl extends StatelessWidget {
  const ProgramLogFilePathControl({
    super.key,
    required this.keyPrefix,
    required this.controller,
    required this.defaultLogPath,
    required this.onChooseLogFile,
  });

  final String keyPrefix;
  final TextEditingController controller;
  final String defaultLogPath;
  final VoidCallback onChooseLogFile;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

    return SizedBox(
      width: 330,
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: ValueKey('$keyPrefix-log-file-path-field'),
              controller: controller,
              style: TextStyle(color: colors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: defaultLogPath,
                hintStyle: TextStyle(color: colors.mutedText, fontSize: 13),
                isDense: true,
                filled: true,
                fillColor: colors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.mutedText),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: ValueKey('$keyPrefix-change-log-file'),
            onPressed: onChooseLogFile,
            child: Text(localizations.change),
          ),
        ],
      ),
    );
  }
}

String programDefaultLogPath(String bottlePath) {
  if (bottlePath.endsWith('/')) {
    return '${bottlePath}logs/latest.log';
  }

  return '$bottlePath/logs/latest.log';
}

String effectiveProgramLogPath({
  required String selectedLogPath,
  required String defaultLogPath,
}) {
  final selectedPath = selectedLogPath.trim();
  if (selectedPath.isNotEmpty) {
    return selectedPath;
  }

  return defaultLogPath.trim();
}

FilePickerInitialDirectory programPathInitialDirectory(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return const FilePickerInitialDirectory.inherited();
  }

  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return const FilePickerInitialDirectory.inherited();
  }

  return filePickerInitialDirectoryFromPath(normalized.substring(0, separator));
}

FilePickerSuggestedName programPathSuggestedLogName(String path) {
  return filePickerSuggestedNameFromPath(path: path, fallback: 'latest.log');
}
