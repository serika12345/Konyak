import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';

const _snackBarHorizontalMargin = 16.0;
const _snackBarBottomMargin = 64.0;
const _snackBarLeadingWidth = 36.0;

SnackBar konyakSnackBar({
  required BuildContext context,
  required String message,
  Color? backgroundColor,
  Color? textColor,
  Widget? leading,
  SnackBarAction? action,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    showCloseIcon: true,
    closeIconColor: textColor ?? Theme.of(context).colorScheme.onSurface,
    margin: const EdgeInsets.fromLTRB(
      _snackBarHorizontalMargin,
      0,
      _snackBarHorizontalMargin,
      _snackBarBottomMargin,
    ),
    backgroundColor: backgroundColor,
    content: _CompactSnackBarMessage(
      message: message,
      textColor: textColor,
      leading: leading,
    ),
    action: action,
  );
}

class _CompactSnackBarMessage extends StatelessWidget {
  const _CompactSnackBarMessage({
    required this.message,
    this.textColor,
    this.leading,
  });

  final String message;
  final Color? textColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = textColor == null
        ? defaultStyle
        : defaultStyle.copyWith(color: textColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableMessageWidth =
            constraints.maxWidth -
            (leading == null ? 0 : _snackBarLeadingWidth);
        final showDetail =
            constraints.hasBoundedWidth &&
            _messageExceedsOneLine(
              context: context,
              message: message,
              style: effectiveStyle,
              maxWidth: availableMessageWidth,
            );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: effectiveStyle,
              ),
            ),
            if (showDetail) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _showSnackBarDetails(context, message),
                style: TextButton.styleFrom(
                  foregroundColor:
                      textColor ?? Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(KonyakLocalizations.of(context).showDetail),
              ),
            ],
          ],
        );
      },
    );
  }
}

bool _messageExceedsOneLine({
  required BuildContext context,
  required String message,
  required TextStyle style,
  required double maxWidth,
}) {
  if (maxWidth <= 0) {
    return true;
  }

  final painter = TextPainter(
    text: TextSpan(text: message, style: style),
    maxLines: 1,
    textDirection: Directionality.of(context),
  )..layout(maxWidth: maxWidth);

  return painter.didExceedMaxLines;
}

Future<void> _showSnackBarDetails(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(KonyakLocalizations.of(context).details),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(child: SelectableText(message)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(KonyakLocalizations.of(context).close),
          ),
        ],
      );
    },
  );
}
