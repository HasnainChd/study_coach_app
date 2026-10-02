import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Centralized service for PostHog analytics capture with error safety.
class AnalyticsService {
  /// Captures an event in PostHog. Wrapped in try/catch to ensure failures
  /// never crash or block the application.
  static Future<void> capture(
    String eventName, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PostHog capture failed for $eventName: $e\n$stackTrace');
      }
    }
  }
}
