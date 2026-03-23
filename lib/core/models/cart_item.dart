/// Model representing an item in the shopping cart
class CartItem {
  final String partId;
  final String partName;
  final String carModel;
  final String imageUrl;
  final String type;
  final double unitPrice;
  final double originalPrice;
  final double? salePrice;
  final bool onSale;
  int quantity;
  final int stock;

  CartItem({
    required this.partId,
    required this.partName,
    required this.carModel,
    required this.imageUrl,
    required this.type,
    required this.unitPrice,
    required this.originalPrice,
    this.salePrice,
    required this.onSale,
    required this.quantity,
    required this.stock,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'partName': partName,
      'carModel': carModel,
      'imageUrl': imageUrl,
      'type': type,
      'unitPrice': unitPrice,
      'originalPrice': originalPrice,
      'salePrice': salePrice,
      'onSale': onSale,
      'quantity': quantity,
      'stock': stock,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      partId: map['partId'] ?? '',
      partName: map['partName'] ?? '',
      carModel: map['carModel'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      type: map['type'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      salePrice: map['salePrice'] != null ? (map['salePrice']).toDouble() : null,
      onSale: map['onSale'] ?? false,
      quantity: map['quantity'] ?? 1,
      stock: map['stock'] ?? 0,
    );
  }

  factory CartItem.fromPart(Map<String, dynamic> part, {int quantity = 1}) {
    final originalPrice = (part['originalPrice'] ?? part['price'] ?? 0).toDouble();
    final salePrice = part['salePrice'] != null ? (part['salePrice']).toDouble() : null;
    final onSale = part['onSale'] == true && salePrice != null;
    final unitPrice = onSale ? salePrice! : originalPrice;

    return CartItem(
      partId: part['id'] ?? '',
      partName: part['part'] ?? '',
      carModel: part['car_model'] ?? '',
      imageUrl: part['imageUrl'] ?? '',
      type: part['type'] ?? '',
      unitPrice: unitPrice,
      originalPrice: originalPrice,
      salePrice: salePrice,
      onSale: onSale,
      quantity: quantity,
      stock: part['stock'] ?? 0,
    );
  }

  CartItem copyWith({
    String? partId,
    String? partName,
    String? carModel,
    String? imageUrl,
    String? type,
    double? unitPrice,
    double? originalPrice,
    double? salePrice,
    bool? onSale,
    int? quantity,
    int? stock,
  }) {
    return CartItem(
      partId: partId ?? this.partId,
      partName: partName ?? this.partName,
      carModel: carModel ?? this.carModel,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      unitPrice: unitPrice ?? this.unitPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      salePrice: salePrice ?? this.salePrice,
      onSale: onSale ?? this.onSale,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
    );
  }
}
