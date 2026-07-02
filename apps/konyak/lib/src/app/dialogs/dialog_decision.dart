import 'package:flutter/material.dart';

Future<T> showDialogDecision<T extends Object>({
  required BuildContext context,
  required WidgetBuilder builder,
  required T dismissedDecision,
}) async {
  final decision = await showDialog<T>(context: context, builder: builder);
  return decision ?? dismissedDecision;
}
