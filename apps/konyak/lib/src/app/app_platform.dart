import 'dart:io' as io;

enum KonyakPlatform {
  linux,
  macos;

  bool get isLinux => this == KonyakPlatform.linux;
  bool get isMacOS => this == KonyakPlatform.macos;
}

KonyakPlatform currentKonyakPlatform() {
  return io.Platform.isMacOS ? KonyakPlatform.macos : KonyakPlatform.linux;
}
