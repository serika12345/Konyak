import 'package:flutter/material.dart';

import '../app_constants.dart';

class KonyakToggle extends StatelessWidget {
  const KonyakToggle({super.key, required this.value, required this.onChanged});

  static const double _width = 36;
  static const double _height = 20;
  static const double _thumbSize = 16;
  static const Duration _duration = Duration(milliseconds: 70);

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final isEnabled = onChanged != null;
    final trackColor = switch ((isEnabled, value)) {
      (false, true) => colors.toggleDisabledOnTrack,
      (false, false) => colors.toggleDisabledOffTrack,
      (true, true) => colors.toggleEnabledOnTrack,
      (true, false) => colors.toggleEnabledOffTrack,
    };
    final borderColor = switch ((isEnabled, value)) {
      (false, true) => colors.toggleDisabledOnBorder,
      (false, false) => colors.toggleDisabledOffBorder,
      (true, true) => colors.toggleEnabledOnBorder,
      (true, false) => colors.toggleEnabledOffBorder,
    };
    final thumbColor = isEnabled
        ? colors.toggleEnabledThumb
        : colors.toggleDisabledThumb;

    return Semantics(
      button: true,
      toggled: value,
      enabled: isEnabled,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isEnabled ? () => onChanged!(!value) : null,
          child: SizedBox(
            width: _width,
            height: _height,
            child: AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(_height / 2),
                border: Border.all(color: borderColor),
              ),
              child: AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                    boxShadow: isEnabled
                        ? const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
