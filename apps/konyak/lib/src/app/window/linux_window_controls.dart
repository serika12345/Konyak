import 'package:flutter/services.dart';

class KonyakLinuxWindowControls {
  const KonyakLinuxWindowControls();

  static const _channel = MethodChannel('konyak/linux_window');

  Future<void> setWindowDragRegion(Rect region) {
    return _channel.invokeMethod<void>('setWindowDragRegion', {
      'left': region.left,
      'top': region.top,
      'right': region.right,
      'bottom': region.bottom,
    });
  }

  Future<void> clearWindowDragRegion() {
    return _channel.invokeMethod<void>('clearWindowDragRegion');
  }

  Future<void> minimizeWindow() {
    return _channel.invokeMethod<void>('minimizeWindow');
  }

  Future<void> toggleMaximizeWindow() {
    return _channel.invokeMethod<void>('toggleMaximizeWindow');
  }

  Future<void> closeWindow() {
    return _channel.invokeMethod<void>('closeWindow');
  }
}
