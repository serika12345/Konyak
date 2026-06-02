part of '../konyak_cli.dart';

KonyakHostPlatform _currentHostPlatform() {
  return switch (Platform.operatingSystem) {
    'macos' => KonyakHostPlatform.macos,
    _ => KonyakHostPlatform.linux,
  };
}

String _pathOpenExecutable() {
  return switch (_currentHostPlatform()) {
    KonyakHostPlatform.macos =>
      File('/usr/bin/open').existsSync() ? '/usr/bin/open' : 'open',
    KonyakHostPlatform.linux => 'xdg-open',
  };
}
