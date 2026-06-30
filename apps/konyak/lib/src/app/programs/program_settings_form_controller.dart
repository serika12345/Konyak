import 'package:flutter/widgets.dart';

import '../../bottles/bottle_summary.dart';
import '../../cli/konyak_cli_program_commands.dart';
import '../configuration_labels.dart';
import 'program_configuration_settings.dart';
import 'program_environment_editor.dart';

final class ProgramSettingsFormController {
  ProgramSettingsFormController() : this.fromSettings(ProgramSettingsSummary());

  ProgramSettingsFormController.fromSettings(ProgramSettingsSummary settings) {
    _argumentsController = TextEditingController();
    _wineLoggingChannelsController = TextEditingController();
    _logFilePathController = TextEditingController();
    _environmentControllers = <ProgramEnvironmentControllers>[];
    replaceSettings(settings);
  }

  late final TextEditingController _argumentsController;
  late final TextEditingController _wineLoggingChannelsController;
  late final TextEditingController _logFilePathController;
  late List<ProgramEnvironmentControllers> _environmentControllers;
  String _locale = '';
  bool _createLogFile = true;

  String get locale => _locale;

  bool get createLogFile => _createLogFile;

  TextEditingController get argumentsController => _argumentsController;

  TextEditingController get wineLoggingChannelsController {
    return _wineLoggingChannelsController;
  }

  TextEditingController get logFilePathController => _logFilePathController;

  List<ProgramEnvironmentControllers> get environmentControllers {
    return _environmentControllers;
  }

  void replaceSettings(ProgramSettingsSummary settings) {
    _locale = _normalizedLocale(settings.locale);
    _createLogFile = settings.logging.createLogFile;
    _argumentsController.text = settings.arguments;
    _wineLoggingChannelsController.text =
        settings.logging.additionalWineLoggingChannels;
    _logFilePathController.text = settings.logging.logFilePath;
    for (final controllers in _environmentControllers) {
      controllers.dispose();
    }
    _environmentControllers = settings.environment.entries
        .map(
          (entry) => ProgramEnvironmentControllers(
            name: entry.key,
            value: entry.value,
          ),
        )
        .toList(growable: true);
  }

  void setLocale(String locale) {
    _locale = _normalizedLocale(locale);
  }

  void setCreateLogFile(bool createLogFile) {
    _createLogFile = createLogFile;
  }

  void addEnvironmentVariable({String name = '', String value = ''}) {
    _environmentControllers.add(
      ProgramEnvironmentControllers(name: name, value: value),
    );
  }

  void removeEnvironmentVariable(int index) {
    _environmentControllers.removeAt(index).dispose();
  }

  ProgramSettingsSummary toSettings() {
    return ProgramSettingsSummary(
      locale: _locale,
      arguments: _argumentsController.text,
      environment: programEnvironmentFromEntries(
        _environmentControllers.map((controller) => controller.toEntry()),
      ),
      logging: ProgramLoggingSettingsSummary(
        createLogFile: _createLogFile,
        additionalWineLoggingChannels: _wineLoggingChannelsController.text,
        logFilePath: _logFilePathController.text,
      ),
    );
  }

  ProgramRunSettingsArgument toRunSettingsArgument() {
    final settings = toSettings();
    if (settings.locale.trim().isEmpty &&
        settings.arguments.trim().isEmpty &&
        settings.environment.isEmpty &&
        settings.logging.isDefault) {
      return const NoProgramRunSettings();
    }

    return UseProgramRunSettings(settings);
  }

  String effectiveLogPath({required String defaultLogPath}) {
    final selectedLogPath = _logFilePathController.text.trim();
    return selectedLogPath.isEmpty ? defaultLogPath : selectedLogPath;
  }

  void dispose() {
    _argumentsController.dispose();
    _wineLoggingChannelsController.dispose();
    _logFilePathController.dispose();
    for (final controllers in _environmentControllers) {
      controllers.dispose();
    }
  }
}

String _normalizedLocale(String locale) {
  return programLocaleLabels.containsKey(locale) ? locale : '';
}
