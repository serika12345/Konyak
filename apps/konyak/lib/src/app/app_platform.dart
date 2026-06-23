enum KonyakPlatform {
  linux,
  macos;

  bool get isLinux => this == KonyakPlatform.linux;
  bool get isMacOS => this == KonyakPlatform.macos;

  String get showInFileManagerLabel {
    return isMacOS ? 'Show in Finder' : 'Show in File Manager';
  }
}
