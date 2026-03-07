import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for review-related Firestore operations
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reviews for a specific workshop
  Future<List<Map<String, dynamic>>> getWorkshopReviews(String workshopId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('workshopId', isEqualTo: workshopId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'workshopId': data['workshopId'] ?? '',
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Anonymous',
          'rating': data['rating'] ?? 5,
          'comment': data['comment'] ?? '',
          'createdAt': data['createdAt'],
          'bookingId': data['bookingId'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('getWorkshopReviews error: $e');
      return [];
    }
  }

  /// Add a new review
  Future<bool> addReview({
    required String workshopId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String? bookingId,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'workshopId': workshopId,
        'userId': userId,
        'userName': userName,
        'rating': rating.toInt(),
        'comment': comment,
        'bookingId': bookingId ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update workshop average rating
      await _updateWorkshopRating(workshopId);

      return true;
    } catch (e) {
      print('addReview error: $e');
      return false;
    }
  }

  /// Check if user can review this workshop (has completed booking)
  Future<bool> canUserReview({
    required String workshopId,
    required String userId,
  }) async {
    try {
      // Check if user has a completed booking at this workshop
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('workshopId', isEqualTo: workshopId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (bookingsSnapshot.docs.isEmpty) return false;

      // Check if user already reviewed this workshop
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('workshopId', isEqualTo: workshopId)
          .get();

      // User can review if they have completed bookings and haven't reviewed yet
      return reviewsSnapshot.docs.isEmpty;
    } catch (e) {
      print('canUserReview error: $e');
      return false;
    }
  }

  /// Get all reviews by a user
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('getUserReviews error: $e');
      return [];
    }
  }

  /// Check if user already reviewed this booking
  Future<bool> hasReviewedBooking(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('hasReviewedBooking error: $e');
      return false;
    }
  }

  /// Update workshop average rating based on all reviews
  Future<void> _updateWorkshopRating(String workshopId) async {
    try {
      final reviews = await getWorkshopReviews(workshopId);
      
      if (reviews.isEmpty) return;

      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + (review['rating'] as int),
      );
      final averageRating = totalRating / reviews.length;

      await _firestore.collection('workshops').doc(workshopId).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
      });
    } catch (e) {
      print('_updateWorkshopRating error: $e');
    }
  }
}
