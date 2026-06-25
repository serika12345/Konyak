import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';

class PinProgramAction extends StatelessWidget {
  const PinProgramAction({
    super.key,
    required this.bottle,
    required this.onPinProgram,
  });

  final BottleSummary bottle;
  final ValueChanged<BottleSummary>? onPinProgram;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

    return Tooltip(
      message: localizations.pinProgramTooltip(bottle.name),
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
                localizations.text('Pin Program'),
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
