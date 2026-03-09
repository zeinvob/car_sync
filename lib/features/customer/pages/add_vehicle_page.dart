import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddVehiclePage extends StatefulWidget {
  final Map<String, dynamic>? existingVehicle; // For edit mode

  const AddVehiclePage({super.key, this.existingVehicle});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  final _authService = AuthService();

  // Controllers
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedTransmission = 'Automatic';
  String _selectedFuelType = 'Petrol';
  bool _isLoading = false;

  final List<String> _transmissions = ['Automatic', 'Manual'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Hybrid', 'Electric'];

  // Popular car brands
  final List<String> _popularBrands = [
    'Toyota', 'Honda', 'Nissan', 'Mazda', 'Mitsubishi',
    'Ford', 'Chevrolet', 'BMW', 'Mercedes-Benz', 'Audi',
    'Volkswagen', 'Hyundai', 'Kia', 'Suzuki', 'Proton', 'Perodua',
  ];

  bool get _isEditMode => widget.existingVehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final vehicle = widget.existingVehicle!;
    _brandController.text = vehicle['brand'] ?? '';
    _modelController.text = vehicle['model'] ?? '';
    _yearController.text = vehicle['year'] ?? '';
    _plateController.text = vehicle['plateNumber'] ?? '';
    _colorController.text = vehicle['color'] ?? '';
    _notesController.text = vehicle['notes'] ?? '';
    _selectedTransmission = vehicle['transmission'] ?? 'Automatic';
    _selectedFuelType = vehicle['fuelType'] ?? 'Petrol';
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in');
      }

      if (_isEditMode) {
        // Update existing vehicle
        await _vehicleService.updateVehicle(
          vehicleId: widget.existingVehicle!['id'],
          data: {
            'brand': _brandController.text.trim(),
            'model': _modelController.text.trim(),
            'year': _yearController.text.trim(),
            'plateNumber': _plateController.text.trim().toUpperCase(),
            'color': _colorController.text.trim(),
            'transmission': _selectedTransmission,
            'fuelType': _selectedFuelType,
            'notes': _notesController.text.trim(),
          },
        );
      } else {
        // Add new vehicle
        await _vehicleService.addVehicle(
          customerId: currentUser.uid,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          year: _yearController.text.trim(),
          plateNumber: _plateController.text.trim(),
          color: _colorController.text.trim(),
          transmission: _selectedTransmission,
          fuelType: _selectedFuelType,
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Vehicle updated!' : 'Vehicle added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Vehicle' : 'Add Vehicle',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car icon header
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Brand field with suggestions
              _buildSectionTitle('Vehicle Information'),
              const SizedBox(height: 12),

              // Brand
              _buildLabel('Brand *'),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) {
                    return _popularBrands;
                  }
                  return _popularBrands.where((brand) =>
                      brand.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _brandController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  // Sync with our controller
                  if (_brandController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _brandController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: _inputDecoration('e.g., Toyota, Honda'),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Brand is required' : null,
                    onChanged: (val) => _brandController.text = val,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Model
              _buildLabel('Model *'),
              TextFormField(
                controller: _modelController,
                decoration: _inputDecoration('e.g., Camry, Civic'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Model is required' : null,
              ),
              const SizedBox(height: 16),

              // Year and Color row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Year *'),
                        TextFormField(
                          controller: _yearController,
                          decoration: _inputDecoration('e.g., 2022'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            final year = int.tryParse(value!);
                            if (year == null || year < 1900 || year > 2030) {
                              return 'Invalid year';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Color'),
                        TextFormField(
                          controller: _colorController,
                          decoration: _inputDecoration('e.g., White'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Plate Number
              _buildLabel('Plate Number *'),
              TextFormField(
                controller: _plateController,
                decoration: _inputDecoration('e.g., ABC 1234'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    value?.isEmpty == true ? 'Plate number is required' : null,
              ),
              const SizedBox(height: 24),

              // Transmission & Fuel Type
              _buildSectionTitle('Specifications'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Transmission'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTransmission,
                              isExpanded: true,
                              items: _transmissions.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t, style: GoogleFonts.poppins(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedTransmission = value!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Fuel Type'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFuelType,
                              isExpanded: true,
                              items: _fuelTypes.map((f) {
                                return DropdownMenuItem(
                                  value: f,
                                  child: Text(f, style: GoogleFonts.poppins(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedFuelType = value!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              _buildLabel('Notes (Optional)'),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('Any additional notes about your vehicle'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update Vehicle' : 'Add Vehicle',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[400],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
