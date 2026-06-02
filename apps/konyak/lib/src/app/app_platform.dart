enum KonyakPlatform {
  linux,
  macos;

  bool get isLinux => this == KonyakPlatform.linux;
  bool get isMacOS => this == KonyakPlatform.macos;
}
