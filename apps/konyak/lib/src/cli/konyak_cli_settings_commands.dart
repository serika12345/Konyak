part of 'konyak_cli_client.dart';

extension KonyakCliSettingsCommands on KonyakCliClient {
  Future<AppSettingsLoadResult> getAppSettings() async {
    final result = await _run(const ['get-app-settings', '--json']);
    return _appSettingsResultFromCommand(
      result: result,
      command: 'get-app-settings',
    );
  }

  Future<AppSettingsLoadResult> setAppSettings({
    required AppSettingsSummary settings,
  }) async {
    final result = await _run([
      'set-app-settings',
      '--settings-json',
      jsonEncode(settings.toJson()),
      '--json',
    ]);
    return _appSettingsResultFromCommand(
      result: result,
      command: 'set-app-settings',
    );
  }
}
