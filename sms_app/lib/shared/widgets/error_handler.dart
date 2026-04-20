import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  /// Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    if (error is String) {
      return error;
    }
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Exception) {
      return _handleGenericException(error);
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Handle Dio HTTP errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet connection.';

      case DioExceptionType.badResponse:
        // Try to get the error message from the response body first
        final responseData = error.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          return responseData['message'];
        }
        return _handleHttpStatusError(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.unknown:
      default:
        return 'Network error. Please try again.';
    }
  }

  /// Handle HTTP status code errors
  static String _handleHttpStatusError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested content was not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Handle generic exceptions
  static String _handleGenericException(Exception error) {
    final message = error.toString();

    // Check for common error patterns
    if (message.contains('SocketException') ||
        message.contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (message.contains('FormatException')) {
      return 'Invalid data format. Please try again.';
    } else if (message.contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Show user-friendly error message in a SnackBar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    // Log the error to console for debugging
    debugPrint('---------------- ERROR LOG ----------------');
    debugPrint('Error Type: ${error.runtimeType}');
    debugPrint('Error Details: $error');
    if (error is DioException) {
      debugPrint('Dio Error Type: ${error.type}');
      debugPrint('Dio Response: ${error.response}');
    }
    debugPrint('-------------------------------------------');
    
    final message = getUserFriendlyMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success message in a SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show info message in a SnackBar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show warning message in a SnackBar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Check if error indicates network connectivity issues
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
    }

    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection');
  }

  /// Check if error indicates authentication issues
  static bool isAuthError(dynamic error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return true;
    }
    return false;
  }
}
