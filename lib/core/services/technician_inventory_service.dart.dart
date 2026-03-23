import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TechnicianInventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uses the 'spareparts' collection to remain consistent with SparePartService
  CollectionReference get _partsCollection => _firestore.collection('spareparts');

  /// Real-time stream of inventory parts for the UI
  Stream<QuerySnapshot> getInventoryStream() {
    return _partsCollection.snapshots();
  }

  /// Search parts by name
  Future<List<Map<String, dynamic>>> searchParts(String query) async {
    try {
      final snapshot = await _partsCollection.get();
      final lowercaseQuery = query.toLowerCase();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((data) =>
              (data['part'] ?? '').toString().toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      debugPrint("Error searching parts: $e");
      return [];
    }
  }

  /// Update stock level when a technician uses a part
  Future<void> usePart(String partId, int quantityUsed) async {
    try {
      final doc = await _partsCollection.doc(partId).get();
      if (!doc.exists) throw Exception("Part not found");

      final currentStock = (doc.data() as Map<String, dynamic>)['stock'] ?? 0;
      final newStock = currentStock - quantityUsed;

      if (newStock < 0) throw Exception("Insufficient stock available");

      await _partsCollection.doc(partId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating part stock: $e");
      rethrow;
    }
  }
}