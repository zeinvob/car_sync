import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_sync/core/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service for all notification-related operations
/// Handles both FCM (push notifications) and Firestore notification storage
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  // ======================== FCM INITIALIZATION ========================

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

      final userData = await _userService.getUserData(user.uid);
      final role = (userData?['role'] ?? 'customer').toString();

      if (role == 'admin') {
        await _messaging.subscribeToTopic('admin');
        debugPrint('Subscribed to admin topic');
      } else {
        await _messaging.unsubscribeFromTopic('admin');
        debugPrint('Unsubscribed from admin topic');
      }

      await saveUserDeviceToken(
        uid: user.uid,
        role: role,
        token: token,
      );

      debugPrint('FCM token saved for user: ${user.uid}');

      _messaging.onTokenRefresh.listen((newToken) async {
        await saveUserDeviceToken(
          uid: user.uid,
          role: role,
          token: newToken,
        );
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
  }

  // ======================== DEVICE TOKEN ========================

  Future<void> saveUserDeviceToken({
    required String uid,
    required String role,
    required String token,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'fcmToken': token,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user device token: $e');
    }
  }

  // ======================== CREATE NOTIFICATIONS ========================

  Future<void> createNotification({
    required String type,
    required String title,
    required String body,
    String? targetRole,
    String? targetUserId,
    String? relatedBookingId,
    String? relatedWorkshopId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _notificationsCollection.add({
        'targetRole': targetRole,
        'targetUserId': targetUserId,
        'type': type,
        'title': title,
        'body': body,
        'relatedBookingId': relatedBookingId,
        'relatedWorkshopId': relatedWorkshopId,
        'extraData': extraData ?? {},
        'isReadBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  Future<void> createNewBookingNotificationForAdmins({
    required String bookingId,
    required String workshopId,
    required String workshopName,
    required String customerName,
  }) async {
    await createNotification(
      targetRole: 'admin',
      type: 'new_booking',
      title: 'New Booking',
      body: '$customerName placed a new booking for $workshopName',
      relatedBookingId: bookingId,
      relatedWorkshopId: workshopId,
      extraData: {
        'bookingId': bookingId,
        'workshopId': workshopId,
        'workshopName': workshopName,
        'customerName': customerName,
      },
    );
  }

  Future<void> createNewBookingNotificationForWorkshops({
    required String bookingId,
    required String workshopId,
    required String customerName,
  }) async {
    await createNotification(
      targetRole: 'workshop',
      type: 'new_booking',
      title: 'New Booking',
      body: '$customerName placed a new booking',
      relatedBookingId: bookingId,
      relatedWorkshopId: workshopId,
      extraData: {'bookingId': bookingId, 'workshopId': workshopId},
    );
  }

  /// Create a notification for customer when booking status changes
  Future<void> createBookingStatusNotificationForCustomer({
    required String customerId,
    required String bookingId,
    required String workshopName,
    required String newStatus,
    String? technicianName,
  }) async {
    String title;
    String body;

    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        title = 'Booking Confirmed';
        body =
            'Your booking at $workshopName has been confirmed. Please arrive on your scheduled date.';
        break;
      case 'in_progress':
        title = 'Service In Progress';
        body =
            'Your vehicle is now being serviced at $workshopName.${technicianName != null ? ' Technician: $technicianName' : ''}';
        break;
      case 'completed':
        title = 'Service Completed';
        body =
            'Your vehicle service at $workshopName has been completed. Thank you for choosing us!';
        break;
      case 'cancelled':
        title = 'Booking Cancelled';
        body = 'Your booking at $workshopName has been cancelled.';
        break;
      default:
        title = 'Booking Update';
        body =
            'Your booking status at $workshopName has been updated to $newStatus.';
    }

    await createNotification(
      targetUserId: customerId,
      type: 'booking_status_update',
      title: title,
      body: body,
      relatedBookingId: bookingId,
      extraData: {
        'bookingId': bookingId,
        'workshopName': workshopName,
        'newStatus': newStatus,
        if (technicianName != null) 'technicianName': technicianName,
      },
    );
  }

  /// Create a notification for customer when technician adds a repair update
  Future<void> createRepairUpdateNotificationForCustomer({
    required String customerId,
    required String bookingId,
    required String workshopName,
    required String updateType,
    required String updateTitle,
  }) async {
    await createNotification(
      targetUserId: customerId,
      type: 'repair_update',
      title: 'Repair Update',
      body: '$updateTitle - $workshopName',
      relatedBookingId: bookingId,
      extraData: {
        'bookingId': bookingId,
        'workshopName': workshopName,
        'updateType': updateType,
        'updateTitle': updateTitle,
      },
    );
  }

  // ======================== READ NOTIFICATIONS ========================

  /// Get notifications stream for a specific user (customer)
  Stream<List<Map<String, dynamic>>> userNotificationsStream({
    required String userId,
  }) {
    // Note: This query requires a composite index on (targetUserId, createdAt)
    // If index is not ready, we fall back to client-side sorting
    return _notificationsCollection
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
          
          // Sort by createdAt on client side
          list.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending
          });
          
          return list;
        });
  }

  /// Get notifications stream by role (admin, workshop)
  Stream<List<Map<String, dynamic>>> notificationsStream({
    required String role,
  }) {
    return _notificationsCollection
        .where('targetRole', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  // ======================== UNREAD COUNTS ========================

  /// Get unread notification count for a specific user (customer)
  Stream<int> unreadUserNotificationCountStream({required String userId}) {
    return _notificationsCollection
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> isReadBy = data['isReadBy'] ?? [];
            if (!isReadBy.contains(userId)) {
              count++;
            }
          }
          return count;
        });
  }

  /// Get unread notification count by role
  Stream<int> unreadNotificationCountStream({
    required String role,
    required String currentUserId,
  }) {
    return _notificationsCollection
        .where('targetRole', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> isReadBy = data['isReadBy'] ?? [];
            if (!isReadBy.contains(currentUserId)) {
              count++;
            }
          }
          return count;
        });
  }

  /// Get unread booking notification count by role
  Stream<int> unreadBookingNotificationCountStream({
    required String role,
    required String currentUserId,
  }) {
    return _notificationsCollection
        .where('targetRole', isEqualTo: role)
        .where('type', isEqualTo: 'new_booking')
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> isReadBy = data['isReadBy'] ?? [];
            if (!isReadBy.contains(currentUserId)) {
              count++;
            }
          }
          return count;
        });
  }

  // ======================== MARK AS READ ========================

  Future<void> markNotificationAsReadForUser({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isReadBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking notification as read for user: $e');
    }
  }

  /// Mark all user-specific notifications as read
  Future<void> markAllUserNotificationsAsRead({required String userId}) async {
    try {
      final snapshot = await _notificationsCollection
          .where('targetUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isReadBy': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking user notifications as read: $e');
    }
  }

  Future<void> markAllRoleNotificationsAsReadForUser({
    required String role,
    required String userId,
  }) async {
    try {
      final snapshot = await _notificationsCollection
          .where('targetRole', isEqualTo: role)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isReadBy': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking role notifications as read: $e');
    }
  }

  // ======================== DELETE NOTIFICATIONS ========================

  /// Delete a single notification by ID
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      debugPrint('Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a specific user
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('targetUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Deleted ${snapshot.docs.length} notifications for user: $userId');
    } catch (e) {
      debugPrint('Error deleting user notifications: $e');
    }
  }

  /// Delete all read notifications for a specific user
  Future<void> deleteReadNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('targetUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final isReadBy = data?['isReadBy'] as List<dynamic>? ?? [];
        if (isReadBy.contains(userId)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      await batch.commit();
      debugPrint('Deleted $deletedCount read notifications for user: $userId');
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notification received: ${message.messageId}');
}
