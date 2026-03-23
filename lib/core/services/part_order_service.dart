import 'package:car_sync/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      final orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }

      final currentData = orderSnapshot.data() as Map<String, dynamic>;
      final currentStatus =
          (currentData['status'] ?? 'pending').toString().toLowerCase();

      if (currentStatus == 'confirmed') {
        throw Exception('This order is already confirmed');
      }

      transaction.update(orderRef, {
        'status': 'confirmed',
        'updatedAt': now,
        'invoiceId': invoiceRef.id,
        'invoiceNumber': invoiceNumber,
      });

      // Handle both old format (single item) and new format (items array)
      final items = orderData['items'] as List<dynamic>?;
      String partName = '';
      String carModel = '';
      String imageUrl = '';
      String type = '';
      int quantity = 0;
      double unitPrice = 0.0;
      double totalPrice = 0.0;

      if (items != null && items.isNotEmpty) {
        // New format with items array
        final firstItem = items[0] as Map<String, dynamic>;
        partName = firstItem['partName'] ?? '';
        carModel = firstItem['carModel'] ?? '';
        imageUrl = firstItem['imageUrl'] ?? '';
        type = firstItem['type'] ?? '';
        quantity = orderData['itemCount'] ?? items.length;
        unitPrice = (firstItem['unitPrice'] ?? 0.0).toDouble();
        totalPrice = (orderData['totalAmount'] ?? 0.0).toDouble();
      } else {
        // Old format with direct fields
        partName = orderData['partName'] ?? '';
        carModel = orderData['carModel'] ?? '';
        imageUrl = orderData['imageUrl'] ?? '';
        type = orderData['type'] ?? '';
        quantity = orderData['quantity'] ?? 0;
        unitPrice = (orderData['unitPrice'] ?? 0.0).toDouble();
        totalPrice = (orderData['totalPrice'] ?? 0.0).toDouble();
      }

      transaction.set(invoiceRef, {
        'invoiceNumber': invoiceNumber,
        'orderId': orderId,
        'customerId': orderData['customerId'],
        'customerName': orderData['customerName'],
        'customerEmail': orderData['customerEmail'],
        'customerPhone': orderData['customerPhone'],
        'items': items, // Store items array for new format
        'partName': partName,
        'carModel': carModel,
        'imageUrl': imageUrl,
        'type': type,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'subtotal': orderData['subtotal'] ?? totalPrice,
        'shippingFee': orderData['shippingFee'] ?? 0.0,
        'totalAmount': orderData['totalAmount'] ?? totalPrice,
        'status': 'issued',
        'createdAt': now,
        'pdfUrl': '',
      });

      if (reduceStock) {
        final partId = (orderData['partId'] ?? '').toString().trim();
        final quantity = (orderData['quantity'] ?? 0) is int
            ? orderData['quantity'] as int
            : int.tryParse(orderData['quantity'].toString()) ?? 0;

        if (partId.isNotEmpty && quantity > 0) {
          final partRef = _sparePartsCollection.doc(partId);
          final partSnapshot = await transaction.get(partRef);

          if (partSnapshot.exists) {
            final partData = partSnapshot.data() as Map<String, dynamic>;
            final currentStock = (partData['stock'] ?? 0) is int
                ? partData['stock'] as int
                : int.tryParse(partData['stock'].toString()) ?? 0;

            final newStock = currentStock - quantity;
            transaction.update(partRef, {
              'stock': newStock < 0 ? 0 : newStock,
              'updatedAt': now,
            });
          }
        }
      }
    });

    await NotificationService.instance.createNotification(
      targetUserId: (orderData['customerId'] ?? '').toString(),
      type: 'invoice_created',
      title: 'Invoice Ready',
      body:
          'Your invoice for ${(orderData['partName'] ?? 'part').toString()} has been created.',
      extraData: {
        'orderId': orderId,
        'invoiceId': invoiceRef.id,
        'invoiceNumber': invoiceNumber,
      },
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
      body:
          'Your order for ${(orderData['partName'] ?? 'part').toString()} has been cancelled.',
      extraData: {
        'orderId': orderId,
      },
    );
  }
}