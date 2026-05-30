import 'package:flutter/material.dart';

import '../app_constants.dart';

class BlockingProgressOverlay extends StatelessWidget {
  const BlockingProgressOverlay({
    super.key,
    required this.message,
    this.progress,
  });

  final String message;
  final double? progress;

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
                    horizontal: 22,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 360,
                      maxWidth: 520,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: LinearProgressIndicator(
                            value: progress,
                            color: colors.accent,
                            backgroundColor: colors.border,
                            minHeight: 4,
                          ),
                        ),
                        if (progress case final progress?) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                color: colors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
