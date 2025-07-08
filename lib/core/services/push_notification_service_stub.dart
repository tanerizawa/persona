import 'package:injectable/injectable.dart';

import 'backend_api_service.dart';

/// Stub implementation of PushNotificationService when feature is disabled
@singleton
class PushNotificationServiceStub {
  PushNotificationServiceStub(BackendApiService backendApi);

  /// Stub method - does nothing when push notifications are disabled
  Future<void> initialize() async {
    // No-op implementation
  }

  /// Stub method - always returns false
  bool get isInitialized => false;

  /// Stub method - returns null
  String? get fcmToken => null;

  /// Stub method - does nothing
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // No-op implementation
  }

  /// Stub method - does nothing
  Future<void> subscribeTopic(String topic) async {
    // No-op implementation
  }

  /// Stub method - does nothing
  Future<void> unsubscribeTopic(String topic) async {
    // No-op implementation
  }
}
