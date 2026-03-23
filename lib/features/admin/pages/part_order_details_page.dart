import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/part_order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PartOrderDetailsPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const PartOrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<PartOrderDetailsPage> createState() => _PartOrderDetailsPageState();
}

class _PartOrderDetailsPageState extends State<PartOrderDetailsPage> {
  bool _isProcessing = false;

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse('$value') ?? 0;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.indigo;
      case 'shipped':
        return Colors.purple;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(String label, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: onSurface.withOpacity(0.70),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder() async {
    setState(() => _isProcessing = true);

    try {
      await PartOrderService.instance.confirmOrderAndCreateInvoice(
        orderId: widget.orderId,
        orderData: widget.orderData,
        reduceStock: false,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order moved to processing.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markShipped() async {
    setState(() => _isProcessing = true);

    try {
      await PartOrderService.instance.markOrderShipped(
        orderId: widget.orderId,
        orderData: widget.orderData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as shipped.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markDelivered() async {
    setState(() => _isProcessing = true);

    try {
      await PartOrderService.instance.markOrderDelivered(
        orderId: widget.orderId,
        orderData: widget.orderData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as delivered.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelOrder() async {
    setState(() => _isProcessing = true);

    try {
      await PartOrderService.instance.cancelOrder(
        orderId: widget.orderId,
        orderData: widget.orderData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order cancelled.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderData;
    final items = (data['items'] as List<dynamic>? ?? []);
    final firstItem = items.isNotEmpty
        ? Map<String, dynamic>.from(items.first as Map<String, dynamic>)
        : <String, dynamic>{};
    final shipping = (data['shippingAddress'] as Map<String, dynamic>? ?? {});

    final status = (data['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final imageUrl = (firstItem['imageUrl'] ?? '').toString();
    final partName = (firstItem['partName'] ?? 'Part').toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    imageUrl,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 74,
                      height: 74,
                      color: Colors.white.withOpacity(0.16),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (data['customerName'] ?? 'Customer').toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Information',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                _infoRow('Order ID', widget.orderId),
                _infoRow('Invoice No', (data['invoiceNumber'] ?? '-').toString()),
                _infoRow('Status', status),
                _infoRow(
                  'Items Count',
                  '${_toInt(data['itemCount'] ?? items.length)}',
                ),
                _infoRow(
                  'Subtotal',
                  'RM ${_toDouble(data['subtotal']).toStringAsFixed(2)}',
                ),
                _infoRow(
                  'Shipping Fee',
                  'RM ${_toDouble(data['shippingFee']).toStringAsFixed(2)}',
                ),
                _infoRow(
                  'Total Amount',
                  'RM ${_toDouble(data['totalAmount']).toStringAsFixed(2)}',
                ),
                _infoRow(
                  'Created At',
                  _formatDate(data['createdAt'] as Timestamp?),
                ),
                _infoRow(
                  'Updated At',
                  _formatDate(data['updatedAt'] as Timestamp?),
                ),
                _infoRow(
                  'Completed At',
                  _formatDate(data['completedAt'] as Timestamp?),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Information',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                _infoRow('Name', (data['customerName'] ?? '').toString()),
                _infoRow('Email', (data['customerEmail'] ?? '').toString()),
                _infoRow('Phone', (data['customerPhone'] ?? '').toString()),
                _infoRow('Customer ID', (data['customerId'] ?? '').toString()),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Address',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                _infoRow(
                  'Address',
                  (shipping['address'] ??
                          shipping['addressLine1'] ??
                          '')
                      .toString(),
                ),
                _infoRow('City', (shipping['city'] ?? '').toString()),
                _infoRow('State', (shipping['state'] ?? '').toString()),
                _infoRow('Postcode', (shipping['postcode'] ?? '').toString()),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordered Items',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((rawItem) {
                  final item = Map<String, dynamic>.from(
                    rawItem as Map<String, dynamic>,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['partName'] ?? 'Part').toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _infoRow('Part ID', (item['partId'] ?? '').toString()),
                        _infoRow('Type', (item['type'] ?? '').toString()),
                        _infoRow('Car Model', (item['carModel'] ?? '').toString()),
                        _infoRow('Quantity', '${_toInt(item['quantity'])}'),
                        _infoRow(
                          'Unit Price',
                          'RM ${_toDouble(item['unitPrice']).toStringAsFixed(2)}',
                        ),
                        _infoRow(
                          'Sale Price',
                          'RM ${_toDouble(item['salePrice']).toStringAsFixed(2)}',
                        ),
                        _infoRow(
                          'Original Price',
                          'RM ${_toDouble(item['originalPrice']).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (status.toLowerCase() == 'pending') ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Confirm Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (status.toLowerCase() == 'processing') ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _markShipped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Mark as Shipped',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (status.toLowerCase() == 'shipped') ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _markDelivered,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Mark as Delivered',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (status.toLowerCase() == 'pending' ||
              status.toLowerCase() == 'processing' ||
              status.toLowerCase() == 'shipped') ...[
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _cancelOrder,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: statusColor.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}