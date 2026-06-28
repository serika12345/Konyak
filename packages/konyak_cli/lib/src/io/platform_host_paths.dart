import 'dart:io';

import '../domain/program/program_runner.dart';

KonyakHostPlatform currentHostPlatform() {
  return switch (Platform.operatingSystem) {
    'macos' => KonyakHostPlatform.macos,
    _ => KonyakHostPlatform.linux,
  };
}

String pathOpenExecutable() {
  return switch (currentHostPlatform()) {
    KonyakHostPlatform.macos =>
      File('/usr/bin/open').existsSync() ? '/usr/bin/open' : 'open',
    KonyakHostPlatform.linux => 'xdg-open',
  };
}
