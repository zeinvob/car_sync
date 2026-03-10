import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:car_sync/core/services/notification_service.dart';

/// Service for workshop-related Firestore operations
class WorkshopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Get list of all workshops with booking counts
  Future<List<Map<String, dynamic>>> getWorkshopList({
    double? userLat,
    double? userLon,
  }) async {
    try {
      final workshopSnapshot = await _firestore.collection('workshops').get();
      final bookingSnapshot = await _firestore.collection('bookings').get();

      final bookings = bookingSnapshot.docs.map((doc) => doc.data()).toList();

      // Debug: Print raw workshop data
      for (var doc in workshopSnapshot.docs) {
        print('Workshop ${doc.id}: ${doc.data()}');
      }

      return workshopSnapshot.docs.map((doc) {
        final data = doc.data();
        final workshopId = doc.id;

        final activeBookingCount = bookings.where((booking) {
          final sameWorkshop = booking['workshopId'] == workshopId;
          final status = (booking['status'] ?? '').toString().toLowerCase();

          return sameWorkshop && status != 'completed' && status != 'cancelled';
        }).length;

        final completedBookingCount = bookings.where((booking) {
          final sameWorkshop = booking['workshopId'] == workshopId;
          final status = (booking['status'] ?? '').toString().toLowerCase();

          return sameWorkshop && status == 'completed';
        }).length;

        // Get workshop coordinates
        // Note: Handle both 'longitude' and 'longtitude' (common typo)
        final double? workshopLat = (data['latitude'] as num?)?.toDouble();
        final double? workshopLon =
            (data['longitude'] as num?)?.toDouble() ??
            (data['longtitude'] as num?)?.toDouble();

        // Calculate distance if user location is provided
        double? distance;
        if (userLat != null &&
            userLon != null &&
            workshopLat != null &&
            workshopLon != null) {
          distance = calculateDistance(
            userLat,
            userLon,
            workshopLat,
            workshopLon,
          );
        }

        return {
          'id': workshopId,
          'name': data['name'] ?? 'Workshop',
          'address': data['address'] ?? 'No address',
          'rating': data['rating'] ?? 0,
          'isActive': data['isActive'] ?? false,
          'imageUrl': data['imageUrl'] ?? '',
          'phone': (data['phone'] ?? '').toString(),
          'description': data['description'] ?? '',
          'openingHours': (data['openingHours'] ?? '9:00 AM - 6:00 PM')
              .toString(),
          'latitude': workshopLat,
          'longitude': workshopLon,
          'distance': distance,
          'bookingCount': activeBookingCount,
          'completedCount': completedBookingCount,
        };
      }).toList();
    } catch (e) {
      print('getWorkshopList error: $e');
      return [];
    }
  }

  ////// --------------------------------------------------------------------------  ADMIN WORKSHOP SERVICE
  /// Get all bookings for this workshop
  Future<List<Map<String, dynamic>>> getBookingsByWorkshop(
    String workshopId,
  ) async {
    final bookingSnapshot = await _firestore
        .collection('bookings')
        .where('workshopId', isEqualTo: workshopId)
        .get();

    List<Map<String, dynamic>> bookingsWithCustomer = [];

    for (final doc in bookingSnapshot.docs) {
      final data = doc.data();

      final customerId = (data['customerId'] ?? '').toString();
      final vehicleId = (data['vehicleId'] ?? '').toString();

      Map<String, dynamic> customerData = {};
      Map<String, dynamic> vehicleData = {};

      if (customerId.isNotEmpty) {
        final customerDoc = await _firestore
            .collection('users')
            .doc(customerId)
            .get();
        if (customerDoc.exists) {
          customerData = customerDoc.data() ?? {};
        }
      }

      if (vehicleId.isNotEmpty) {
        final vehicleDoc = await _firestore
            .collection('vehicles')
            .doc(vehicleId)
            .get();
        if (vehicleDoc.exists) {
          vehicleData = vehicleDoc.data() ?? {};
        }
      }

      final brand = (vehicleData['brand'] ?? '').toString();
      final model = (vehicleData['model'] ?? '').toString();
      final plateNumber = (vehicleData['plateNumber'] ?? '').toString();

      final vehicleFullDisplay = [
        if (brand.isNotEmpty) brand,
        if (model.isNotEmpty) model,
        if (plateNumber.isNotEmpty) '($plateNumber)',
      ].join(' ');

      bookingsWithCustomer.add({
        'id': doc.id,
        'customerId': customerId,
        'customerName':
            customerData['name'] ??
            customerData['fullName'] ??
            customerData['username'] ??
            'Unknown Customer',
        'customerPhone':
            customerData['phone'] ??
            customerData['contact'] ??
            customerData['phoneNumber'] ??
            'No contact',
        'customerEmail': customerData['email'] ?? 'No email',
        'serviceType': data['serviceType'] ?? '',
        'status': data['status'] ?? '',
        'workshopId': data['workshopId'] ?? '',
        'assignedTechnicianId': data['assignedTechnicianId'] ?? '',
        'bookingDate': data['bookingDate'],
        'vehicleId': vehicleId,
        'vehicleBrand': brand,
        'vehicleModel': model,
        'plateNumber': plateNumber,
        'vehicleDisplay': vehicleFullDisplay,
        'notes': data['notes'] ?? '',
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      });
    }

    return bookingsWithCustomer;
  }

  /// Update booking status and assigned technician
  Future<void> updateBookingStatusAndTechnician({
    required String bookingId,
    required String newStatus,
    String? technicianId,
  }) async {
    // Get booking details before updating
    final bookingDoc = await _firestore
        .collection('bookings')
        .doc(bookingId)
        .get();
    final bookingData = bookingDoc.data();

    // Update the booking
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': newStatus,
      'assignedTechnicianId':
          (technicianId != null && technicianId.trim().isNotEmpty)
          ? technicianId
          : '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notification to customer
    if (bookingData != null) {
      final customerId = bookingData['customerId']?.toString() ?? '';
      final workshopName =
          bookingData['workshopName']?.toString() ?? 'Workshop';

      // Get technician name if assigned
      String? technicianName;
      if (technicianId != null && technicianId.trim().isNotEmpty) {
        technicianName = await getTechnicianName(technicianId);
      }

      if (customerId.isNotEmpty) {
        await NotificationService.instance.createBookingStatusNotificationForCustomer(
          customerId: customerId,
          bookingId: bookingId,
          workshopName: workshopName,
          newStatus: newStatus,
          technicianName: technicianName,
        );
      }
    }
  }

  /// ADMIN WORKSHOP SERVICE
  /// Get technicians that belong to this workshop
  Future<List<Map<String, dynamic>>> getWorkshopTechnicians(
    String workshopId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .where('workshopId', isEqualTo: workshopId)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'name':
                (data['name'] ??
                        data['fullName'] ??
                        data['username'] ??
                        'Unknown Technician')
                    .toString(),
            'role': (data['role'] ?? '').toString(),
          };
        })
        .where((item) {
          final role = item['role'].toString().toLowerCase();
          return role == 'technician' ||
              role == 'mechanic' ||
              role == 'foreman';
        })
        .toList();
  }

  /// ADMIN WORKSHOP SERVICE
  /// Get technician display name
  Future<String?> getTechnicianName(String technicianId) async {
    if (technicianId.trim().isEmpty) return null;

    final doc = await _firestore.collection('users').doc(technicianId).get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};
    return (data['name'] ??
            data['fullName'] ??
            data['username'] ??
            'Technician')
        .toString();
  }

  /// ADMIN WORKSHOP SERVICE
  /// Stream chat messages for one booking
  Stream<QuerySnapshot> bookingMessagesStream(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// ADMIN WORKSHOP SERVICE
  /// Send workshop/admin message in booking chat
  Future<void> sendBookingMessage({
    required String bookingId,
    required String senderName,
    required String message,
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .add({
          'message': message,
          'senderName': senderName,
          'senderRole': 'workshop',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// -------------------------------------------------------------------------- ADMIN WORKSHOP SERVICE
}
