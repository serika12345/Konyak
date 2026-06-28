import 'dart:async';

import '../../domain/runtime/runtime_models.dart';
import '../../io/runtime_install_progress_io.dart';
import 'macos_wine_install_requests.dart';

sealed class MacosWineInstallResult {
  const MacosWineInstallResult();
}

class MacosWineInstallCompleted extends MacosWineInstallResult {
  const MacosWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class MacosWineInstallFailed extends MacosWineInstallResult {
  const MacosWineInstallFailed(this.message);

  final String message;
}

abstract interface class MacosWineInstaller {
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}

abstract interface class MacosWineStreamingInstaller
    implements MacosWineInstaller {
  Future<MacosWineInstallResult> installStreaming(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}
