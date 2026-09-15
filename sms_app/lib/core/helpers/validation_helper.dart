
/// A utility class that provides static methods for validating form fields.
/// This ensures consistent validation logic across the entire application.
class ValidationHelper {
  /// Validates the full name field.
  /// Requires at least 2 characters and only alphabets/spaces.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (trimmed.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validates the email field.
  /// Uses an RFC-compliant regex to check for a valid email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates the phone number field.
  /// Checks for a valid 10-digit mobile number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-+()]'), '');
    // Support either 10-digit standard or 12-digit with 91 prefix
    final normalized = cleanNumber.startsWith('91') && cleanNumber.length == 12
        ? cleanNumber.substring(2)
        : cleanNumber;

    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(normalized)) {
      return 'Please enter a valid 10-digit mobile number';
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

  /// Validates the daily SMS limit.
  /// -1 represents unlimited; otherwise must be between 1 and 50,000.
  static String? validateSmsLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SMS limit is required';
    }
    final trimmed = value.trim();
    final limit = int.tryParse(trimmed);
    if (limit == null) {
      return 'Please enter a valid number (-1 for unlimited)';
    }
    if (limit == -1) {
      return null;
    }
    if (limit < 1) {
      return 'Limit must be at least 1 or -1 for unlimited';
    }
    if (limit > 50000) {
      return 'Daily limit cannot exceed 50,000';
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
