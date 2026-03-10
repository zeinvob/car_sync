import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for spare parts-related Firestore operations
class SparePartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all spare parts
  Future<List<Map<String, dynamic>>> getAllSpareParts() async {
    try {
      final snapshot = await _firestore.collection('spareparts').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'part': data['part'] ?? '',
          'car_model': data['car_model'] ?? '',
          'description': data['description'] ?? '',
          'price': data['price'] ?? 0,
          'stock': data['stock'] ?? 0,
          'type': data['type'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      print("getAllSpareParts error: $e");
      return [];
    }
  }

  /// Update spare part stock
  Future<void> updateSparePartStock({
    required String docId,
    required int newStock,
  }) async {
    try {
      await _firestore.collection('spareparts').doc(docId).update({
        'stock': newStock,
      });
    } catch (e) {
      print("updateSparePartStock error: $e");
    }
  }

  /// Get recent spare parts (limited)
  Future<List<Map<String, dynamic>>> getRecentSpareParts() async {
    try {
      final snapshot = await _firestore
          .collection('spareparts')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'part': data['part'] ?? '',
          'car_model': data['car_model'] ?? '',
          'description': data['description'] ?? '',
          'price': data['price'] ?? 0,
          'stock': data['stock'] ?? 0,
          'type': data['type'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('getRecentSpareParts error: $e');
      return [];
    }
  }
}
