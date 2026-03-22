import 'package:cloud_firestore/cloud_firestore.dart';

class StockItemModel {
  final String id;
  final String carModel;
  final String description;
  final int discountPercent;
  final String imageUrl;
  final bool onSale;
  final double originalPrice;
  final String part;
  final double salePrice;
  final int stock;
  final String type;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  StockItemModel({
    required this.id,
    required this.carModel,
    required this.description,
    required this.discountPercent,
    required this.imageUrl,
    required this.onSale,
    required this.originalPrice,
    required this.part,
    required this.salePrice,
    required this.stock,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory StockItemModel.fromMap(String id, Map<String, dynamic> map) {
    return StockItemModel(
      id: id,
      carModel: (map['carModel'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      discountPercent: (map['discountPercent'] ?? 0) is int
          ? map['discountPercent'] as int
          : int.tryParse(map['discountPercent'].toString()) ?? 0,
      imageUrl: (map['imageUrl'] ?? '').toString(),
      onSale: map['onSale'] ?? false,
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      part: (map['part'] ?? '').toString(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0) is int
          ? map['stock'] as int
          : int.tryParse(map['stock'].toString()) ?? 0,
      type: (map['type'] ?? '').toString(),
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carModel': carModel,
      'description': description,
      'discountPercent': discountPercent,
      'imageUrl': imageUrl,
      'onSale': onSale,
      'originalPrice': originalPrice,
      'part': part,
      'salePrice': salePrice,
      'stock': stock,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  StockItemModel copyWith({
    String? id,
    String? carModel,
    String? description,
    int? discountPercent,
    String? imageUrl,
    bool? onSale,
    double? originalPrice,
    String? part,
    double? salePrice,
    int? stock,
    String? type,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      carModel: carModel ?? this.carModel,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      imageUrl: imageUrl ?? this.imageUrl,
      onSale: onSale ?? this.onSale,
      originalPrice: originalPrice ?? this.originalPrice,
      part: part ?? this.part,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}