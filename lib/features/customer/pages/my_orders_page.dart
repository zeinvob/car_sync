import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/features/customer/pages/order_details_page.dart';
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
    return FirebaseFirestore.instance
        .collection('part_orders')
        .where('customerId', isEqualTo: _userId)
        .snapshots();
  }

  // Sort orders by createdAt locally
  List<QueryDocumentSnapshot> _sortOrdersByDate(
    List<QueryDocumentSnapshot> orders,
  ) {
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
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
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
                final allOrders = _sortOrdersByDate(
                  snapshot.data?.docs.toList() ?? [],
                );
                debugPrint(
                  'MyOrdersPage - Total orders found: ${allOrders.length}',
                );

                // Debug: Print all order customerIds
                for (var doc in allOrders) {
                  final data = doc.data() as Map<String, dynamic>;
                  debugPrint(
                    'Order ${doc.id}: customerId=${data['customerId']}, status=${data['status']}',
                  );
                }

                // Separate active and history orders
                final activeOrders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();

                  return status == 'pending' ||
                      status == 'processing' ||
                      status == 'shipped' ||
                      status == 'confirmed';
                }).toList();

                debugPrint(
                  'MyOrdersPage - Active orders: ${activeOrders.length}',
                );

                final historyOrders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();

                  return status == 'completed' || status == 'cancelled';
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
      case 'processing':
        return (Colors.indigo, 'Processing');
      case 'shipped':
        return (Colors.purple, 'Shipped');
      case 'confirmed':
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderDetailsPage(orderId: orderId, orderData: data),
      ),
    ).then((result) {
      // Refresh the list if order was completed
      if (result == true) {
        setState(() {});
      }
    });
  }
}
