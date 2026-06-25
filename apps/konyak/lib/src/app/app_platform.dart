import '../l10n/konyak_localizations.dart';

enum KonyakPlatform {
  linux,
  macos;

  bool get isLinux => this == KonyakPlatform.linux;
  bool get isMacOS => this == KonyakPlatform.macos;

  String get showInFileManagerLabel {
    return isMacOS ? 'Show in Finder' : 'Show in File Manager';
  }
}

String localizedShowInFileManagerLabel(
  KonyakLocalizations localizations,
  KonyakPlatform platform,
) {
  return platform.isMacOS
      ? localizations.showInFinder
      : localizations.showInFileManager;
}
