import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/sparepart_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SparePartsPage extends StatefulWidget {
  const SparePartsPage({super.key});

  @override
  State<SparePartsPage> createState() => _SparePartsPageState();
}

class _SparePartsPageState extends State<SparePartsPage> {
  final SparePartService _sparePartService = SparePartService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allParts = [];
  List<Map<String, dynamic>> _filteredParts = [];
  bool _isLoading = true;
  String _selectedType = 'All';

  final List<String> _types = ['All', 'Engine', 'Brake', 'Suspension', 'Electrical', 'Body', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpareParts() async {
    setState(() => _isLoading = true);
    try {
      final parts = await _sparePartService.getAllSpareParts();
      if (mounted) {
        setState(() {
          _allParts = parts;
          _filteredParts = parts;
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
        final matchesSearch = query.isEmpty ||
            (part['part'] ?? '').toString().toLowerCase().contains(query) ||
            (part['car_model'] ?? '').toString().toLowerCase().contains(query) ||
            (part['description'] ?? '').toString().toLowerCase().contains(query);

        final matchesType = _selectedType == 'All' ||
            (part['type'] ?? '').toString().toLowerCase() == _selectedType.toLowerCase();

        return matchesSearch && matchesType;
      }).toList();
    });
  }

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(),
            ),
          ),

          // Type Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      type,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedType = type);
                      _filterParts();
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Parts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredParts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSpareParts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
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
            'Try adjusting your search or filter',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(Map<String, dynamic> part) {
    final partName = part['part'] ?? 'Unknown Part';
    final carModel = part['car_model'] ?? '';
    final description = part['description'] ?? '';
    final price = part['price'] ?? 0;
    final stock = part['stock'] ?? 0;
    final type = part['type'] ?? '';
    final imageUrl = part['imageUrl'] ?? '';

    final isInStock = stock > 0;

    return Container(
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
      child: InkWell(
        onTap: () => _showPartDetails(part),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            _getTypeIcon(type),
                            color: _getTypeColor(type),
                            size: 28,
                          ),
                        )
                      : Icon(
                          _getTypeIcon(type),
                          color: _getTypeColor(type),
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Part Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (carModel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        carModel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        Text(
                          'RM ${price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        // Stock Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isInStock
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isInStock ? 'In Stock ($stock)' : 'Out of Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isInStock ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _PartDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> part;

  const _PartDetailsSheet({required this.part});

  @override
  Widget build(BuildContext context) {
    final partName = part['part'] ?? 'Unknown Part';
    final carModel = part['car_model'] ?? 'Universal';
    final description = part['description'] ?? 'No description available';
    final price = part['price'] ?? 0;
    final stock = part['stock'] ?? 0;
    final type = part['type'] ?? 'Other';
    final imageUrl = part['imageUrl'] ?? '';
    final isInStock = stock > 0;

    return Container(
      padding: const EdgeInsets.all(24),
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
          _buildDetailRow(Icons.directions_car, 'Compatible with', carModel),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.description_outlined, 'Description', description),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.inventory_2_outlined,
            'Availability',
            isInStock ? 'In Stock ($stock available)' : 'Out of Stock',
            valueColor: isInStock ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),

          // Price
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isInStock
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contact workshop to order $partName'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(
                'Enquire Now',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
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
