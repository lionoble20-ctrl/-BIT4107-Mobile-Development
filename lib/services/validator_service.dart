/// validator_service.dart
/// Centralized input validation for Retail Analytics Engine.
/// Used across Auth, Register, and Inventory screens.
library;

class ValidatorService {
  /// Validates an email address format.
  /// Returns null if valid, or an error message string if invalid.
  static String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password strength.
  /// Requires at least 6 characters for this app's purposes.
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that two password fields match (used on Register screen).
  static String? validatePasswordMatch(String password, String confirm) {
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a product name field (used on Inventory/Stock Entry form).
  static String? validateProductName(String name) {
    if (name.trim().isEmpty) {
      return 'Product name cannot be empty';
    }
    if (name.trim().length < 2) {
      return 'Product name is too short';
    }
    return null;
  }

  /// Validates price input — must be a positive number.
  static String? validatePrice(String value) {
    if (value.trim().isEmpty) {
      return 'Price cannot be empty';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Price must be greater than zero';
    }
    return null;
  }

  /// Validates stock quantity input — must be a non-negative integer.
  static String? validateStockQuantity(String value) {
    if (value.trim().isEmpty) {
      return 'Stock quantity cannot be empty';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid whole number';
    }
    if (parsed < 0) {
      return 'Stock quantity cannot be negative';
    }
    return null;
  }

  /// Runs full validation for a Stock Entry form submission.
  /// Returns a map of field -> error message for any invalid fields.
  /// Empty map means all fields are valid.
  static Map<String, String> validateStockEntry({
    required String name,
    required String price,
    required String stock,
  }) {
    final errors = <String, String>{};

    final nameError = validateProductName(name);
    if (nameError != null) errors['name'] = nameError;

    final priceError = validatePrice(price);
    if (priceError != null) errors['price'] = priceError;

    final stockError = validateStockQuantity(stock);
    if (stockError != null) errors['stock'] = stockError;

    return errors;
  }
}
