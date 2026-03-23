import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/models/cart_item.dart';
import 'package:car_sync/core/services/cart_service.dart';
import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/core/services/user_service.dart';
import 'package:car_sync/features/customer/pages/my_orders_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CartService _cartService = CartService.instance;
  final UserService _userService = UserService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _userService.getUserData(user.uid);

        if (userData != null) {
          _nameController.text = userData['fullName'] ?? userData['name'] ?? '';
          _emailController.text = userData['email'] ?? user.email ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _cityController.text = userData['city'] ?? '';
          _postcodeController.text = userData['postcode'] ?? '';
          _stateController.text = userData['state'] ?? '';
        } else {
          _emailController.text = user.email ?? '';
          _nameController.text = user.displayName ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    _buildSectionTitle('Order Summary', onSurface),
                    const SizedBox(height: 12),
                    _buildOrderSummary(isDark, onSurface),
                    const SizedBox(height: 24),

                    // Shipping Information
                    _buildSectionTitle('Shipping Information', onSurface),
                    const SizedBox(height: 12),
                    _buildShippingForm(isDark, onSurface),
                    const SizedBox(height: 24),

                    // Total
                    _buildTotalSection(isDark, onSurface),
                    const SizedBox(height: 24),

                    // Place Order Button
                    _buildPlaceOrderButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, Color onSurface) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          ..._cartService.items.map((item) => _buildOrderItem(item, onSurface)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${_cartService.itemCount} items)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                'RM ${_cartService.subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, color: Colors.grey.shade400, size: 20),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image, color: Colors.grey.shade400, size: 20),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.partName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity} × RM ${item.unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${item.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm(bool isDark, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v?.isEmpty == true) return 'Email is required';
              if (!v!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty == true ? 'Phone is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) => v?.isEmpty == true ? 'Address is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _postcodeController,
                  label: 'Postcode',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _stateController,
            label: 'State',
            icon: Icons.map_outlined,
            validator: (v) => v?.isEmpty == true ? 'State is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildTotalSection(bool isDark, Color onSurface) {
    const shippingFee = 0.0; // Free shipping
    final total = _cartService.subtotal + shippingFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.poppins(fontSize: 14, color: onSurface),
              ),
              Text(
                'RM ${_cartService.subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(fontSize: 14, color: onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping',
                style: GoogleFonts.poppins(fontSize: 14, color: onSurface),
              ),
              Text(
                shippingFee > 0 ? 'RM ${shippingFee.toStringAsFixed(2)}' : 'FREE',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: shippingFee > 0 ? onSurface : Colors.green,
                  fontWeight: shippingFee > 0 ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              Text(
                'RM ${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Place Order - RM ${_cartService.subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please login to continue');
      }

      // Generate reference number
      final refNumber = 'CS-${DateTime.now().millisecondsSinceEpoch}';

      // Create order in Firestore
      final orderRef = await FirebaseFirestore.instance.collection('part_orders').add({
        'customerId': user.uid,
        'customerName': _nameController.text.trim(),
        'customerEmail': _emailController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'shippingAddress': {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postcode': _postcodeController.text.trim(),
          'state': _stateController.text.trim(),
        },
        'items': _cartService.toMapList(),
        'itemCount': _cartService.itemCount,
        'subtotal': _cartService.subtotal,
        'shippingFee': 0.0,
        'totalAmount': _cartService.subtotal,
        'referenceNumber': refNumber,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for admins
      await NotificationService.instance.createPartOrderNotificationForAdmins(
        orderId: orderRef.id,
        customerName: _nameController.text.trim(),
        partName: _cartService.items.length == 1
            ? _cartService.items.first.partName
            : '${_cartService.items.length} items',
        quantity: _cartService.itemCount,
      );

      // Clear cart
      _cartService.clearCart();

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            content: Stack(
              children: [
                // Close button
                Positioned(
                  right: -12,
                  top: -8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close checkout
                      Navigator.pop(context); // Close cart
                    },
                  ),
                ),
                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 60,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order Placed!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your order has been placed successfully. We will process it shortly.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ref: $refNumber',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close checkout
                    Navigator.pop(context); // Close cart
                    // Navigate to My Orders page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'View My Orders',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Order Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
