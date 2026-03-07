import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service for admin-related Firestore operations
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Create foreman account (admin only)
  Future<void> createForemanAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String createdBy,
    List<String> assignedSites = const [],
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'role': 'foreman',
        'createdBy': createdBy,
        'assignedSites': assignedSites,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Foreman account created for UID: $uid");
    } catch (e) {
      print("Error creating foreman: $e");
      rethrow;
    }
  }

  /// Get all foremen (admin only)
  Future<List<Map<String, dynamic>>> getAllForemen() async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .where('role', isEqualTo: 'foreman')
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Error getting foremen: $e");
      return [];
    }
  }

  /// Update foreman assigned sites
  Future<void> updateForemanSites({
    required String uid,
    required List<String> assignedSites,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'assignedSites': assignedSites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Foreman sites updated for UID: $uid");
    } catch (e) {
      print("Error updating foreman sites: $e");
      rethrow;
    }
  }

  /// Get admin dashboard data
  Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // 1) Today's bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where(
            'bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'bookingDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      // 2) Services
      final servicesSnapshot = await _firestore.collection('services').get();

      // 3) Towing
      final towingSnapshot = await _firestore
          .collection('towing_requests')
          .where('status', isEqualTo: 'active')
          .get();

      // 4) Spareparts low stock
      final lowStockSnapshot = await _firestore
          .collection('spareparts')
          .where('stock', isLessThanOrEqualTo: 5)
          .get();

      // 5) Revenue from invoices
      final invoicesSnapshot = await _firestore
          .collection('invoices')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // 6) Recent activities
      final activitySnapshot = await _firestore
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final bookings = bookingsSnapshot.docs.map((d) => d.data()).toList();
      final services = servicesSnapshot.docs.map((d) => d.data()).toList();

      // Cars In Service
      final carsInService = services.where((s) {
        final status = (s['status'] ?? '').toString();
        return status == 'Diagnosing' ||
            status == 'Diagnosis' ||
            status == 'Repairing' ||
            status == 'In Progress';
      }).length;

      // Completed
      final completedServices = services.where((s) {
        final status = (s['status'] ?? '').toString();
        return status == 'Completed';
      }).length;

      // Revenue sum
      double todayRevenue = 0;
      for (final doc in invoicesSnapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount is int) todayRevenue += amount.toDouble();
        if (amount is double) todayRevenue += amount;
      }

      // Appointments list
      final appointments = bookings.map((b) {
        final date = (b['bookingDate'] is Timestamp)
            ? (b['bookingDate'] as Timestamp).toDate()
            : null;

        return {
          'time': date != null ? DateFormat('hh:mm a').format(date) : '--:--',
          'customerName': b['customerName'] ?? 'Unknown',
          'carPlate': b['carPlate'] ?? '-',
          'serviceType': b['serviceType'] ?? '-',
          'status': b['status'] ?? '-',
        };
      }).toList();

      // Status overview
      final statusOverview = {
        'Booked': services.where((s) => (s['status'] ?? '') == 'Booked').length,
        'Diagnosing': services
            .where((s) => (s['status'] ?? '') == 'Diagnosing')
            .length,
        'Repairing': services
            .where((s) => (s['status'] ?? '') == 'Repairing')
            .length,
        'Ready for Pickup': services
            .where((s) => (s['status'] ?? '') == 'Ready for Pickup')
            .length,
      };

      // Alerts
      final alerts = <String>[];

      for (final doc in lowStockSnapshot.docs) {
        final item = doc.data();
        alerts.add("Low stock: ${item['part'] ?? 'Unknown Part'}");
      }

      for (final b in bookings) {
        final foremanId = (b['foremanId'] ?? '').toString();
        final status = (b['status'] ?? '').toString();
        final paymentStatus = (b['paymentStatus'] ?? '').toString();
        final carPlate = (b['carPlate'] ?? 'vehicle').toString();

        if (foremanId.isEmpty) alerts.add("Unassigned job: $carPlate");
        if (status == 'Ready for Pickup') {
          alerts.add("Customer waiting for pickup: $carPlate");
        }
        if (paymentStatus == 'Pending') {
          alerts.add("Pending payment: $carPlate");
        }
      }

      final recentActivities = activitySnapshot.docs
          .map((d) => (d.data()['message'] ?? '').toString())
          .where((m) => m.isNotEmpty)
          .toList();

      return {
        'todayBookings': bookings.length,
        'carsInService': carsInService,
        'completedServices': completedServices,
        'activeTowingRequests': towingSnapshot.docs.length,
        'todayRevenue': todayRevenue,
        'lowStockItems': lowStockSnapshot.docs.length,
        'appointments': appointments,
        'statusOverview': statusOverview,
        'alerts': alerts,
        'recentActivities': recentActivities,
      };
    } catch (e) {
      print("getAdminDashboardData error: $e");
      return {
        'todayBookings': 0,
        'carsInService': 0,
        'completedServices': 0,
        'activeTowingRequests': 0,
        'todayRevenue': 0.0,
        'lowStockItems': 0,
        'appointments': <Map<String, dynamic>>[],
        'statusOverview': <String, int>{},
        'alerts': <String>[],
        'recentActivities': <String>[],
      };
    }
  }
}
