import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/sparepart_service.dart';
import 'package:car_sync/core/services/cart_service.dart';
import 'package:car_sync/features/customer/pages/cart_page.dart';
import 'package:car_sync/features/customer/pages/checkout_page.dart';
import 'package:car_sync/features/customer/pages/customer_support_chat_page.dart';
import 'package:car_sync/features/customer/pages/my_orders_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SparePartsPage extends StatelessWidget {
  const SparePartsPage({super.key});

  static final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps, 'color': AppColors.primary},
    {'name': 'Engine', 'icon': Icons.settings, 'color': Colors.red.shade600},
    {'name': 'Brake', 'icon': Icons.stop_circle_outlined, 'color': Colors.orange.shade600},
    {'name': 'Suspension', 'icon': Icons.airline_seat_legroom_extra, 'color': Colors.blue.shade600},
    {'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.purple.shade500},
    {'name': 'Light', 'icon': Icons.lightbulb_outline, 'color': Colors.amber.shade600},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.teal.shade500},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spare Parts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryTile(
            context: context,
            name: category['name'] as String,
            icon: category['icon'] as IconData,
            color: category['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile({
    required BuildContext context,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SparePartsListPage(category: name)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

/// Page to show spare parts filtered by category
class SparePartsListPage extends StatefulWidget {
  final String category;

  const SparePartsListPage({super.key, required this.category});

  @override
  State<SparePartsListPage> createState() => _SparePartsListPageState();
}

class _SparePartsListPageState extends State<SparePartsListPage> {
  final SparePartService _sparePartService = SparePartService();
  final CartService _cartService = CartService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allParts = [];
  List<Map<String, dynamic>> _filteredParts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChanged);
    _loadSpareParts();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSpareParts() async {
    setState(() => _isLoading = true);
    try {
      final parts = await _sparePartService.getAllSpareParts();
      if (mounted) {
        setState(() {
          // Filter by category
          if (widget.category == 'All') {
            _allParts = parts;
          } else {
            _allParts = parts
                .where(
                  (part) =>
                      (part['type'] ?? '').toString().toLowerCase() ==
                      widget.category.toLowerCase(),
                )
                .toList();
          }
          _filteredParts = _allParts;
        });
      }
    } catch (e) {
      debugPrint('Error loading spare parts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterParts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParts = _allParts.where((part) {
        return query.isEmpty ||
            (part['part'] ?? '').toString().toLowerCase().contains(query) ||
            (part['car_model'] ?? '').toString().toLowerCase().contains(
              query,
            ) ||
            (part['description'] ?? '').toString().toLowerCase().contains(
              query,
            );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // My Orders Icon
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersPage()),
              );
            },
          ),
          // Cart Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
              ),
              if (_cartService.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEE4D2D),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartService.itemCount > 99 ? '99+' : '${_cartService.itemCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterParts(),
              decoration: InputDecoration(
                hintText: 'Search parts, car model...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterParts();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
          ),
          const SizedBox(height: 8),
          // Parts Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredParts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadSpareParts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _filteredParts.length,
                      itemBuilder: (context, index) {
                        return _buildPartCard(_filteredParts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No spare parts found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(Map<String, dynamic> part) {
    final partName = part['part'] ?? 'Unknown Part';
    final carModel = part['car_model'] ?? '';
    final originalPrice = (part['originalPrice'] ?? part['price'] ?? 0)
        .toDouble();
    final salePrice = part['salePrice'] != null
        ? (part['salePrice']).toDouble()
        : null;
    final discountPercent = part['discountPercent'] ?? 0;
    final stock = part['stock'] ?? 0;
    final type = part['type'] ?? '';
    final imageUrl = part['imageUrl'] ?? '';
    final onSale = part['onSale'] == true && salePrice != null;

    final isInStock = stock > 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPartDetails(part),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Badge
            Stack(
              children: [
                // Image Container
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                _getTypeIcon(type),
                                color: _getTypeColor(type),
                                size: 40,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              _getTypeIcon(type),
                              color: _getTypeColor(type),
                              size: 40,
                            ),
                          ),
                  ),
                ),
                // Discount Badge (Shopee Style)
                if (onSale && discountPercent > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEE4D2D), // Shopee orange-red
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Out of Stock Overlay
                if (!isInStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    partName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Car Model
                  if (carModel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      carModel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Price Section (Shopee Style)
                  if (onSale) ...[
                    // Sale Price
                    Text(
                      'RM${salePrice!.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEE4D2D), // Shopee orange-red
                      ),
                    ),
                    // Original Price with strikethrough
                    Text(
                      'RM${originalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.grey,
                      ),
                    ),
                  ] else ...[
                    // Regular Price
                    Text(
                      'RM${originalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEE4D2D),
                      ),
                    ),
                  ],

                  // Stock Info (Shopee Style)
                  const SizedBox(height: 4),
                  if (isInStock)
                    Text(
                      '$stock left',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartDetails(Map<String, dynamic> part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PartDetailsSheet(part: part),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'engine':
        return Colors.red;
      case 'brake':
        return Colors.orange;
      case 'suspension':
        return Colors.blue;
      case 'electrical':
        return Colors.amber;
      case 'body':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'engine':
        return Icons.engineering;
      case 'brake':
        return Icons.do_not_disturb_on;
      case 'suspension':
        return Icons.height;
      case 'electrical':
        return Icons.electrical_services;
      case 'body':
        return Icons.directions_car;
      default:
        return Icons.build;
    }
  }
}

class _PartDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> part;

  const _PartDetailsSheet({required this.part});

  @override
  State<_PartDetailsSheet> createState() => _PartDetailsSheetState();
}

class _PartDetailsSheetState extends State<_PartDetailsSheet> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final CartService _cartService = CartService.instance;
  bool _isBuying = false;
  bool _isAddingToCart = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitPurchase(int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make a purchase'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isBuying = true);

    try {
      // Clear cart first for "Buy Now" flow
      _cartService.clearCart();
      
      // Add this item to cart with specified quantity
      _cartService.addFromPart(widget.part, quantity: quantity);

      if (mounted) {
        // Close the details sheet
        Navigator.pop(context);
        
        // Navigate directly to checkout
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to proceed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  void _showPurchaseDialog() {
    final originalPrice =
        (widget.part['originalPrice'] ?? widget.part['price'] ?? 0).toDouble();
    final salePrice = widget.part['salePrice'] != null
        ? (widget.part['salePrice']).toDouble()
        : null;
    final onSale = widget.part['onSale'] == true && salePrice != null;
    final unitPrice = onSale ? salePrice! : originalPrice;
    final stock = widget.part['stock'] ?? 0;
    
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Buy Now',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.part['part'] ?? 'Unknown Part',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${unitPrice.toStringAsFixed(2)} each',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                // Quantity selector
                Row(
                  children: [
                    Text(
                      'Quantity:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: quantity > 1
                                ? () => setDialogState(() => quantity--)
                                : null,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '$quantity',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: quantity < stock
                                ? () => setDialogState(() => quantity++)
                                : null,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$stock available',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                // Total price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'RM ${(unitPrice * quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isBuying
                    ? null
                    : () {
                        Navigator.pop(context);
                        _submitPurchase(quantity);
                      },
                icon: _isBuying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_cart_checkout, size: 18),
                label: Text(
                  _isBuying ? 'Processing...' : 'Confirm Order',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChatDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to contact admin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final partName = widget.part['part'] ?? 'Unknown Part';
    final carModel = widget.part['car_model'] ?? '';

    // Pre-fill message with part context
    final initialMessage = carModel.isNotEmpty 
        ? 'Hi, I have a question about: $partName (for $carModel)'
        : 'Hi, I have a question about: $partName';

    Navigator.pop(context); // Close part details sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerSupportChatPage(
          initialContext: initialMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partName = widget.part['part'] ?? 'Unknown Part';
    final description =
        widget.part['description'] ?? 'No description available';
    final originalPrice =
        (widget.part['originalPrice'] ?? widget.part['price'] ?? 0).toDouble();
    final salePrice = widget.part['salePrice'] != null
        ? (widget.part['salePrice']).toDouble()
        : null;
    final discountPercent = widget.part['discountPercent'] ?? 0;
    final stock = widget.part['stock'] ?? 0;
    final type = widget.part['type'] ?? 'Other';
    final imageUrl = widget.part['imageUrl'] ?? '';
    final onSale = widget.part['onSale'] == true && salePrice != null;
    final isInStock = stock > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scrollable content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Part Image
          if (imageUrl.isNotEmpty)
            Center(
              child: Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Part Name
          Text(
            partName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Details
          _buildDetailRow(
            Icons.description_outlined,
            'Description',
            description,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.inventory_2_outlined,
            'Availability',
            isInStock ? 'In Stock ($stock available)' : 'Out of Stock',
            valueColor: isInStock ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Bottom Bar
        _buildBottomBar(
          originalPrice: originalPrice,
          salePrice: salePrice,
          onSale: onSale,
          discountPercent: discountPercent,
          isInStock: isInStock,
        ),
      ],
    );
  }

  Widget _buildBottomBar({
    required double originalPrice,
    required double? salePrice,
    required bool onSale,
    required int discountPercent,
    required bool isInStock,
  }) {
    final displayPrice = onSale ? salePrice! : originalPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price Section
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onSale) ...[
                    Row(
                      children: [
                        Text(
                          'RM${originalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEE4D2D),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Text(
                    'RM ${displayPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEE4D2D),
                    ),
                  ),
                ],
              ),
            ),
            // Add to Cart Button
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: isInStock && !_isAddingToCart ? () => _addToCart() : null,
                icon: _isAddingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFEE4D2D),
                        ),
                      )
                    : const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(
                  'Cart',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEE4D2D),
                  side: const BorderSide(color: Color(0xFFEE4D2D), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Buy Now Button
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: isInStock ? () => _showPurchaseDialog() : null,
                icon: _isBuying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_cart_checkout, size: 18),
                label: Text(
                  _isBuying ? '...' : 'Buy Now',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEE4D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    setState(() => _isAddingToCart = true);

    try {
      _cartService.addFromPart(widget.part, quantity: 1);

      if (mounted) {
        // Capture the navigator and scaffold messenger before any async operations
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        
        // Close the bottom sheet first
        navigator.pop();
        
        // Then show snackbar on the parent page
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${widget.part['part']} added to cart'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                navigator.push(
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
