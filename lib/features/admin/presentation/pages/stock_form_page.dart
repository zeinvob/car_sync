import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockFormPage extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? existingData;

  const StockFormPage({
    super.key,
    this.documentId,
    this.existingData,
  });

  @override
  State<StockFormPage> createState() => _StockFormPageState();
}

class _StockFormPageState extends State<StockFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _partController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _originalPriceController =
      TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  // IMPORTANT: same collection as StockPage
  final CollectionReference _partsCollection =
      FirebaseFirestore.instance.collection('spareparts');

  bool _isSaving = false;
  String _selectedType = 'Engine';
  int _discountPercent = 0;

  final List<String> _types = const [
    'Engine',
    'Brake',
    'Suspension',
    'Electrical',
    'Light',
    'Other',
  ];

  bool get isEdit => widget.documentId != null && widget.documentId!.isNotEmpty;

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _readCarModel(Map<String, dynamic> data) {
    return (data['car model'] ?? '').toString();
  }

  double _readOriginalPrice(Map<String, dynamic> data) {
    return _toDouble(data['originalPrice'] ?? data['price'] ?? 0);
  }

  double _readSalePrice(Map<String, dynamic> data) {
    final sale = _toDouble(data['salePrice']);
    final original = _readOriginalPrice(data);
    if (sale <= 0) return original;
    return sale;
  }

  void _calculateDiscount() {
    final original = double.tryParse(_originalPriceController.text.trim()) ?? 0;
    final sale = double.tryParse(_salePriceController.text.trim()) ?? 0;

    int discount = 0;
    if (original > 0 && sale > 0 && sale < original) {
      discount = (((original - sale) / original) * 100).round();
    }

    if (mounted) {
      setState(() {
        _discountPercent = discount;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;
    if (data != null) {
      _partController.text = (data['part'] ?? '').toString();
      _carModelController.text = _readCarModel(data);
      _descriptionController.text = (data['description'] ?? '').toString();
      _imageUrlController.text = (data['imageUrl'] ?? '').toString();
      _originalPriceController.text = _readOriginalPrice(data).toString();
      _salePriceController.text = _readSalePrice(data).toString();
      _stockController.text = _toInt(data['stock']).toString();

      final type = (data['type'] ?? 'Engine').toString();
      if (_types.contains(type)) {
        _selectedType = type;
      } else {
        _selectedType = 'Other';
      }
    }

    _originalPriceController.addListener(_calculateDiscount);
    _salePriceController.addListener(_calculateDiscount);
    _calculateDiscount();
  }

  @override
  void dispose() {
    _partController.dispose();
    _carModelController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _originalPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final originalPrice =
        double.tryParse(_originalPriceController.text.trim()) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = {
        'part': _partController.text.trim(),
        'car model': _carModelController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'type': _selectedType,
        'originalPrice': originalPrice,
        'salePrice': salePrice,
        'discountPercent': _discountPercent,
        'onSale': _discountPercent > 0,
        'stock': stock,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        final docRef = _partsCollection.doc(widget.documentId);
        final snapshot = await docRef.get();

        if (!snapshot.exists) {
          throw Exception('Document not found for update');
        }

        await docRef.update(payload);
      } else {
        await _partsCollection.add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Stock updated successfully' : 'Stock added successfully',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save stock item: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Stock' : 'Add Stock',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit
                          ? 'Update the stock item details'
                          : 'Add a new stock item to inventory',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _partController,
              decoration: _inputDecoration(
                'Part Name',
                Icons.build_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Part name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _carModelController,
              decoration: _inputDecoration(
                'Car Model',
                Icons.directions_car_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Car model is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration(
                'Type',
                Icons.category_outlined,
              ),
              items: _types.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(
                'Description',
                Icons.notes_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageUrlController,
              decoration: _inputDecoration(
                'Image URL',
                Icons.image_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Image URL is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Original Price',
                      Icons.payments_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Sale Price',
                      Icons.local_offer_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }

                      final sale = double.tryParse(value.trim());
                      if (sale == null) return 'Invalid';

                      final original =
                          double.tryParse(_originalPriceController.text.trim()) ??
                              0;

                      if (original > 0 && sale > original) {
                        return 'Must be <= original';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'Stock Quantity',
                Icons.numbers_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Stock is required';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Invalid stock';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _discountPercent > 0
                    ? Colors.red.withOpacity(0.08)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    _discountPercent > 0
                        ? Icons.local_fire_department_rounded
                        : Icons.price_check_rounded,
                    color: _discountPercent > 0
                        ? Colors.red
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _discountPercent > 0
                          ? 'Discount automatically calculated: $_discountPercent% OFF'
                          : 'No discount will be shown',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: _discountPercent > 0
                            ? Colors.red
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GradientButton(
              text: _isSaving
                  ? 'Saving...'
                  : isEdit
                      ? 'Update Stock Item'
                      : 'Add Stock Item',
              height: 54,
              borderRadius: 16,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}