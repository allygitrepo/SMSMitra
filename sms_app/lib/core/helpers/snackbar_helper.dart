import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A utility class to show consistent and beautiful snackbars/toasts throughout the app.
class MessageHelper {
  /// Shows a success snackbar with a green background.
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.success,
      Icons.check_circle_outline,
    );
  }

  /// Shows an error snackbar with a red background.
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.error,
      Icons.error_outline,
    );
  }

  /// Shows a warning snackbar with an orange background.
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.orange,
      Icons.warning_amber_rounded,
    );
  }

  /// Internal method to build and show the SnackBar.
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
