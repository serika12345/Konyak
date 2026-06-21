import 'package:flutter/material.dart';

import '../app_constants.dart';

class KonyakBottomButton extends StatelessWidget {
  const KonyakBottomButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return SizedBox(
      width: _bottomButtonWidth(label),
      height: 24,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.text,
          disabledForegroundColor: colors.buttonDisabledForeground,
          backgroundColor: colors.buttonBackground,
          disabledBackgroundColor: colors.buttonDisabledBackground,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontSize: 13),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label),
      ),
    );
  }
}

double _bottomButtonWidth(String label) {
  return switch (label) {
    'Open C: Drive' => 104,
    'Open Control Panel' => 138,
    'Open Registry Editor' => 150,
    'Open Wine Configuration' => 174,
    'Show in Finder' => 112,
    'Terminal' => 76,
    'Tools' => 64,
    'Winetricks' => 88,
    'Run' => 46,
    'Save' => 54,
    _ => 72,
  };
}
