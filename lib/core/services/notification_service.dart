import 'dart:async';
import 'package:car_sync/core/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StorageService _storageService = StorageService();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  Future<void> initialize() async {
    await _requestPermission();
    await _setupForegroundHandlers();
    await _saveCurrentUserToken();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _setupForegroundHandlers() async {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground notification received: ${message.messageId}');
    });

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('Notification opened app: ${message.messageId}');
    });
  }

  Future<void> _saveCurrentUserToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('FCM: no logged in user');
        return;
      }

      final token = await _messaging.getToken();
      debugPrint('FCM token generated: $token');

      if (token == null || token.isEmpty) {
        debugPrint('FCM: token is null or empty');
        return;
      }

      final userData = await _storageService.getUserData(user.uid);
      final role = (userData?['role'] ?? 'customer').toString();

      if (role == 'admin') {
        await _messaging.subscribeToTopic('admin');
        debugPrint('Subscribed to admin topic');
      } else {
        await _messaging.unsubscribeFromTopic('admin');
        debugPrint('Unsubscribed from admin topic');
      }

      await _storageService.saveUserDeviceToken(
        uid: user.uid,
        role: role,
        token: token,
      );

      debugPrint('FCM token saved for user: ${user.uid}');

      _messaging.onTokenRefresh.listen((newToken) async {
        await _storageService.saveUserDeviceToken(
          uid: user.uid,
          role: role,
          token: newToken,
        );
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Stream<int> unreadNotificationCountStream({
    required String role,
    required String currentUserId,
  }) {
    return _storageService.getUnreadNotificationCountByRole(
      role: role,
      currentUserId: currentUserId,
    );
  }

  Stream<int> unreadBookingNotificationCountStream({
    required String role,
    required String currentUserId,
  }) {
    return _storageService.getUnreadBookingNotificationCountByRole(
      role: role,
      currentUserId: currentUserId,
    );
  }

  Stream<List<Map<String, dynamic>>> notificationsStream({
    required String role,
  }) {
    return _storageService.getNotificationsByRoleStream(role);
  }

  /// Get notifications stream for a specific user (customer)
  Stream<List<Map<String, dynamic>>> userNotificationsStream({
    required String userId,
  }) {
    return _storageService.getNotificationsByUserIdStream(userId);
  }

  /// Get unread notification count for a specific user (customer)
  Stream<int> unreadUserNotificationCountStream({required String userId}) {
    return _storageService.getUnreadNotificationCountByUserId(userId);
  }

  /// Mark all user-specific notifications as read
  Future<void> markAllUserNotificationsAsRead({required String userId}) async {
    await _storageService.markAllUserNotificationsAsRead(userId: userId);
  }

  Future<void> markNotificationAsReadForUser({
    required String notificationId,
    required String userId,
  }) async {
    await _storageService.markNotificationAsReadForUser(
      notificationId: notificationId,
      userId: userId,
    );
  }

  Future<void> markAllRoleNotificationsAsReadForUser({
    required String role,
    required String userId,
  }) async {
    await _storageService.markAllRoleNotificationsAsReadForUser(
      role: role,
      userId: userId,
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notification received: ${message.messageId}');
}
