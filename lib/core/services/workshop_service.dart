import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for workshop-related Firestore operations
class WorkshopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get list of all workshops with booking counts
  Future<List<Map<String, dynamic>>> getWorkshopList() async {
    try {
      final workshopSnapshot = await _firestore.collection('workshops').get();
      final bookingSnapshot = await _firestore.collection('bookings').get();

      final bookings = bookingSnapshot.docs.map((doc) => doc.data()).toList();

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

        return {
          'id': workshopId,
          'name': data['name'] ?? 'Workshop',
          'address': data['address'] ?? 'No address',
          'rating': data['rating'] ?? 0,
          'isActive': data['isActive'] ?? false,
          'bookingCount': activeBookingCount,
          'completedCount': completedBookingCount,
        };
      }).toList();
    } catch (e) {
      print('getWorkshopList error: $e');
      return [];
    }
  }
}
