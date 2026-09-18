import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';

class ErrorHandler {
  /// Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred.';
    }
    if (error is String) {
      return error;
    }
    if (error is AppException) {
      return error.message;
    }
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Exception) {
      return _handleGenericException(error);
    } else {
      return error.toString();
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
          return responseData['message'].toString();
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
      return message.replaceFirst(RegExp(r'^Exception:\s*'), '');
    }
  }

  /// Show user-friendly error message floating above bottom sheets & modals
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    HapticFeedback.lightImpact();
    final message = getUserFriendlyMessage(error);
    logger.e('ErrorHandler: $message', error: error);

    unawaited(
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red.shade800,
        textColor: Colors.white,
        fontSize: 14.0,
      ),
    );
  }

  /// Show success message floating above bottom sheets & modals
  static void showSuccessSnackBar(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    unawaited(
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.green.shade700,
        textColor: Colors.white,
        fontSize: 14.0,
      ),
    );
  }

  /// Show info message floating above bottom sheets & modals
  static void showInfoSnackBar(BuildContext context, String message) {
    unawaited(
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.blue.shade700,
        textColor: Colors.white,
        fontSize: 14.0,
      ),
    );
  }

  /// Show warning message floating above bottom sheets & modals
  static void showWarningSnackBar(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    unawaited(
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.orange.shade900,
        textColor: Colors.white,
        fontSize: 14.0,
      ),
    );
  }

  /// Check if error indicates network connectivity issues
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) return true;
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
    if (error is AuthException) return true;
    if (error is DioException && error.response?.statusCode == 401) {
      return true;
    }
    return false;
  }
}
