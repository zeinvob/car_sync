import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_sync/features/admin/presentation/model/stock_item_model.dart';

class StockService {
  StockService._();
  static final StockService instance = StockService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _stocksCollection => _firestore.collection('stocks');

  Stream<List<StockItemModel>> getStocksStream() {
    return _stocksCollection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StockItemModel.fromMap(doc.id, data);
      }).toList();

      list.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }

  Future<void> addStockItem({
    required String carModel,
    required String description,
    required int discountPercent,
    required String imageUrl,
    required bool onSale,
    required double originalPrice,
    required String part,
    required double salePrice,
    required int stock,
    required String type,
  }) async {
    try {
      await _stocksCollection.add({
        'carModel': carModel,
        'description': description,
        'discountPercent': discountPercent,
        'imageUrl': imageUrl,
        'onSale': onSale,
        'originalPrice': originalPrice,
        'part': part,
        'salePrice': salePrice,
        'stock': stock,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding stock item: $e');
      rethrow;
    }
  }

  Future<void> updateStockItem({
    required String id,
    required String carModel,
    required String description,
    required int discountPercent,
    required String imageUrl,
    required bool onSale,
    required double originalPrice,
    required double salePrice,
    required String part,
    required int stock,
    required String type,
  }) async {
    try {
      await _stocksCollection.doc(id).update({
        'carModel': carModel,
        'description': description,
        'discountPercent': discountPercent,
        'imageUrl': imageUrl,
        'onSale': onSale,
        'originalPrice': originalPrice,
        'salePrice': salePrice,
        'part': part,
        'stock': stock,
        'type': type,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating stock item: $e');
      rethrow;
    }
  }

  Future<void> deleteStockItem(String id) async {
    try {
      await _stocksCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting stock item: $e');
      rethrow;
    }
  }
}