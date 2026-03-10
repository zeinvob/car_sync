import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class WorkshopMapPage extends StatefulWidget {
  const WorkshopMapPage({super.key});

  @override
  State<WorkshopMapPage> createState() => _WorkshopMapPageState();
}

class _WorkshopMapPageState extends State<WorkshopMapPage> {
  final WorkshopService _workshopService = WorkshopService();
  final MapController _mapController = MapController();
  
  List<Map<String, dynamic>> _workshops = [];
  List<Marker> _markers = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationError = false;
  String _errorMessage = '';
  
  // Default to Kuala Lumpur if location not available
  static const LatLng _defaultLocation = LatLng(3.1390, 101.6869);
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    await _getCurrentLocation();
    await _loadWorkshops();
    
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = true;
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = true;
            _errorMessage = 'Location permission denied.';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _locationError = false;
        _errorMessage = '';
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _locationError = true;
        _errorMessage = 'Could not get your location.';
      });
    }
  }

  Future<void> _loadWorkshops() async {
    try {
      final workshops = await _workshopService.getWorkshopList(
        userLat: _currentPosition?.latitude,
        userLon: _currentPosition?.longitude,
      );
      
      setState(() {
        _workshops = workshops.where((w) => w['isActive'] == true).toList();
        
        // Sort by distance if available
        _workshops.sort((a, b) {
          final distA = a['distance'] as double?;
          final distB = b['distance'] as double?;
          if (distA == null && distB == null) return 0;
          if (distA == null) return 1;
          if (distB == null) return -1;
          return distA.compareTo(distB);
        });
        
        _createMarkers();
      });
    } catch (e) {
      debugPrint('Error loading workshops: $e');
    }
  }

  void _createMarkers() {
    final List<Marker> markers = [];
    
    // Add user location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }
    
    // Add workshop markers
    for (final workshop in _workshops) {
      final lat = workshop['latitude'] as double?;
      final lon = workshop['longitude'] as double?;
      
      if (lat != null && lon != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showWorkshopDetails(workshop),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.car_repair,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    setState(() => _markers = markers);
  }

  void _showWorkshopDetails(Map<String, dynamic> workshop) {
    final distance = workshop['distance'] as double?;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            
            // Workshop image
            if (workshop['imageUrl'] != null && workshop['imageUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  workshop['imageUrl'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.car_repair, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Workshop name
            Text(
              workshop['name'] ?? 'Workshop',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workshop['address'] ?? 'No address',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Distance
            if (distance != null)
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            
            // Rating
            Row(
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${(workshop['rating'] ?? 0).toStringAsFixed(1)} rating',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Book Now button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, workshop); // Return selected workshop
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Book This Workshop',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToUserLocation() {
    if (_currentPosition == null) return;
    
    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      14,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Nearby Workshops',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // OpenStreetMap (FREE - No API key needed!)
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 12,
                  ),
                  children: [
                    // OpenStreetMap Tiles (FREE!)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.carsync.app',
                    ),
                    // Markers
                    MarkerLayer(markers: _markers),
                  ],
                ),
                
                // Error banner
                if (_locationError)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange.withValues(alpha: 0.9),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _getCurrentLocation,
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Nearby workshops list
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      itemCount: _workshops.length,
                      itemBuilder: (context, index) {
                        final workshop = _workshops[index];
                        return _buildWorkshopCard(workshop);
                      },
                    ),
                  ),
                ),
                
                // My location button
                Positioned(
                  right: 16,
                  bottom: 180,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _goToUserLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWorkshopCard(Map<String, dynamic> workshop) {
    final distance = workshop['distance'] as double?;
    
    return GestureDetector(
      onTap: () {
        final lat = workshop['latitude'] as double?;
        final lon = workshop['longitude'] as double?;
        
        if (lat != null && lon != null) {
          _mapController.move(LatLng(lat, lon), 15);
        }
        
        _showWorkshopDetails(workshop);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workshop image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: workshop['imageUrl'] != null && workshop['imageUrl'].toString().isNotEmpty
                  ? Image.network(
                      workshop['imageUrl'],
                      height: 70,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 70,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.car_repair, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      height: 70,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(Icons.car_repair, color: AppColors.primary),
                      ),
                    ),
            ),
            
            // Workshop info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workshop['name'] ?? 'Workshop',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (distance != null) ...[
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${(workshop['rating'] ?? 0).toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
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
    );
  }
}
