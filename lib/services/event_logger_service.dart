/// event_logger_service.dart
/// Centralized event logging for Retail Analytics Engine.
/// Records keyboard input, gestures, validation failures, and other
/// user interactions, with timestamps, for debugging and demo evidence.
library;

class AppEvent {
  final String type; // e.g. "KEYBOARD", "GESTURE", "VALIDATION", "LOGIN"
  final String details; // human-readable description
  final DateTime timestamp;

  AppEvent({required this.type, required this.details, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final t = timestamp.toIso8601String();
    return '[$t] $type: $details';
  }
}

class EventLoggerService {
  // In-memory log store. Could later be persisted via DatabaseHelper
  // if you want logs to survive app restarts.
  static final List<AppEvent> _events = [];

  /// Logs a new event. Call this from anywhere in the app.
  static void log(String type, String details) {
    final event = AppEvent(type: type, details: details);
    _events.add(event);

    // Also print to console for live debugging during development/demo.
    // ignore: avoid_print
    print(event.toString());
  }

  /// Convenience wrappers for common event types used across the app.
  static void logKeyboardEvent(String details) => log('KEYBOARD', details);
  static void logGestureEvent(String details) => log('GESTURE', details);
  static void logValidationEvent(String details) => log('VALIDATION', details);
  static void logLoginEvent(String details) => log('LOGIN', details);
  static void logSaleEvent(String details) => log('SALE', details);

  /// Returns all logged events, most recent first.
  static List<AppEvent> getEvents() {
    return _events.reversed.toList();
  }

  /// Returns only events of a given type, most recent first.
  static List<AppEvent> getEventsByType(String type) {
    return _events.where((e) => e.type == type).toList().reversed.toList();
  }

  /// Clears all stored events (useful for resetting between demo runs).
  static void clearEvents() {
    _events.clear();
  }
}
