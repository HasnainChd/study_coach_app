import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required SnackbarType type,
    required String title,
    String? message,
    VoidCallback? onUndo,
    Duration? duration,
  }) {
    final typeColor = _getTypeColor(type);
    final iconData = _getIconData(type);
    final autoDuration = duration ??
        (type == SnackbarType.error
            ? const Duration(seconds: 4)
            : (onUndo != null
                ? const Duration(seconds: 5)
                : const Duration(milliseconds: 2500)));

    final hasMessage = message != null && message.trim().isNotEmpty;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: autoDuration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 84, top: 16),
        padding: EdgeInsets.zero,
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.snackbarBg,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: typeColor, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: hasMessage ? 12 : 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  color: typeColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasMessage
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message!,
                              style: const TextStyle(
                                color: AppColors.snackbarSubtitle,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (onUndo != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onUndo();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'UNDO',
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _getTypeColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppColors.snackbarSuccess;
      case SnackbarType.error:
        return AppColors.snackbarError;
      case SnackbarType.warning:
        return AppColors.snackbarWarning;
      case SnackbarType.info:
        return AppColors.snackbarInfo;
    }
  }

  static IconData _getIconData(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_outline_rounded;
      case SnackbarType.warning:
        return Icons.warning_amber_rounded;
      case SnackbarType.info:
        return Icons.info_outline_rounded;
    }
  }
}
