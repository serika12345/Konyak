import 'package:flutter/material.dart';

import '../app_constants.dart';

class BlockingProgressOverlay extends StatelessWidget {
  const BlockingProgressOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.overlayPanelBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: colors.accent,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        message,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
