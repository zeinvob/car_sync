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
      case 'confirmed':
        return Colors.green;
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
            'Order confirmed and invoice created.',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderData;
    final status = (data['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
                    (data['imageUrl'] ?? '').toString(),
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
                        (data['partName'] ?? 'Part').toString(),
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
                _infoRow('Part Name', (data['partName'] ?? '').toString()),
                _infoRow('Type', (data['type'] ?? '').toString()),
                _infoRow('Car Model', (data['carModel'] ?? '').toString()),
                _infoRow('Quantity', '${_toInt(data['quantity'])}'),
                _infoRow(
                  'Unit Price',
                  'RM ${_toDouble(data['unitPrice']).toStringAsFixed(2)}',
                ),
                _infoRow(
                  'Sale Price',
                  'RM ${_toDouble(data['salePrice']).toStringAsFixed(2)}',
                ),
                _infoRow(
                  'Original Price',
                  'RM ${_toDouble(data['originalPrice']).toStringAsFixed(2)}',
                ),
                _infoRow(
                  'Total Price',
                  'RM ${_toDouble(data['totalPrice']).toStringAsFixed(2)}',
                ),
                _infoRow('Status', status),
                _infoRow(
                  'Created At',
                  _formatDate(data['createdAt'] as Timestamp?),
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
                  _isProcessing
                      ? 'Processing...'
                      : 'Confirm & Create Invoice',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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