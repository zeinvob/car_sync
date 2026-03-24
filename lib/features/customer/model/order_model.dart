import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a customer order
class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic> shippingAddress;
  final List<Map<String, dynamic>> items;
  final int itemCount;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final String referenceNumber;
  final String status;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    this.shippingFee = 0,
    required this.totalAmount,
    required this.referenceNumber,
    required this.status,
    this.createdAt,
    this.confirmedAt,
  });

  /// Create from Firestore document
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shippingAddress: data['shippingAddress'] ?? {},
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      itemCount: data['itemCount'] ?? 0,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      referenceNumber: data['referenceNumber'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'items': items,
      'itemCount': itemCount,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'totalAmount': totalAmount,
      'referenceNumber': referenceNumber,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Check if order is active
  bool get isActive {
    return ['pending', 'confirmed'].contains(status);
  }

  /// Check if order can be marked as completed
  bool get canComplete => status == 'confirmed';

  /// Get status display label
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }
}
