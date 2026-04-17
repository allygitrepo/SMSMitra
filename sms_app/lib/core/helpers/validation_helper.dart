
/// A utility class that provides static methods for validating form fields.
/// This ensures consistent validation logic across the entire application.
class ValidationHelper {
  /// Validates the full name field.
  /// Requires at least 3 characters.
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters long';
    }
    return null;
  }

  /// Validates the email field.
  /// Uses a regex to check for a valid email format.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates the phone number field.
  /// Checks for a valid mobile length (assuming 10 digits for simplicity, can be adjusted).
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Basic validation for 10-digit number; adjust based on region if needed
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates the password field.
  /// Requires at least 6 characters.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  /// Validates the confirm password field.
  /// Ensures it matches the original password.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates that a field is not empty.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
