import 'package:flutter/services.dart';

import '../app_platform.dart';

abstract interface class ProgramWindowProbe {
  Future<Set<String>?> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  });
}

final class NativeProgramWindowProbe implements ProgramWindowProbe {
  const NativeProgramWindowProbe();

  static const MethodChannel _macosMenuChannel = MethodChannel('konyak/menu');

  @override
  Future<Set<String>?> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  }) async {
    if (!platform.isMacOS) {
      return null;
    }

    final rootProcessIds = descendantOfProcessIds
        .where((processId) => processId > 0)
        .toSet();
    if (rootProcessIds.isEmpty && !includeWineProcessWindows) {
      return null;
    }

    try {
      final windowIds = await _macosMenuChannel.invokeListMethod<String>(
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
}
