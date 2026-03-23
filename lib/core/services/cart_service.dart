import 'package:flutter/foundation.dart';
import 'package:car_sync/core/models/cart_item.dart';

/// Service for managing shopping cart state
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];

  /// Get all cart items
  List<CartItem> get items => List.unmodifiable(_items);

  /// Get total number of items in cart
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Get number of unique items in cart
  int get uniqueItemCount => _items.length;

  /// Get subtotal (before any fees)
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => _items.isNotEmpty;

  /// Add item to cart
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.partId == item.partId);
    
    if (existingIndex >= 0) {
      // Item exists, update quantity
      final existing = _items[existingIndex];
      final newQuantity = existing.quantity + item.quantity;
      
      // Don't exceed stock
      if (newQuantity <= existing.stock) {
        _items[existingIndex] = existing.copyWith(quantity: newQuantity);
      } else {
        _items[existingIndex] = existing.copyWith(quantity: existing.stock);
      }
    } else {
      // New item, add to cart
      _items.add(item);
    }
    
    notifyListeners();
  }

  /// Add item from spare part map
  void addFromPart(Map<String, dynamic> part, {int quantity = 1}) {
    final cartItem = CartItem.fromPart(part, quantity: quantity);
    addItem(cartItem);
  }

  /// Remove item from cart
  void removeItem(String partId) {
    _items.removeWhere((item) => item.partId == partId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String partId, int quantity) {
    final index = _items.indexWhere((item) => item.partId == partId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        final item = _items[index];
        // Don't exceed stock
        final newQuantity = quantity > item.stock ? item.stock : quantity;
        _items[index] = item.copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  /// Increment item quantity by 1
  void incrementQuantity(String partId) {
    final index = _items.indexWhere((item) => item.partId == partId);
    
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity < item.stock) {
        _items[index] = item.copyWith(quantity: item.quantity + 1);
        notifyListeners();
      }
    }
  }

  /// Decrement item quantity by 1
  void decrementQuantity(String partId) {
    final index = _items.indexWhere((item) => item.partId == partId);
    
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > 1) {
        _items[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// Check if item is in cart
  bool isInCart(String partId) {
    return _items.any((item) => item.partId == partId);
  }

  /// Get item quantity in cart
  int getQuantity(String partId) {
    final item = _items.firstWhere(
      (item) => item.partId == partId,
      orElse: () => CartItem(
        partId: '',
        partName: '',
        carModel: '',
        imageUrl: '',
        type: '',
        unitPrice: 0,
        originalPrice: 0,
        onSale: false,
        quantity: 0,
        stock: 0,
      ),
    );
    return item.quantity;
  }

  /// Clear all items from cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Get cart items as list of maps (for order creation)
  List<Map<String, dynamic>> toMapList() {
    return _items.map((item) => item.toMap()).toList();
  }
}
