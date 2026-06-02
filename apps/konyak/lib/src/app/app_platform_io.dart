import 'dart:io' as io;

import 'app_platform.dart';

KonyakPlatform currentKonyakPlatform() {
  return io.Platform.isMacOS ? KonyakPlatform.macos : KonyakPlatform.linux;
}
