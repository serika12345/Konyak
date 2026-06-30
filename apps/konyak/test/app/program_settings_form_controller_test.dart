import 'package:flutter_test/flutter_test.dart';

import 'package:konyak/src/app/programs/program_settings_form_controller.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/cli/konyak_cli_program_commands.dart';

void main() {
  test('loads persisted program settings into form controllers', () {
    final controller = ProgramSettingsFormController.fromSettings(
      ProgramSettingsSummary(
        locale: 'ja_JP.UTF-8',
        arguments: '-windowed',
        environment: const <String, String>{'WINEDEBUG': '+seh'},
        logging: const ProgramLoggingSettingsSummary(
          createLogFile: false,
          additionalWineLoggingChannels: '+seh',
          logFilePath: '/tmp/setup.log',
        ),
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.locale, 'ja_JP.UTF-8');
    expect(controller.argumentsController.text, '-windowed');
    expect(controller.createLogFile, isFalse);
    expect(controller.wineLoggingChannelsController.text, '+seh');
    expect(controller.logFilePathController.text, '/tmp/setup.log');
    expect(controller.environmentControllers, hasLength(1));
    expect(
      controller.environmentControllers.single.nameController.text,
      'WINEDEBUG',
    );
    expect(
      controller.environmentControllers.single.valueController.text,
      '+seh',
    );
  });

  test('normalizes unsupported locales when replacing settings', () {
    final controller = ProgramSettingsFormController.fromSettings(
      ProgramSettingsSummary(locale: 'ja_JP.UTF-8'),
    );
    addTearDown(controller.dispose);

    controller.replaceSettings(ProgramSettingsSummary(locale: 'unsupported'));

    expect(controller.locale, '');
  });

  test('builds program settings from current form values', () {
    final controller = ProgramSettingsFormController();
    addTearDown(controller.dispose);

    controller.setLocale('ja_JP.UTF-8');
    controller.argumentsController.text = '-windowed';
    controller.setCreateLogFile(false);
    controller.wineLoggingChannelsController.text = '+seh';
    controller.logFilePathController.text = '/tmp/setup.log';
    controller.addEnvironmentVariable();
    controller.environmentControllers.single.nameController.text = 'WINEDEBUG';
    controller.environmentControllers.single.valueController.text = '+seh';

    final settings = controller.toSettings();

    expect(settings.locale, 'ja_JP.UTF-8');
    expect(settings.arguments, '-windowed');
    expect(settings.environment.unlockView, <String, String>{
      'WINEDEBUG': '+seh',
    });
    expect(settings.logging.createLogFile, isFalse);
    expect(settings.logging.additionalWineLoggingChannels, '+seh');
    expect(settings.logging.logFilePath, '/tmp/setup.log');
  });

  test('builds explicit one-shot settings arguments', () {
    final controller = ProgramSettingsFormController();
    addTearDown(controller.dispose);

    expect(controller.toRunSettingsArgument(), const NoProgramRunSettings());

    controller.argumentsController.text = '-windowed';

    final settings = controller.toRunSettingsArgument();
    switch (settings) {
      case UseProgramRunSettings(:final settings):
        expect(settings.arguments, '-windowed');
      case NoProgramRunSettings():
        fail('Expected one-shot settings to be used.');
    }
  });

  test('uses the selected log path when present', () {
    final controller = ProgramSettingsFormController();
    addTearDown(controller.dispose);

    expect(
      controller.effectiveLogPath(defaultLogPath: '/tmp/default.log'),
      '/tmp/default.log',
    );

    controller.logFilePathController.text = ' /tmp/custom.log ';

    expect(
      controller.effectiveLogPath(defaultLogPath: '/tmp/default.log'),
      '/tmp/custom.log',
    );
  });

  test('adds and removes environment rows', () {
    final controller = ProgramSettingsFormController();
    addTearDown(controller.dispose);

    controller.addEnvironmentVariable(name: 'WINEDEBUG', value: '+seh');
    controller.addEnvironmentVariable(name: 'DXVK_HUD', value: 'fps');
    controller.removeEnvironmentVariable(0);

    expect(controller.environmentControllers, hasLength(1));
    expect(
      controller.environmentControllers.single.nameController.text,
      'DXVK_HUD',
    );
    expect(
      controller.environmentControllers.single.valueController.text,
      'fps',
    );
  });
}
