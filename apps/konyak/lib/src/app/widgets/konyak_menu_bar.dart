import 'dart:async';

import 'package:flutter/material.dart';

import '../app_constants.dart';
import '../window/linux_window_controls.dart';

class KonyakMenuDefinition {
  KonyakMenuDefinition({
    required this.label,
    required List<KonyakMenuItemDefinition> items,
  }) : items = List.unmodifiable(items);

  final String label;
  final List<KonyakMenuItemDefinition> items;
}

class KonyakMenuItemDefinition {
  const KonyakMenuItemDefinition({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class KonyakMenuBar extends StatelessWidget {
  KonyakMenuBar({
    super.key,
    required List<KonyakMenuDefinition> menus,
    this.windowControls = const KonyakLinuxWindowControls(),
  }) : menus = List.unmodifiable(menus);

  final List<KonyakMenuDefinition> menus;
  final KonyakLinuxWindowControls windowControls;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Container(
      key: const ValueKey('linux-menu-bar'),
      height: 38,
      decoration: BoxDecoration(
        color: colors.windowBackground,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: MenuBar(
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(
                  colors.windowBackground,
                ),
                elevation: const WidgetStatePropertyAll(0),
                minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -3,
                ),
              ),
              children: [
                for (final menu in menus)
                  SubmenuButton(
                    style: ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(colors.text),
                      minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 10),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -3,
                      ),
                    ),
                    menuChildren: [
                      for (final item in menu.items)
                        MenuItemButton(
                          leadingIcon: Icon(item.icon, size: 16),
                          onPressed: item.onPressed,
                          child: Text(item.label),
                        ),
                    ],
                    child: Text(menu.label),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _LinuxWindowDragRegion(windowControls: windowControls),
          ),
          _LinuxWindowControlButton(
            key: const ValueKey('linux-window-minimize-button'),
            tooltip: 'Minimize window',
            icon: Icons.minimize,
            onPressed: () {
              unawaited(windowControls.minimizeWindow());
            },
          ),
          _LinuxWindowControlButton(
            key: const ValueKey('linux-window-maximize-button'),
            tooltip: 'Maximize or restore window',
            icon: Icons.crop_square,
            onPressed: () {
              unawaited(windowControls.toggleMaximizeWindow());
            },
          ),
          _LinuxWindowControlButton(
            key: const ValueKey('linux-window-close-button'),
            tooltip: 'Close window',
            icon: Icons.close,
            onPressed: () {
              unawaited(windowControls.closeWindow());
            },
          ),
        ],
      ),
    );
  }
}

class _LinuxWindowDragRegion extends StatefulWidget {
  const _LinuxWindowDragRegion({required this.windowControls});

  final KonyakLinuxWindowControls windowControls;

  @override
  State<_LinuxWindowDragRegion> createState() => _LinuxWindowDragRegionState();
}

class _LinuxWindowDragRegionState extends State<_LinuxWindowDragRegion> {
  final _regionKey = GlobalKey();
  Rect? _lastRegion;
  bool _isUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleRegionUpdate();
  }

  @override
  void didUpdateWidget(_LinuxWindowDragRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRegionUpdate();
  }

  @override
  void dispose() {
    unawaited(widget.windowControls.clearWindowDragRegion());
    super.dispose();
  }

  void _scheduleRegionUpdate() {
    if (_isUpdateScheduled) {
      return;
    }
    _isUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdateScheduled = false;
      if (!mounted) {
        return;
      }

      final renderObject = _regionKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return;
      }

      final topLeft = renderObject.localToGlobal(Offset.zero);
      final region = topLeft & renderObject.size;
      if (_lastRegion == region) {
        return;
      }

      _lastRegion = region;
      unawaited(widget.windowControls.setWindowDragRegion(region));
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRegionUpdate();
    return SizedBox.expand(
      key: const ValueKey('linux-menu-drag-region'),
      child: SizedBox.expand(key: _regionKey),
    );
  }
}

class _LinuxWindowControlButton extends StatelessWidget {
  const _LinuxWindowControlButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: colors.toolbarIcon,
      iconSize: 18,
      constraints: const BoxConstraints.tightFor(width: 40, height: 38),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      icon: Icon(icon),
    );
  }
}
