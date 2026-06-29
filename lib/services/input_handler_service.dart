/// input_handler_service.dart
/// Centralized keyboard input handling for Retail Analytics Engine.
/// Wraps text input events (submit-on-Enter, live search) into a
/// class-based structure, with validation + logging hooks built in.
library;

import 'validator_service.dart';
import 'event_logger_service.dart';

class InputHandlerService {
  /// Handles login form submission triggered by keyboard (Enter key)
  /// or a submit button. Validates email + password before calling
  /// the provided [onValid] callback (e.g. your actual login logic).
  static void handleLoginSubmit({
    required String email,
    required String password,
    required void Function() onValid,
    required void Function(Map<String, String> errors) onInvalid,
  }) {
    final errors = <String, String>{};

    final emailError = ValidatorService.validateEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = ValidatorService.validatePassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    if (errors.isNotEmpty) {
      EventLoggerService.logValidationEvent(
        'Login submit blocked — errors: $errors',
      );
      onInvalid(errors);
      return;
    }

    EventLoggerService.logKeyboardEvent(
      'Login submitted via keyboard for $email',
    );
    onValid();
  }

  /// Handles register form submission. Same pattern as login,
  /// but also checks password match.
  static void handleRegisterSubmit({
    required String email,
    required String password,
    required String confirmPassword,
    required void Function() onValid,
    required void Function(Map<String, String> errors) onInvalid,
  }) {
    final errors = <String, String>{};

    final emailError = ValidatorService.validateEmail(email);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = ValidatorService.validatePassword(password);
    if (passwordError != null) errors['password'] = passwordError;

    final matchError = ValidatorService.validatePasswordMatch(
      password,
      confirmPassword,
    );
    if (matchError != null) errors['confirmPassword'] = matchError;

    if (errors.isNotEmpty) {
      EventLoggerService.logValidationEvent(
        'Register submit blocked — errors: $errors',
      );
      onInvalid(errors);
      return;
    }

    EventLoggerService.logKeyboardEvent(
      'Register submitted via keyboard for $email',
    );
    onValid();
  }

  /// Handles live search-as-you-type on the Catalog screen.
  /// Call this from the search TextField's onChanged callback.
  /// [onSearch] is your existing filter/search logic.
  static void handleCatalogSearchInput({
    required String query,
    required void Function(String query) onSearch,
  }) {
    EventLoggerService.logKeyboardEvent('Catalog search input: "$query"');
    onSearch(query);
  }

  /// Handles numeric keyboard input for Stock Entry form fields
  /// (price, quantity), validating as the user types or on submit.
  static void handleStockEntrySubmit({
    required String name,
    required String price,
    required String stock,
    required void Function() onValid,
    required void Function(Map<String, String> errors) onInvalid,
  }) {
    final errors = ValidatorService.validateStockEntry(
      name: name,
      price: price,
      stock: stock,
    );

    if (errors.isNotEmpty) {
      EventLoggerService.logValidationEvent(
        'Stock entry submit blocked — errors: $errors',
      );
      onInvalid(errors);
      return;
    }

    EventLoggerService.logKeyboardEvent(
      'Stock entry submitted via keyboard for product "$name"',
    );
    onValid();
  }
}
