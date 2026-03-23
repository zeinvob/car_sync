import 'package:car_sync/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('MyOrdersPage - Current User ID: $_userId');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    debugPrint('MyOrdersPage - Getting orders for userId: $_userId');
    if (_userId == null) {
      debugPrint('MyOrdersPage - User ID is null!');
      return const Stream.empty();
    }
    // Note: Using only where clause to avoid needing a composite index
    // We'll sort the results locally instead
    return FirebaseFirestore.instance
        .collection('part_orders')
        .where('customerId', isEqualTo: _userId)
        .snapshots();
  }

  // Sort orders by createdAt locally
  List<QueryDocumentSnapshot> _sortOrdersByDate(List<QueryDocumentSnapshot> orders) {
    orders.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = aData['createdAt'] as Timestamp?;
      final bDate = bData['createdAt'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // Descending order
    });
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'History'),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Error loading orders: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Sort orders locally
                final allOrders = _sortOrdersByDate(snapshot.data?.docs.toList() ?? []);
                debugPrint('MyOrdersPage - Total orders found: ${allOrders.length}');
                
                // Debug: Print all order customerIds
                for (var doc in allOrders) {
                  final data = doc.data() as Map<String, dynamic>;
                  debugPrint('Order ${doc.id}: customerId=${data['customerId']}, status=${data['status']}');
                }

                // Separate active and history orders
                final activeOrders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  return status == 'pending' ||
                      status == 'confirmed' ||
                      status == 'processing' ||
                      status == 'shipped';
                }).toList();
                
                debugPrint('MyOrdersPage - Active orders: ${activeOrders.length}');

                final historyOrders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  return status == 'completed' ||
                      status == 'delivered' ||
                      status == 'cancelled';
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(activeOrders, isHistory: false),
                    _buildOrdersList(historyOrders, isHistory: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    List<QueryDocumentSnapshot> orders, {
    required bool isHistory,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistory ? Icons.history : Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isHistory ? 'No Order History' : 'No Active Orders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isHistory
                  ? 'Your completed orders will appear here'
                  : 'Your pending orders will appear here',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final doc = orders[index];
          final data = doc.data() as Map<String, dynamic>;
          return _buildOrderCard(doc.id, data);
        },
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final items = data['items'] as List<dynamic>? ?? [];
    final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
    final createdAt = data['createdAt'] as Timestamp?;

    // Format date
    String dateStr = 'N/A';
    if (createdAt != null) {
      dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
    }

    // Status styling
    final (statusColor, statusLabel) = _getStatusStyle(status);

    // Get first item image or use placeholder
    String? firstItemImage;
    String itemsSummary = '';
    if (items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>;
      firstItemImage = firstItem['imageUrl'] as String?;
      if (items.length == 1) {
        itemsSummary = '${firstItem['partName']} x${firstItem['quantity']}';
      } else {
        itemsSummary =
            '${firstItem['partName']} +${items.length - 1} more item${items.length > 2 ? 's' : ''}';
      }
    }

    return GestureDetector(
      onTap: () => _showOrderDetails(orderId, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${orderId.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Order Items Preview
              Row(
                children: [
                  // Item Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: firstItemImage != null && firstItemImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              firstItemImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.build_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Icon(Icons.build_outlined, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 12),
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemsSummary,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Total and View Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        'RM ${totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _showOrderDetails(orderId, data),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String) _getStatusStyle(String status) {
    switch (status) {
      case 'pending':
        return (Colors.orange, 'Pending');
      case 'confirmed':
        return (Colors.blue, 'Confirmed');
      case 'processing':
        return (Colors.indigo, 'Processing');
      case 'shipped':
        return (Colors.purple, 'Shipped');
      case 'delivered':
        return (Colors.green, 'Delivered');
      case 'completed':
        return (Colors.teal, 'Completed');
      case 'cancelled':
        return (Colors.red, 'Cancelled');
      default:
        return (Colors.grey, status.toUpperCase());
    }
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>? ?? [];
    final subtotal = (data['subtotal'] ?? 0.0).toDouble();
    final shippingFee = (data['shippingFee'] ?? 0.0).toDouble();
    final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final createdAt = data['createdAt'] as Timestamp?;
    final shippingAddress = data['shippingAddress'] as Map<String, dynamic>?;
    
    // Invoice info
    final invoiceNumber = data['invoiceNumber'] as String?;
    final invoiceId = data['invoiceId'] as String?;

    // Format date
    String dateStr = 'N/A';
    if (createdAt != null) {
      dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
    }

    final (statusColor, statusLabel) = _getStatusStyle(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '#${orderId.substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Order Date
                    _buildInfoRow(Icons.calendar_today, 'Order Date', dateStr),
                    const SizedBox(height: 20),
                    // Shipping Address
                    if (shippingAddress != null) ...[
                      Text(
                        'Shipping Address',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shippingAddress['fullName'] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              shippingAddress['phone'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${shippingAddress['addressLine1'] ?? ''}\n'
                              '${shippingAddress['addressLine2'] ?? ''}\n'
                              '${shippingAddress['postcode'] ?? ''} ${shippingAddress['city'] ?? ''}\n'
                              '${shippingAddress['state'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Order Items
                    Text(
                      'Items (${items.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) {
                      final itemData = item as Map<String, dynamic>;
                      final partName = itemData['partName'] ?? 'Part';
                      final quantity = itemData['quantity'] ?? 1;
                      final unitPrice = (itemData['unitPrice'] ?? 0.0).toDouble();
                      final imageUrl = itemData['imageUrl'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Image
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.build_outlined,
                                          color: Colors.grey[400],
                                          size: 24,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.build_outlined,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'RM ${unitPrice.toStringAsFixed(2)} x $quantity',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Subtotal
                            Text(
                              'RM ${(unitPrice * quantity).toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    // Order Summary
                    Text(
                      'Order Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', 'RM ${subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Shipping Fee',
                            shippingFee > 0
                                ? 'RM ${shippingFee.toStringAsFixed(2)}'
                                : 'FREE',
                          ),
                          const Divider(height: 20),
                          _buildSummaryRow(
                            'Total',
                            'RM ${totalAmount.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    // Invoice Section
                    if (invoiceNumber != null && invoiceId != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Invoice',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoice Ready',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  Text(
                                    invoiceNumber,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showInvoiceDetails(invoiceId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? null : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Future<void> _showInvoiceDetails(String invoiceId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final invoiceDoc = await FirebaseFirestore.instance
          .collection('invoice')
          .doc(invoiceId)
          .get();

      if (mounted) Navigator.pop(context); // Close loading

      if (!invoiceDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final invoice = invoiceDoc.data()!;
      final invoiceNumber = invoice['invoiceNumber'] ?? '';
      final customerName = invoice['customerName'] ?? '';
      final customerEmail = invoice['customerEmail'] ?? '';
      final customerPhone = invoice['customerPhone'] ?? '';
      final createdAt = invoice['createdAt'] as Timestamp?;
      final invoiceStatus = invoice['status'] ?? 'issued';
      
      // Handle both formats - items array (new) or single item (old)
      final items = invoice['items'] as List<dynamic>?;
      final subtotal = (invoice['subtotal'] ?? invoice['totalPrice'] ?? 0.0).toDouble();
      final shippingFee = (invoice['shippingFee'] ?? 0.0).toDouble();
      final totalAmount = (invoice['totalAmount'] ?? invoice['totalPrice'] ?? 0.0).toDouble();

      String invoiceDateStr = 'N/A';
      if (createdAt != null) {
        invoiceDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                invoiceNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            invoiceStatus.toString().toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Invoice Date
                        _buildInfoRow(Icons.calendar_today, 'Invoice Date', invoiceDateStr),
                        const SizedBox(height: 20),
                        // Customer Info
                        Text(
                          'Bill To',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              if (customerEmail.isNotEmpty)
                                Text(
                                  customerEmail,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (customerPhone.isNotEmpty)
                                Text(
                                  customerPhone,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Item Details
                        Text(
                          'Items',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Show items from array or single item
                        if (items != null && items.isNotEmpty)
                          ...items.map((item) {
                            final itemData = item as Map<String, dynamic>;
                            final partName = itemData['partName'] ?? '';
                            final carModel = itemData['carModel'] ?? '';
                            final quantity = itemData['quantity'] ?? 1;
                            final unitPrice = (itemData['unitPrice'] ?? 0.0).toDouble();
                            final imageUrl = itemData['imageUrl'] as String?;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Image
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: imageUrl != null && imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.build_outlined,
                                                color: Colors.grey[400],
                                                size: 24,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.build_outlined,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          partName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (carModel.isNotEmpty)
                                          Text(
                                            carModel,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RM ${unitPrice.toStringAsFixed(2)} x $quantity',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Subtotal
                                  Text(
                                    'RM ${(unitPrice * quantity).toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                        else
                          // Fallback for old format without items array
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice['partName'] ?? 'Item',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                ),
                                if ((invoice['carModel'] ?? '').toString().isNotEmpty)
                                  Text(
                                    'For: ${invoice['carModel']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unit Price',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'RM ${(invoice['unitPrice'] ?? 0.0).toDouble().toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Quantity',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'x ${invoice['quantity'] ?? 0}',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        // Order Summary
                        Text(
                          'Summary',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('Subtotal', 'RM ${subtotal.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Shipping Fee',
                                shippingFee > 0
                                    ? 'RM ${shippingFee.toStringAsFixed(2)}'
                                    : 'FREE',
                              ),
                              const Divider(height: 20),
                              _buildSummaryRow(
                                'Total Amount',
                                'RM ${totalAmount.toStringAsFixed(2)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      debugPrint('Error loading invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
