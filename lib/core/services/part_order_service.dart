import 'package:car_sync/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart' show debugPrint;

class PartOrderService {
  PartOrderService._();
  static final PartOrderService instance = PartOrderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersCollection =>
      _firestore.collection('part_orders');

  CollectionReference get _invoiceCollection =>
      _firestore.collection('invoice');

  CollectionReference get _sparePartsCollection =>
      _firestore.collection('spareparts');

  String _buildInvoiceNumber() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final stamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'INV-$y$m$d-$stamp';
  }

  Future<void> confirmOrderAndCreateInvoice({
  required String orderId,
  required Map<String, dynamic> orderData,
  bool reduceStock = false,
}) async {
  final orderRef = _ordersCollection.doc(orderId);
  final invoiceRef = _invoiceCollection.doc();
  final now = FieldValue.serverTimestamp();
  final invoiceNumber = _buildInvoiceNumber();

  await _firestore.runTransaction((transaction) async {
    // 1) READ ORDER FIRST
    final orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw Exception('Order not found');
    }

    final currentData = orderSnapshot.data() as Map<String, dynamic>;
    final currentStatus =
        (currentData['status'] ?? 'pending').toString().toLowerCase();

    if (currentStatus != 'pending') {
      throw Exception('Only pending orders can be confirmed');
    }

    final items = currentData['items'] as List<dynamic>? ?? [];

    String partName = '';
    String carModel = '';
    String imageUrl = '';
    String type = '';
    int quantity = 0;
    double unitPrice = 0.0;
    double totalPrice = 0.0;

    if (items.isNotEmpty) {
      final firstItem = Map<String, dynamic>.from(
        items.first as Map<String, dynamic>,
      );
      partName = (firstItem['partName'] ?? '').toString();
      carModel = (firstItem['carModel'] ?? '').toString();
      imageUrl = (firstItem['imageUrl'] ?? '').toString();
      type = (firstItem['type'] ?? '').toString();
      quantity = (currentData['itemCount'] ?? items.length) is int
          ? (currentData['itemCount'] ?? items.length) as int
          : int.tryParse('${currentData['itemCount'] ?? items.length}') ?? 0;
      unitPrice = ((firstItem['unitPrice'] ?? 0) as num).toDouble();
      totalPrice = ((currentData['totalAmount'] ?? 0) as num).toDouble();
    } else {
      partName = (currentData['partName'] ?? '').toString();
      carModel = (currentData['carModel'] ?? '').toString();
      imageUrl = (currentData['imageUrl'] ?? '').toString();
      type = (currentData['type'] ?? '').toString();
      quantity = (currentData['quantity'] ?? 0) is int
          ? currentData['quantity'] as int
          : int.tryParse('${currentData['quantity'] ?? 0}') ?? 0;
      unitPrice = ((currentData['unitPrice'] ?? 0) as num).toDouble();
      totalPrice =
          ((currentData['totalAmount'] ?? currentData['totalPrice'] ?? 0)
                  as num)
              .toDouble();
    }

    // 2) READ ALL SPARE PART DOCS BEFORE ANY WRITE
    final List<Map<String, dynamic>> stockUpdates = [];

    if (reduceStock) {
      for (final rawItem in items) {
        final item = Map<String, dynamic>.from(rawItem as Map<String, dynamic>);

        final partId = (item['partId'] ?? '').toString().trim();
        final qty = (item['quantity'] ?? 0) is int
            ? item['quantity'] as int
            : int.tryParse('${item['quantity']}') ?? 0;

        if (partId.isEmpty || qty <= 0) continue;

        final partRef = _sparePartsCollection.doc(partId);
        final partSnapshot = await transaction.get(partRef);

        if (!partSnapshot.exists) continue;

        final partData = partSnapshot.data() as Map<String, dynamic>;
        final currentStock = (partData['stock'] ?? 0) is int
            ? partData['stock'] as int
            : int.tryParse('${partData['stock']}') ?? 0;

        stockUpdates.add({
          'ref': partRef,
          'newStock': (currentStock - qty) < 0 ? 0 : (currentStock - qty),
        });
      }
    }

    // 3) NOW DO ALL WRITES
    transaction.update(orderRef, {
      'status': 'processing',
      'updatedAt': now,
      'invoiceId': invoiceRef.id,
      'invoiceNumber': invoiceNumber,
    });

    transaction.set(invoiceRef, {
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'customerId': currentData['customerId'],
      'customerName': currentData['customerName'],
      'customerEmail': currentData['customerEmail'],
      'customerPhone': currentData['customerPhone'],
      'items': items,
      'partName': partName,
      'carModel': carModel,
      'imageUrl': imageUrl,
      'type': type,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'subtotal': currentData['subtotal'] ?? totalPrice,
      'shippingFee': currentData['shippingFee'] ?? 0.0,
      'totalAmount': currentData['totalAmount'] ?? totalPrice,
      'status': 'issued',
      'createdAt': now,
      'pdfUrl': '',
    });

    for (final update in stockUpdates) {
      transaction.update(update['ref'] as DocumentReference, {
        'stock': update['newStock'],
        'updatedAt': now,
      });
    }
  });

  await NotificationService.instance.createNotification(
    targetUserId: (orderData['customerId'] ?? '').toString(),
    type: 'order_processing',
    title: 'Order Confirmed',
    body: 'Your parts order is now being processed.',
    extraData: {
      'orderId': orderId,
      'invoiceId': invoiceRef.id,
      'invoiceNumber': invoiceNumber,
    },
  );
}
  
  Future<void> markOrderShipped({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': 'shipped',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.instance.createNotification(
      targetUserId: (orderData['customerId'] ?? '').toString(),
      type: 'order_shipped',
      title: 'Order Shipped',
      body: 'Your order has been shipped.',
      extraData: {'orderId': orderId},
    );
  }

  Future<void> markOrderDelivered({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': 'confirmed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.instance.createNotification(
      targetUserId: (orderData['customerId'] ?? '').toString(),
      type: 'order_delivered',
      title: 'Order Delivered',
      body: 'Your order has been delivered. Please confirm receipt.',
      extraData: {'orderId': orderId},
    );
  }

  Future<void> cancelOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.instance.createNotification(
      targetUserId: (orderData['customerId'] ?? '').toString(),
      type: 'part_order_cancelled',
      title: 'Parts Order Cancelled',
      body: 'Your order has been cancelled.',
      extraData: {'orderId': orderId},
    );
  }
}
