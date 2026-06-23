import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import 'pinned_program_context_menu.dart';
import 'pinned_program_icon.dart';

class PinnedProgramTile extends StatefulWidget {
  const PinnedProgramTile({
    super.key,
    required this.platform,
    required this.bottle,
    required this.program,
    required this.onRunProgramPath,
    required this.onConfigurePinnedProgram,
    required this.onUnpinProgram,
    required this.onRenamePinnedProgram,
    required this.onOpenPinnedProgramLocation,
  });

  final KonyakPlatform platform;
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
  State<PinnedProgramTile> createState() => _PinnedProgramTileState();
}

class _PinnedProgramTileState extends State<PinnedProgramTile>
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
    final selectedAction = await showMenu<PinnedProgramContextMenuAction>(
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
      items: pinnedProgramContextMenuItems(colors, widget.platform),
    );

    if (!mounted || selectedAction == null) {
      return;
    }

    switch (selectedAction) {
      case PinnedProgramContextMenuAction.run:
        unawaited(_bounceController.forward(from: 0));
        widget.onRunProgramPath?.call(widget.bottle, widget.program.path);
      case PinnedProgramContextMenuAction.config:
        widget.onConfigurePinnedProgram?.call(widget.bottle, widget.program);
      case PinnedProgramContextMenuAction.unpin:
        widget.onUnpinProgram?.call(widget.bottle, widget.program);
      case PinnedProgramContextMenuAction.rename:
        widget.onRenamePinnedProgram?.call(widget.bottle, widget.program);
      case PinnedProgramContextMenuAction.showInFinder:
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
                  PinnedProgramIcon(program: widget.program),
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
