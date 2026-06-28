import 'dart:async';
import 'dart:convert';

import '../settings/app_settings_summary.dart';
import 'konyak_cli_client.dart' show KonyakCliClient;
import 'konyak_cli_result_helpers.dart';
import 'konyak_cli_settings_result_types.dart';

extension KonyakCliSettingsCommands on KonyakCliClient {
  Future<AppSettingsLoadResult> getAppSettings() async {
    final result = await run(const ['get-app-settings', '--json']);
    return appSettingsResultFromCommand(
      result: result,
      command: 'get-app-settings',
    );
  }

  Future<AppSettingsLoadResult> setAppSettings({
    required AppSettingsSummary settings,
  }) async {
    final result = await run([
      'set-app-settings',
      '--settings-json',
      jsonEncode(settings.toJson()),
      '--json',
    ]);
    return appSettingsResultFromCommand(
      result: result,
      command: 'set-app-settings',
    );
  }
}
