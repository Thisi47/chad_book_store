import 'package:flutter/material.dart';

void showAppMessage(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
  Duration? duration,
}) {
  final colors = Theme.of(context).colorScheme;
  final background = isError
      ? colors.errorContainer
      : colors.secondaryContainer;
  final foreground = isError
      ? colors.onErrorContainer
      : colors.onSecondaryContainer;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration:
            duration ??
            (action == null
                ? const Duration(seconds: 4)
                : const Duration(seconds: 10)),
        backgroundColor: background,
        action: action,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
                color: foreground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
}
