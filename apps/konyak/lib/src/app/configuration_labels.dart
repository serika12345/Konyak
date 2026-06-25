import 'package:flutter/material.dart';

import '../l10n/konyak_localizations.dart';

const Map<String, String> enhancedSyncLabels = <String, String>{
  'none': 'None',
  'esync': 'ESync',
  'msync': 'MSync',
};

const Map<String, String> dxvkHudLabels = <String, String>{
  'full': 'Full',
  'partial': 'Partial',
  'fps': 'FPS',
  'off': 'Off',
};

const Map<String, String> buildVersionLabels = <String, String>{
  '0': 'Default',
  '3790': 'Windows XP x64 (3790)',
  '7601': 'Windows 7 SP1 (7601)',
  '9200': 'Windows 8 (9200)',
  '9600': 'Windows 8.1 (9600)',
  '19045': 'Windows 10 22H2 (19045)',
  '22000': 'Windows 11 21H2 (22000)',
  '22621': 'Windows 11 22H2 (22621)',
  '22631': 'Windows 11 23H2 (22631)',
  '26100': 'Windows 11 24H2 (26100)',
};

const Map<String, String> dpiScalingLabels = <String, String>{
  '96': '96 DPI',
  '120': '120 DPI',
  '144': '144 DPI',
  '168': '168 DPI',
  '192': '192 DPI',
  '216': '216 DPI',
  '240': '240 DPI',
  '264': '264 DPI',
  '288': '288 DPI',
  '312': '312 DPI',
  '336': '336 DPI',
  '360': '360 DPI',
  '384': '384 DPI',
  '408': '408 DPI',
  '432': '432 DPI',
  '456': '456 DPI',
  '480': '480 DPI',
};

const Map<String, String> programLocaleLabels = <String, String>{
  '': 'Auto',
  'de_DE.UTF-8': 'German',
  'en_US': 'English',
  'es_ES.UTF-8': 'Spanish',
  'fr_FR.UTF-8': 'French',
  'it_IT.UTF-8': 'Italian',
  'ja_JP.UTF-8': 'Japanese',
  'ko_KR.UTF-8': 'Korean',
  'ru_RU.UTF-8': 'Russian',
  'uk_UA.UTF-8': 'Ukrainian',
  'th_TH.UTF-8': 'Thai',
  'zh_CN.UTF-8': 'Chinese (Simplified)',
  'zh_TW.UTF-8': 'Chinese (Traditional)',
};

Map<String, String> localizedBuildVersionLabels(
  KonyakLocalizations localizations,
) {
  return _localizedLabels(localizations, buildVersionLabels);
}

Map<String, String> localizedEnhancedSyncLabels(
  KonyakLocalizations localizations,
) {
  return _localizedLabels(localizations, enhancedSyncLabels);
}

Map<String, String> localizedDxvkHudLabels(KonyakLocalizations localizations) {
  return _localizedLabels(localizations, dxvkHudLabels);
}

Map<String, String> localizedProgramLocaleLabels(
  KonyakLocalizations localizations,
) {
  return _localizedLabels(localizations, programLocaleLabels);
}

Map<String, String> _localizedLabels(
  KonyakLocalizations localizations,
  Map<String, String> labels,
) {
  return <String, String>{
    for (final entry in labels.entries)
      entry.key: _localizedConfigurationLabel(localizations, entry.value),
  };
}

String _localizedConfigurationLabel(
  KonyakLocalizations localizations,
  String label,
) {
  return switch (label) {
    'Auto' => localizations.auto,
    'Chinese (Simplified)' => localizations.chineseSimplified,
    'Chinese (Traditional)' => localizations.chineseTraditional,
    'Default' => localizations.defaultLabel,
    'English' => localizations.english,
    'French' => localizations.french,
    'Full' => localizations.full,
    'German' => localizations.german,
    'Italian' => localizations.italian,
    'Japanese' => localizations.japanese,
    'Korean' => localizations.korean,
    'None' => localizations.none,
    'Off' => localizations.off,
    'Partial' => localizations.partial,
    'Russian' => localizations.russian,
    'Spanish' => localizations.spanish,
    'Thai' => localizations.thai,
    'Ukrainian' => localizations.ukrainian,
    _ => label,
  };
}

const Map<String, String> _windowsVersionLabels = <String, String>{
  'winxp64': 'Windows XP',
  'win7': 'Windows 7',
  'win8': 'Windows 8',
  'win81': 'Windows 8.1',
  'win10': 'Windows 10',
  'win11': 'Windows 11',
};

List<DropdownMenuItem<String>> windowsVersionMenuItems(String currentVersion) {
  final labels = <String, String>{
    ..._windowsVersionLabels,
    if (!_windowsVersionLabels.containsKey(currentVersion))
      currentVersion: currentVersion,
  };

  return labels.entries
      .map(
        (entry) => DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        ),
      )
      .toList(growable: false);
}
