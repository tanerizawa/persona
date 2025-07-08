import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_service.dart';

/// Service to handle push notifications using Firebase Cloud Messaging
@singleton
class PushNotificationService {
  final BackendApiService _backendApi;
  final FlutterLocalNotificationsPlugin _localNotifications;
  late FirebaseMessaging _firebaseMessaging;
  
  bool _isInitialized = false;
  String? _fcmToken;

  PushNotificationService(this._backendApi)
      : _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize Firebase and notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase (if not already initialized)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestPermissions();

      // Setup FCM token handling
      await _setupFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ Push notification service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize push notification service: $e');
      // Don't throw - allow app to continue without push notifications
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for different types of notifications
  Future<void> _createNotificationChannels() async {
    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
    );

    const reminderChannel = AndroidNotificationChannel(
      'reminders',
      'Reminders',
      description: 'Mood tracking and journal reminders',
      importance: Importance.defaultImportance,
    );

    const systemChannel = AndroidNotificationChannel(
      'system',
      'System Notifications',
      description: 'System updates and alerts',
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Setup FCM token handling
  Future<void> _setupFCMToken() async {
    try {
      // Get initial token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
        await _saveTokenLocally(_fcmToken!);
      }

      // Listen for token updates
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        await _sendTokenToBackend(token);
        await _saveTokenLocally(token);
      });
    } catch (e) {
      print('Error setting up FCM token: $e');
    }
  }

  /// Send FCM token to backend for push notification targeting
  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _backendApi.registerDeviceToken(token);
      print('✅ FCM token registered with backend');
    } catch (e) {
      print('❌ Failed to register FCM token with backend: $e');
    }
  }

  /// Save token locally for debugging/reference
  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification taps when app is terminated
    _handleInitialMessage();
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap when app was in background
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    _processNotificationData(message.data);
  }

  /// Handle notification tap when app was terminated
  Future<void> _handleInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      print('App opened from notification: ${message.messageId}');
      _processNotificationData(message.data);
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Determine notification channel based on message data
    AndroidNotificationDetails androidDetails;
    
    if (message.data['type'] == 'chat_message') {
      androidDetails = const AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        importance: Importance.high,
        priority: Priority.high,
      );
    } else if (message.data['type'] == 'reminder') {
      androidDetails = const AndroidNotificationDetails(
        'reminders',
        'Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'system',
        'System Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
    }

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _processNotificationData(data);
    }
  }

  /// Process notification data and navigate accordingly
  void _processNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final route = data['route'] as String?;

    print('Processing notification: type=$type, route=$route');

    // TODO: Implement navigation based on notification type
    // This could be handled by injecting a navigation service
    // or using a callback system
  }

  /// Schedule local reminder notifications
  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // For now, just show immediate notification
    // TODO: Implement proper timezone-based scheduling
    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  Future<void> dispose() async {
    // FCM streams are automatically disposed
    _isInitialized = false;
  }
}

/// Extension to add device token registration to BackendApiService
extension PushNotificationAPI on BackendApiService {
  Future<void> registerDeviceToken(String token) async {
    try {
      final response = await dio.post(
        '/api/notifications/register-device',
        data: {
          'fcmToken': token,
          'platform': 'flutter',
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to register device token: $e');
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final response = await dio.delete('/api/notifications/unregister-device');
      return response.data;
    } catch (e) {
      throw Exception('Failed to unregister device token: $e');
    }
  }
}
