import 'package:flutter/material.dart';
import '../../shared/widgets/error_handler.dart';

/// A utility class to show consistent and beautiful snackbars/toasts throughout the app.
class MessageHelper {
  /// Shows a success snackbar with a green background.
  static void showSuccess(BuildContext context, String message) {
    ErrorHandler.showSuccessSnackBar(context, message);
  }

  /// Shows an error snackbar with a red background.
  /// Uses ErrorHandler to format the message and log to console.
  static void showError(BuildContext context, dynamic errorOrMessage) {
    ErrorHandler.showErrorSnackBar(context, errorOrMessage);
  }

  /// Shows a warning snackbar with an orange background.
  static void showWarning(BuildContext context, String message) {
    ErrorHandler.showWarningSnackBar(context, message);
  }
}
