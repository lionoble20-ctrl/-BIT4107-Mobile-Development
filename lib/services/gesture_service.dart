/// gesture_service.dart
/// Centralized touch gesture handling for Retail Analytics Engine.
/// Wraps tap, long-press, and swipe interactions into a class-based
/// structure, with logging hooks built in, for use mainly on the
/// Catalog screen's product cards.
library;

import 'event_logger_service.dart';

class GestureService {
  /// Handles a single tap on a product card.
  /// Typically used to open product details or trigger "Simulate Sale".
  static void onProductTap({
    required String productName,
    required void Function() onAction,
  }) {
    EventLoggerService.logGestureEvent(
      'Tap detected on product "$productName"',
    );
    onAction();
  }

  /// Handles a long-press on a product card.
  /// Typically used to open a quick-view/edit dialog without
  /// navigating away from the Catalog screen.
  static void onProductLongPress({
    required String productName,
    required void Function() onAction,
  }) {
    EventLoggerService.logGestureEvent(
      'Long-press detected on product "$productName" — opening quick view',
    );
    onAction();
  }

  /// Handles a horizontal swipe on a product card (e.g. swipe-to-delete
  /// or swipe to mark out-of-stock).
  /// [direction] should be 'left' or 'right'.
  static void onProductSwipe({
    required String productName,
    required String direction,
    required void Function() onAction,
  }) {
    EventLoggerService.logGestureEvent(
      'Swipe ($direction) detected on product "$productName"',
    );
    onAction();
  }

  /// Handles a double-tap, e.g. as a quick "favorite" or "restock" shortcut.
  static void onProductDoubleTap({
    required String productName,
    required void Function() onAction,
  }) {
    EventLoggerService.logGestureEvent(
      'Double-tap detected on product "$productName"',
    );
    onAction();
  }
}
