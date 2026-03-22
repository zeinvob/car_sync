import 'dart:io';

import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ManageWorkshopsPage extends StatefulWidget {
  const ManageWorkshopsPage({super.key});

  @override
  State<ManageWorkshopsPage> createState() => _ManageWorkshopsPageState();
}

class _ManageWorkshopsPageState extends State<ManageWorkshopsPage> {
  final WorkshopService _workshopService = WorkshopService();
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWorkshopForm({Map<String, dynamic>? workshop}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkshopFormSheet(workshop: workshop),
    );
  }

  Future<void> _deleteWorkshop(Map<String, dynamic> workshop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return AlertDialog(
          title: Text(
            'Delete Workshop',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${workshop['name']}"?',
            style: GoogleFonts.poppins(color: onSurface.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _workshopService.deleteWorkshop(
      workshopId: workshop['id'].toString(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workshop deleted')));
  }

  List<Map<String, dynamic>> _applySearchAndFilter(
    List<Map<String, dynamic>> workshops,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    var result = workshops.where((w) {
      final name = (w['name'] ?? '').toString().toLowerCase();
      final address = (w['address'] ?? '').toString().toLowerCase();
      final phone = (w['phone'] ?? '').toString().toLowerCase();
      final description = (w['description'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          address.contains(query) ||
          phone.contains(query) ||
          description.contains(query);

      if (!matchesSearch) return false;

      final isActive = (w['isActive'] ?? false) == true;

      if (_filter == 'Active') return isActive;
      if (_filter == 'Inactive') return !isActive;

      return true;
    }).toList();

    result.sort((a, b) {
      final aCreated = a['createdAt'] is Timestamp
          ? (a['createdAt'] as Timestamp).toDate()
          : DateTime(1970);
      final bCreated = b['createdAt'] is Timestamp
          ? (b['createdAt'] as Timestamp).toDate()
          : DateTime(1970);
      return bCreated.compareTo(aCreated);
    });

    return result;
  }

  Widget _buildWorkshopImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 170,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.garage_outlined, size: 44, color: Colors.white),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 170,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 170,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'Manage Workshops',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _openWorkshopForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Workshop',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(color: onSurface),
                  decoration: InputDecoration(
                    hintText: "Search workshop, address, phone...",
                    hintStyle: GoogleFonts.poppins(
                      color: onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: onSurface.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _filterChip("All"),
                        const SizedBox(width: 8),
                        _filterChip("Active"),
                        const SizedBox(width: 8),
                        _filterChip("Inactive"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('workshops')
                  .orderBy('createdAt', descending: true)
                  .snapshots()
                  .map((snapshot) {
                    return snapshot.docs.map((doc) {
                      final data = doc.data();
                      return {
                        'id': doc.id,
                        'name': (data['name'] ?? '').toString(),
                        'address': (data['address'] ?? '').toString(),
                        'description': (data['description'] ?? '').toString(),
                        'imageUrl': (data['imageUrl'] ?? '').toString(),
                        'phone': (data['phone'] ?? '').toString(),
                        'openingHours': (data['openingHours'] ?? '').toString(),
                        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
                        'latitude': (data['latitude'] as num?)?.toDouble(),
                        'longitude':
                            (data['longitude'] as num?)?.toDouble() ??
                            (data['longtitude'] as num?)?.toDouble(),
                        'isActive': (data['isActive'] ?? true) == true,
                        'createdAt': data['createdAt'],
                        'updatedAt': data['updatedAt'],
                      };
                    }).toList();
                  }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final raw = snapshot.data ?? [];
                final workshops = _applySearchAndFilter(raw);

                if (workshops.isEmpty) {
                  return Center(
                    child: Text(
                      'No workshops found.',
                      style: GoogleFonts.poppins(
                        color: onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: workshops.length,
                  itemBuilder: (context, index) {
                    final workshop = workshops[index];
                    final isActive = (workshop['isActive'] ?? false) == true;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWorkshopImage(
                            (workshop['imageUrl'] ?? '').toString(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        workshop['name']?.toString() ??
                                            'Workshop',
                                        style: GoogleFonts.poppins(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withOpacity(0.10)
                                            : Colors.grey.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: isActive
                                              ? Colors.green.withOpacity(0.20)
                                              : Colors.grey.withOpacity(0.20),
                                        ),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isActive
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  workshop['description']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: onSurface.withOpacity(0.72),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _infoText(
                                  Icons.location_on_outlined,
                                  workshop['address']?.toString() ?? '-',
                                  onSurface,
                                ),
                                _infoText(
                                  Icons.phone_outlined,
                                  workshop['phone']?.toString() ?? '-',
                                  onSurface,
                                ),
                                _infoText(
                                  Icons.access_time_outlined,
                                  workshop['openingHours']?.toString() ?? '-',
                                  onSurface,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openWorkshopForm(
                                          workshop: workshop,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: Text(
                                          'Edit',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _deleteWorkshop(workshop),
                                        icon: const Icon(Icons.delete_outline),
                                        label: Text(
                                          'Delete',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoText(IconData icon, String text, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: onSurface.withOpacity(0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filter = label),
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.primary.withOpacity(0.20),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkshopFormSheet extends StatefulWidget {
  final Map<String, dynamic>? workshop;

  const WorkshopFormSheet({super.key, this.workshop});

  @override
  State<WorkshopFormSheet> createState() => _WorkshopFormSheetState();
}

class _WorkshopFormSheetState extends State<WorkshopFormSheet> {
  final WorkshopService _workshopService = WorkshopService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ratingController;
  late final TextEditingController _imageUrlController;

  bool _isActive = true;
  bool _isSaving = false;
  String _imageUrl = '';

  double? _latitude;
  double? _longitude;

  late String _selectedOpenTime;
  late String _selectedCloseTime;

  bool get _isEdit => widget.workshop != null;

  List<String> get _timeSlots {
    final List<String> slots = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final dt = DateTime(2026, 1, 1, hour, minute);
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        slots.add('$h:$m $period');
      }
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();

    final data = widget.workshop ?? {};

    _nameController = TextEditingController(text: data['name']?.toString() ?? '');
    _addressController = TextEditingController(text: data['address']?.toString() ?? '');
    _descriptionController = TextEditingController(text: data['description']?.toString() ?? '');
    _phoneController = TextEditingController(text: data['phone']?.toString() ?? '');
    _ratingController = TextEditingController(text: data['rating']?.toString() ?? '4.5');
    _imageUrlController = TextEditingController(
      text: data['imageUrl']?.toString() ?? '',
    );

    _isActive = (data['isActive'] ?? true) == true;
    _imageUrl = data['imageUrl']?.toString() ?? '';
    _latitude = (data['latitude'] as num?)?.toDouble();
    _longitude = (data['longitude'] as num?)?.toDouble();

    final openingRaw =
        (data['openingHours']?.toString() ?? '9:00 AM - 5:00 PM').split('-');

    _selectedOpenTime =
        openingRaw.isNotEmpty ? openingRaw.first.trim() : '9:00 AM';
    _selectedCloseTime =
        openingRaw.length > 1 ? openingRaw.last.trim() : '5:00 PM';

    if (!_timeSlots.contains(_selectedOpenTime)) {
      _selectedOpenTime = '9:00 AM';
    }
    if (!_timeSlots.contains(_selectedCloseTime)) {
      _selectedCloseTime = '5:00 PM';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _ratingController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkshopLocationPickerPage(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (picked == null) return;

    _latitude = picked.latitude;
    _longitude = picked.longitude;

    try {
      final places = await placemarkFromCoordinates(
        picked.latitude,
        picked.longitude,
      );

      if (places.isNotEmpty) {
        final p = places.first;
        final parts = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

        _addressController.text = parts.join(', ');
      }
    } catch (_) {}

    setState(() {});
  }

  Widget _buildPreview() {
    if (_imageUrl.trim().isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.garage_outlined,
          size: 42,
          color: Colors.white,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        _imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }

  Future<void> _saveWorkshop() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick the workshop location')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'openingHours': '$_selectedOpenTime - $_selectedCloseTime',
        'rating': double.tryParse(_ratingController.text.trim()) ?? 0.0,
        'latitude': _latitude,
        'longitude': _longitude,
        'imageUrl': _imageUrlController.text.trim(),
        'isActive': _isActive,
      };

      if (_isEdit) {
        await _workshopService.updateWorkshop(
          workshopId: widget.workshop!['id'].toString(),
          data: payload,
        );
      } else {
        await _workshopService.addWorkshop(data: payload);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Workshop updated' : 'Workshop added'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isEdit ? 'Edit Workshop' : 'Add Workshop',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreview(),
              const SizedBox(height: 12),
              _buildField(
                _imageUrlController,
                'Workshop Image URL',
                keyboardType: TextInputType.url,
                required: false,
                onChanged: (value) {
                  setState(() {
                    _imageUrl = value.trim();
                  });
                },
              ),
              _buildField(_nameController, 'Workshop Name'),
              _buildField(_descriptionController, 'Description', maxLines: 3),
              _buildField(
                _phoneController,
                'Phone',
                keyboardType: TextInputType.phone,
              ),
              _buildField(
                _ratingController,
                'Rating',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 4),
              _buildSectionCard(
                title: 'Opening Hours',
                icon: Icons.access_time_rounded,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Open',
                        value: _selectedOpenTime,
                        items: _timeSlots,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedOpenTime = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Close',
                        value: _selectedCloseTime,
                        items: _timeSlots,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCloseTime = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Workshop Location',
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openMapPicker,
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.map_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap to pick workshop location from map',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please choose a location from the map';
                        }
                        return null;
                      },
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Address',
                        labelStyle: GoogleFonts.poppins(),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.08),
                          ),
                        ),
                      ),
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _miniInfo(
                              'Latitude',
                              _latitude!.toStringAsFixed(6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _miniInfo(
                              'Longitude',
                              _longitude!.toStringAsFixed(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.toggle_on_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Workshop Active',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      activeColor: AppColors.primary,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWorkshop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Add Workshop',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
      ),
      items: items.map((time) {
        return DropdownMenuItem<String>(
          value: time,
          child: Text(
            time,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _miniInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.poppins(),
        validator: (value) {
          if (!required) return null;
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class WorkshopLocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const WorkshopLocationPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<WorkshopLocationPickerPage> createState() =>
      _WorkshopLocationPickerPageState();
}

class _WorkshopLocationPickerPageState
    extends State<WorkshopLocationPickerPage> {
  static const LatLng _bukitJalilDefault = LatLng(3.0570, 101.6900);

  late LatLng _picked;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _picked = LatLng(
      widget.initialLat ?? _bukitJalilDefault.latitude,
      widget.initialLng ?? _bukitJalilDefault.longitude,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _zoomIn() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _goToPickedLocation() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _picked, zoom: 16),
      ),
    );
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await locationFromAddress(query);

      if (results.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
        return;
      }

      final first = results.first;
      final latLng = LatLng(first.latitude, first.longitude);

      setState(() {
        _picked = latLng;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pick Workshop Location',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _picked,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _picked,
              ),
            },
            onTap: (latLng) {
              setState(() {
                _picked = latLng;
              });
            },
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            mapToolbarEnabled: true,
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchPlace(),
                        style: GoogleFonts.poppins(color: onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search place or address',
                          hintStyle: GoogleFonts.poppins(
                            color: onSurface.withOpacity(0.55),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _isSearching
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: _searchPlace,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 100,
            child: Column(
              children: [
                _mapActionButton(
                  icon: Icons.add,
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 10),
                _mapActionButton(
                  icon: Icons.remove,
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 10),
                _mapActionButton(
                  icon: Icons.my_location,
                  onTap: _goToPickedLocation,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _picked),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Use This Location',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}