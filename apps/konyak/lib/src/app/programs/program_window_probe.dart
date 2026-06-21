import 'package:flutter/services.dart';

import '../app_platform.dart';

abstract interface class ProgramWindowProbe {
  Future<Set<String>?> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  });

  Future<Set<int>?> runningWineProcessIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcesses = false,
  });
}

final class NativeProgramWindowProbe implements ProgramWindowProbe {
  const NativeProgramWindowProbe();

  static const MethodChannel _macosMenuChannel = MethodChannel('konyak/menu');
  static const MethodChannel _linuxWindowChannel = MethodChannel(
    'konyak/linux_window',
  );

  @override
  Future<Set<String>?> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  }) async {
    if (!platform.isMacOS && !platform.isLinux) {
      return null;
    }

    final rootProcessIds = descendantOfProcessIds
        .where((processId) => processId > 0)
        .toSet();
    if (rootProcessIds.isEmpty && !includeWineProcessWindows) {
      return null;
    }

    final channel = platform.isMacOS ? _macosMenuChannel : _linuxWindowChannel;

    try {
      final windowIds = await channel.invokeListMethod<String>(
        'visibleExternalWindowIds',
        <String, Object>{
          'descendantOfProcessIds': rootProcessIds.toList(growable: false)
            ..sort(),
          'includeWineProcessWindows': includeWineProcessWindows,
        },
      );
      if (windowIds == null) {
        return null;
      }

      return <String>{
        for (final windowId in windowIds)
          if (windowId.trim().isNotEmpty) windowId.trim(),
      };
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<Set<int>?> runningWineProcessIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcesses = false,
  }) async {
    if (!platform.isLinux) {
      return null;
    }

    final rootProcessIds = descendantOfProcessIds
        .where((processId) => processId > 0)
        .toSet();
    if (rootProcessIds.isEmpty && !includeWineProcesses) {
      return null;
    }

    try {
      final processIds = await _linuxWindowChannel
          .invokeListMethod<int>('runningWineProcessIds', <String, Object>{
            'descendantOfProcessIds': rootProcessIds.toList(growable: false)
              ..sort(),
            'includeWineProcesses': includeWineProcesses,
          });
      if (processIds == null) {
        return null;
      }

      return <int>{
        for (final processId in processIds)
          if (processId > 0) processId,
      };
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
