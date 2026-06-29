import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';

part 'app_settings_models.freezed.dart';

enum AppAppearanceMode { dark, light, system }

enum AppLanguageMode { system, english, japanese }

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class AppSettingsRecord with _$AppSettingsRecord {
  const AppSettingsRecord._();

  factory AppSettingsRecord({
    bool terminateWineProcessesOnClose = false,
    required String defaultBottlePath,
    AppAppearanceMode appearanceMode = AppAppearanceMode.dark,
    AppLanguageMode languageMode = AppLanguageMode.system,
    bool automaticallyCheckForKonyakUpdates = false,
    bool automaticallyCheckForWineUpdates = true,
    bool automaticallyPinNewInstalledPrograms = true,
  }) {
    return AppSettingsRecord._validated(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: DefaultBottlePath(defaultBottlePath),
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  const factory AppSettingsRecord._validated({
    required bool terminateWineProcessesOnClose,
    required DefaultBottlePath defaultBottlePath,
    required AppAppearanceMode appearanceMode,
    required AppLanguageMode languageMode,
    required bool automaticallyCheckForKonyakUpdates,
    required bool automaticallyCheckForWineUpdates,
    required bool automaticallyPinNewInstalledPrograms,
  }) = _AppSettingsRecord;
}
