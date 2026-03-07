import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Import individual services
import 'user_service.dart';
import 'admin_service.dart';
import 'booking_service.dart';
import 'vehicle_service.dart';
import 'workshop_service.dart';
import 'sparepart_service.dart';
import 'review_service.dart';

/// StorageService - Facade that delegates to individual services
/// This keeps backward compatibility while using separate service implementations
class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Individual service instances
  final UserService _userService = UserService();
  final AdminService _adminService = AdminService();
  final BookingService _bookingService = BookingService();
  final VehicleService _vehicleService = VehicleService();
  final WorkshopService _workshopService = WorkshopService();
  final SparePartService _sparePartService = SparePartService();
  final ReviewService _reviewService = ReviewService();

  // Collection references for notification methods
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // ======================== USER METHODS ========================
  // Delegated to UserService

  Future<bool> userExists(String uid) => _userService.userExists(uid);

  Future<void> saveGoogleUserData({
    required String uid,
    required String email,
    required String fullName,
  }) => _userService.saveGoogleUserData(
    uid: uid,
    email: email,
    fullName: fullName,
  );

  Future<bool> needsProfileCompletion(String uid) =>
      _userService.needsProfileCompletion(uid);

  Future<void> completeUserProfile({
    required String uid,
    required String phone,
    required DateTime dateOfBirth,
  }) => _userService.completeUserProfile(
    uid: uid,
    phone: phone,
    dateOfBirth: dateOfBirth,
  );

  Future<void> saveCustomerData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) => _userService.saveCustomerData(
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
    emailVerified: emailVerified,
  );

  Future<void> saveUserData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) => _userService.saveUserData(
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
    emailVerified: emailVerified,
  );

  Future<String?> getUserRole(String uid) => _userService.getUserRole(uid);

  Future<Map<String, dynamic>?> getUserData(String uid) =>
      _userService.getUserData(uid);

  Future<void> updateUserData({
    required String uid,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
  }) => _userService.updateUserData(
    uid: uid,
    fullName: fullName,
    phone: phone,
    dateOfBirth: dateOfBirth,
  );

  Future<void> updateEmailVerified(String uid, bool verified) =>
      _userService.updateEmailVerified(uid, verified);

  // ======================== ADMIN METHODS ========================
  // Delegated to AdminService

  Future<void> createForemanAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String createdBy,
    List<String> assignedSites = const [],
  }) => _adminService.createForemanAccount(
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    createdBy: createdBy,
    assignedSites: assignedSites,
  );

  Future<List<Map<String, dynamic>>> getAllForemen() =>
      _adminService.getAllForemen();

  Future<void> updateForemanSites({
    required String uid,
    required List<String> assignedSites,
  }) =>
      _adminService.updateForemanSites(uid: uid, assignedSites: assignedSites);

  Future<Map<String, dynamic>> getAdminDashboardData() =>
      _adminService.getAdminDashboardData();

  // ======================== BOOKING METHODS ========================
  // Delegated to BookingService

  Future<List<TimeOfDay>> getAvailableSlots({
    required String workshopId,
    required DateTime date,
  }) => _bookingService.getAvailableSlots(workshopId: workshopId, date: date);

  Future<String> createBooking({
    required String customerId,
    required String workshopId,
    required String serviceType,
    required DateTime bookingDate,
    String? notes,
    String? vehicleId,
  }) async {
    final bookingId = await _bookingService.createBooking(
      customerId: customerId,
      workshopId: workshopId,
      serviceType: serviceType,
      bookingDate: bookingDate,
      notes: notes,
      vehicleId: vehicleId,
    );

    try {
      // Load workshop info
      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();
      final workshopData = workshopDoc.data() ?? {};
      final workshopName = (workshopData['name'] ?? 'Workshop').toString();

      // Load customer info
      final customerDoc = await _firestore
          .collection('users')
          .doc(customerId)
          .get();
      final customerData = customerDoc.data() ?? {};
      final customerName =
          (customerData['name'] ??
                  customerData['fullName'] ??
                  customerData['username'] ??
                  'Customer')
              .toString();

      // Notify admins
      await createNewBookingNotificationForAdmins(
        bookingId: bookingId,
        workshopId: workshopId,
        workshopName: workshopName,
        customerName: customerName,
      );

      // Optional: notify workshops too
      await createNewBookingNotificationForWorkshops(
        bookingId: bookingId,
        workshopId: workshopId,
        customerName: customerName,
      );
    } catch (e) {
      debugPrint('Booking created but notification failed: $e');
    }

    return bookingId;
  }

  Future<List<Map<String, dynamic>>> getCustomerBookings(String customerId) =>
      _bookingService.getCustomerBookings(customerId);

  Future<List<Map<String, dynamic>>> getBookingsByWorkshop(String workshopId) =>
      _bookingService.getBookingsByWorkshop(workshopId);

  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) => _bookingService.updateBookingStatus(
    bookingId: bookingId,
    newStatus: newStatus,
  );

  Stream<int> getActiveBookingsCountStream() =>
      _bookingService.getActiveBookingsCountStream();

  // ======================== VEHICLE METHODS ========================
  // Delegated to VehicleService

  Future<String> addVehicle({
    required String customerId,
    required String brand,
    required String model,
    required String year,
    required String plateNumber,
    String? color,
    String? transmission,
    String? fuelType,
    String? notes,
  }) => _vehicleService.addVehicle(
    customerId: customerId,
    brand: brand,
    model: model,
    year: year,
    plateNumber: plateNumber,
    color: color,
    transmission: transmission,
    fuelType: fuelType,
    notes: notes,
  );

  Future<List<Map<String, dynamic>>> getCustomerVehicles(String customerId) =>
      _vehicleService.getCustomerVehicles(customerId);

  Future<void> updateVehicle({
    required String vehicleId,
    required Map<String, dynamic> data,
  }) => _vehicleService.updateVehicle(vehicleId: vehicleId, data: data);

  Future<void> deleteVehicle(String vehicleId) =>
      _vehicleService.deleteVehicle(vehicleId);

  // ======================== WORKSHOP METHODS ========================
  // Delegated to WorkshopService

  Future<List<Map<String, dynamic>>> getWorkshopList({
    double? userLat,
    double? userLon,
  }) => _workshopService.getWorkshopList(userLat: userLat, userLon: userLon);

  // ======================== SPARE PARTS METHODS ========================
  // Delegated to SparePartService

  Future<List<Map<String, dynamic>>> getAllSpareParts() =>
      _sparePartService.getAllSpareParts();

  Future<void> updateSparePartStock({
    required String docId,
    required int newStock,
  }) =>
      _sparePartService.updateSparePartStock(docId: docId, newStock: newStock);

  Future<List<Map<String, dynamic>>> getRecentSpareParts() =>
      _sparePartService.getRecentSpareParts();

  // ======================== REVIEW METHODS ========================
  // Delegated to ReviewService

  Future<List<Map<String, dynamic>>> getWorkshopReviews(String workshopId) =>
      _reviewService.getWorkshopReviews(workshopId);

  Future<void> addReview({
    required String workshopId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) => _reviewService.addReview(
    workshopId: workshopId,
    userId: userId,
    userName: userName,
    rating: rating,
    comment: comment,
  );

  Future<bool> canUserReview({
    required String workshopId,
    required String userId,
  }) => _reviewService.canUserReview(workshopId: workshopId, userId: userId);

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) =>
      _reviewService.getUserReviews(userId);

  // ======================== NOTIFICATION METHODS ========================
  // These stay in StorageService as they are used by NotificationService

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

  Future<void> createNotification({
    required String targetRole,
    required String type,
    required String title,
    required String body,
    String? relatedBookingId,
    String? relatedWorkshopId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _notificationsCollection.add({
        'targetRole': targetRole,
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

  Stream<List<Map<String, dynamic>>> getNotificationsByRoleStream(String role) {
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

  Stream<int> getUnreadNotificationCountByRole({
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

  Stream<int> getUnreadBookingNotificationCountByRole({
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
}
