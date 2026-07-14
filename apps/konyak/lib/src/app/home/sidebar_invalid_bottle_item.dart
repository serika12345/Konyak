import 'package:flutter/material.dart';

import '../../bottles/invalid_bottle_record.dart';
import '../app_constants.dart';

class SidebarInvalidBottleItem extends StatelessWidget {
  const SidebarInvalidBottleItem({
    super.key,
    required this.invalidBottle,
    required this.onTap,
  });

  final InvalidBottleRecord invalidBottle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      key: ValueKey('sidebar-invalid-bottle-${invalidBottle.storageId}'),
      color: colorScheme.errorContainer.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_outlined,
                size: 17,
                color: colorScheme.error,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invalidBottle.storageId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.text, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invalidBottle.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.mutedText, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invalidBottle.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.mutedText, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
