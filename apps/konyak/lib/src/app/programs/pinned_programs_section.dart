import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../home/sidebar.dart';

class PinnedProgramsSection extends StatelessWidget {
  const PinnedProgramsSection({
    super.key,
    required this.bottle,
    required this.onPinProgram,
    required this.onRunProgramPath,
    required this.onConfigurePinnedProgram,
    required this.onUnpinProgram,
    required this.onRenamePinnedProgram,
    required this.onOpenPinnedProgramLocation,
  });

  final BottleSummary bottle;
  final ValueChanged<BottleSummary>? onPinProgram;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onConfigurePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onUnpinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onRenamePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final program in bottle.pinnedPrograms)
          _PinnedProgramTile(
            bottle: bottle,
            program: program,
            onRunProgramPath: onRunProgramPath,
            onConfigurePinnedProgram: onConfigurePinnedProgram,
            onUnpinProgram: onUnpinProgram,
            onRenamePinnedProgram: onRenamePinnedProgram,
            onOpenPinnedProgramLocation: onOpenPinnedProgramLocation,
          ),
        _PinProgramAction(bottle: bottle, onPinProgram: onPinProgram),
      ],
    );
  }
}

class _PinnedProgramTile extends StatefulWidget {
  const _PinnedProgramTile({
    required this.bottle,
    required this.program,
    required this.onRunProgramPath,
    required this.onConfigurePinnedProgram,
    required this.onUnpinProgram,
    required this.onRenamePinnedProgram,
    required this.onOpenPinnedProgramLocation,
  });

  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onConfigurePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onUnpinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onRenamePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;

  @override
  State<_PinnedProgramTile> createState() => _PinnedProgramTileState();
}

class _PinnedProgramTileState extends State<_PinnedProgramTile>
    with SingleTickerProviderStateMixin {
  static const Duration _doubleClickInterval = Duration(milliseconds: 350);

  bool _isSelected = false;
  bool _isPressed = false;
  Duration? _lastPointerDownAt;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.18,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.96,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _animateClickFeedback() async {
    setState(() {
      _isPressed = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 90));

    if (!mounted) {
      return;
    }

    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapFeedback() {
    setState(() {
      _isSelected = true;
    });
    _animateClickFeedback();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _handleTapFeedback();

    if (event.buttons == kSecondaryMouseButton) {
      unawaited(_showContextMenu(event.position));
      return;
    }

    if (event.buttons != kPrimaryMouseButton) {
      return;
    }

    final lastPointerDownAt = _lastPointerDownAt;
    _lastPointerDownAt = event.timeStamp;
    if (lastPointerDownAt == null) {
      return;
    }

    final elapsed = event.timeStamp - lastPointerDownAt;
    if (elapsed.isNegative || elapsed > _doubleClickInterval) {
      return;
    }

    _bounceController.forward(from: 0);
    widget.onRunProgramPath?.call(widget.bottle, widget.program.path);
    _lastPointerDownAt = null;
  }

  Future<void> _showContextMenu(Offset globalPosition) async {
    final colors = KonyakThemeColors.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selectedAction = await showMenu<_PinnedProgramContextMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      color: colors.menuBackground,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.menuBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
      items: _pinnedProgramContextMenuItems(colors),
    );

    if (!mounted || selectedAction == null) {
      return;
    }

    switch (selectedAction) {
      case _PinnedProgramContextMenuAction.run:
        unawaited(_bounceController.forward(from: 0));
        widget.onRunProgramPath?.call(widget.bottle, widget.program.path);
      case _PinnedProgramContextMenuAction.config:
        widget.onConfigurePinnedProgram?.call(widget.bottle, widget.program);
      case _PinnedProgramContextMenuAction.unpin:
        widget.onUnpinProgram?.call(widget.bottle, widget.program);
      case _PinnedProgramContextMenuAction.rename:
        widget.onRenamePinnedProgram?.call(widget.bottle, widget.program);
      case _PinnedProgramContextMenuAction.showInFinder:
        widget.onOpenPinnedProgramLocation?.call(widget.bottle, widget.program);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final isEnabled = widget.onRunProgramPath != null;

    return Tooltip(
      message: '${widget.program.path}\nDouble-click to run',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: isEnabled ? _handlePointerDown : null,
        child: ScaleTransition(
          key: ValueKey('pinned-program-bounce-${widget.program.path}'),
          scale: _bounceScale,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            scale: _isPressed ? 0.96 : 1,
            child: AnimatedContainer(
              key: ValueKey('pinned-program-tile-${widget.program.path}'),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: 76,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                color: _isSelected
                    ? colors.programTileSelectedBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSelected
                      ? colors.programTileSelectedBorder
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PinnedProgramIcon(program: widget.program),
                  const SizedBox(height: 8),
                  Text(
                    widget.program.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.text, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedProgramIcon extends StatelessWidget {
  const _PinnedProgramIcon({required this.program});

  final PinnedProgramSummary program;

  @override
  Widget build(BuildContext context) {
    final iconPath = program.iconPath;
    if (iconPath == null || iconPath.trim().isEmpty) {
      return const _PinnedProgramFallbackIcon();
    }

    try {
      return Image.memory(
        File(iconPath).readAsBytesSync(),
        key: ValueKey('pinned-program-icon-${program.path}'),
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const _PinnedProgramFallbackIcon(),
      );
    } on FileSystemException {
      return const _PinnedProgramFallbackIcon();
    }
  }
}

class _PinnedProgramFallbackIcon extends StatelessWidget {
  const _PinnedProgramFallbackIcon();

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Icon(
      Icons.web_asset_outlined,
      color: colors.pinnedProgramIcon,
      size: 44,
    );
  }
}

enum _PinnedProgramContextMenuAction {
  run,
  config,
  unpin,
  rename,
  showInFinder,
}

List<PopupMenuEntry<_PinnedProgramContextMenuAction>>
_pinnedProgramContextMenuItems(KonyakThemeColors colors) {
  return [
    const PopupMenuItem<_PinnedProgramContextMenuAction>(
      value: _PinnedProgramContextMenuAction.run,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-run'),
        icon: Icons.play_arrow_outlined,
        label: 'Run...',
      ),
    ),
    const PopupMenuDivider(height: 8),
    PopupMenuItem<_PinnedProgramContextMenuAction>(
      enabled: false,
      height: 28,
      child: Text(
        'Settings',
        key: const ValueKey('pinned-program-context-settings-header'),
        style: TextStyle(
          color: colors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    const PopupMenuItem<_PinnedProgramContextMenuAction>(
      value: _PinnedProgramContextMenuAction.config,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-config'),
        icon: Icons.settings_outlined,
        label: 'Config',
      ),
    ),
    const PopupMenuItem<_PinnedProgramContextMenuAction>(
      value: _PinnedProgramContextMenuAction.unpin,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-unpin'),
        icon: Icons.push_pin_outlined,
        label: 'Unpin',
      ),
    ),
    const PopupMenuDivider(height: 8),
    const PopupMenuItem<_PinnedProgramContextMenuAction>(
      value: _PinnedProgramContextMenuAction.rename,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-rename'),
        icon: Icons.edit_outlined,
        label: 'Rename...',
      ),
    ),
    const PopupMenuItem<_PinnedProgramContextMenuAction>(
      value: _PinnedProgramContextMenuAction.showInFinder,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-show-in-finder'),
        icon: Icons.folder_outlined,
        label: 'Show in Finder',
      ),
    ),
  ];
}

class _PinProgramAction extends StatelessWidget {
  const _PinProgramAction({required this.bottle, required this.onPinProgram});

  final BottleSummary bottle;
  final ValueChanged<BottleSummary>? onPinProgram;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Tooltip(
      message: 'Pin program in ${bottle.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPinProgram == null ? null : () => onPinProgram!(bottle),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.pinProgramBorder, width: 4),
                ),
                child: Icon(Icons.add, color: colors.pinProgramIcon, size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                'Pin Program',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.text, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
