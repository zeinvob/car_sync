import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;

/// Service for workshop-related Firestore operations
class WorkshopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
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
        final double? workshopLon = (data['longitude'] as num?)?.toDouble() ?? 
                                    (data['longtitude'] as num?)?.toDouble();
        
        // Calculate distance if user location is provided
        double? distance;
        if (userLat != null && userLon != null && workshopLat != null && workshopLon != null) {
          distance = calculateDistance(userLat, userLon, workshopLat, workshopLon);
        }

        return {
          'id': workshopId,
          'name': data['name'] ?? 'Workshop',
          'address': data['address'] ?? 'No address',
          'rating': data['rating'] ?? 0,
          'isActive': data['isActive'] ?? false,
          'imageUrl': data['imageUrl'] ?? '',
          'phone': data['phone'] ?? '',
          'email': data['email'] ?? '',
          'description': data['description'] ?? '',
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
}
