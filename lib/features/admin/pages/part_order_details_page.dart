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
  final PageController _imagePageController = PageController(viewportFraction: 0.92);
  int _currentImageIndex = 0;

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

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'confirmed':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'processing':
        return Icons.precision_manufacturing_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'confirmed':
        return Icons.inventory_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: onSurface.withOpacity(0.60),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.8,
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider(List<dynamic> items) {
    if (items.isEmpty) {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.inventory_2_rounded,
            color: Colors.white,
            size: 56,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _imagePageController,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              final item = Map<String, dynamic>.from(items[index] as Map<String, dynamic>);
              final imageUrl = (item['imageUrl'] ?? '').toString();
              final partName = (item['partName'] ?? 'Part').toString();

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white.withOpacity(0.10),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.white.withOpacity(0.10),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  partName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${index + 1}/${items.length}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final selected = index == _currentImageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryChips(Map<String, dynamic> data, List<dynamic> items) {
    return Row(
      children: [
        Expanded(
          child: _summaryChip(
            icon: Icons.layers_rounded,
            label: 'Items',
            value: '${_toInt(data['itemCount'] ?? items.length)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryChip(
            icon: Icons.payments_rounded,
            label: 'Total',
            value: 'RM ${_toDouble(data['totalAmount']).toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.60),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ],
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
        reduceStock: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order moved to processing.', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          content: Text('Order marked as shipped.', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          content: Text('Order marked as delivered.', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
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
          content: Text('Order cancelled.', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderData;
    final items = (data['items'] as List<dynamic>? ?? []);
    final firstItem = items.isNotEmpty
        ? Map<String, dynamic>.from(items.first as Map<String, dynamic>)
        : <String, dynamic>{};
    final shipping = Map<String, dynamic>.from(data['shippingAddress'] ?? {});

    final status = (data['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final title = items.length == 1
        ? (firstItem['partName'] ?? 'Part').toString()
        : '${items.length} Parts Ordered';

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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _buildImageSlider(items),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryChips(data, items),
          const SizedBox(height: 16),

          _sectionCard(
            title: 'Order Information',
            icon: Icons.receipt_long_rounded,
            child: Column(
              children: [
                _infoRow('Order ID', widget.orderId),
                _infoRow('Invoice No', (data['invoiceNumber'] ?? '-').toString()),
                _infoRow('Status', _statusLabel(status)),
                _infoRow('Items Count', '${_toInt(data['itemCount'] ?? items.length)}'),
                _infoRow('Subtotal', 'RM ${_toDouble(data['subtotal']).toStringAsFixed(2)}'),
                _infoRow('Shipping Fee', 'RM ${_toDouble(data['shippingFee']).toStringAsFixed(2)}'),
                _infoRow('Total Amount', 'RM ${_toDouble(data['totalAmount']).toStringAsFixed(2)}'),
                _infoRow('Created At', _formatDate(data['createdAt'] as Timestamp?)),
                _infoRow('Updated At', _formatDate(data['updatedAt'] as Timestamp?)),
                _infoRow('Completed At', _formatDate(data['completedAt'] as Timestamp?)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: 'Customer Information',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                _infoRow('Name', (data['customerName'] ?? '').toString()),
                _infoRow('Email', (data['customerEmail'] ?? '').toString()),
                _infoRow('Phone', (data['customerPhone'] ?? '').toString()),
                _infoRow('Customer ID', (data['customerId'] ?? '').toString()),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: 'Shipping Address',
            icon: Icons.location_on_outlined,
            child: Column(
              children: [
                _infoRow('Address', (shipping['address'] ?? shipping['addressLine1'] ?? '').toString()),
                _infoRow('City', (shipping['city'] ?? '').toString()),
                _infoRow('State', (shipping['state'] ?? '').toString()),
                _infoRow('Postcode', (shipping['postcode'] ?? '').toString()),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: 'Ordered Items',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: items.map((rawItem) {
                final item = Map<String, dynamic>.from(rawItem as Map<String, dynamic>);
                final imageUrl = (item['imageUrl'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.inventory_2_outlined),
                                ),
                              )
                            : Container(
                                width: 72,
                                height: 72,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.inventory_2_outlined),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (item['partName'] ?? 'Part').toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _infoRow('Part ID', (item['partId'] ?? '').toString()),
                            _infoRow('Type', (item['type'] ?? '').toString()),
                            _infoRow('Car Model', (item['carModel'] ?? '').toString()),
                            _infoRow('Quantity', '${_toInt(item['quantity'])}'),
                            _infoRow('Unit Price', 'RM ${_toDouble(item['unitPrice']).toStringAsFixed(2)}'),
                            _infoRow('Sale Price', 'RM ${_toDouble(item['salePrice']).toStringAsFixed(2)}'),
                            _infoRow('Original Price', 'RM ${_toDouble(item['originalPrice']).toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          if (status.toLowerCase() == 'pending') ...[
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmOrder,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Confirm Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (status.toLowerCase() == 'processing') ...[
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _markShipped,
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Mark as Shipped',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (status.toLowerCase() == 'shipped') ...[
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _markDelivered,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Mark as Delivered',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _cancelOrder,
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                label: Text(
                  'Cancel Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: statusColor.withOpacity(0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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