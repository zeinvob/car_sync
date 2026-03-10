import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/location_service.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_bookings_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminWorkshopsBrowserPage extends StatefulWidget {
  const AdminWorkshopsBrowserPage({super.key});

  @override
  State<AdminWorkshopsBrowserPage> createState() =>
      _AdminWorkshopsBrowserPageState();
}

class _AdminWorkshopsBrowserPageState extends State<AdminWorkshopsBrowserPage> {
  final WorkshopService _workshopService = WorkshopService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'All';
  bool _sortNearby = false;
  bool _showMap = false;

  double? _userLat;
  double? _userLon;

  GoogleMapController? _mapController;
  Map<String, dynamic>? _selectedWorkshop;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (!mounted || position == null) return;

    setState(() {
      _userLat = position.latitude;
      _userLon = position.longitude;
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> workshops) {
    final query = _searchController.text.trim().toLowerCase();

    var result = workshops.where((workshop) {
      final name = (workshop['name'] ?? '').toString().toLowerCase();
      final address = (workshop['address'] ?? '').toString().toLowerCase();
      final phone = (workshop['phone'] ?? '').toString().toLowerCase();
      final description = (workshop['description'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          address.contains(query) ||
          phone.contains(query) ||
          description.contains(query);

      if (!matchesSearch) return false;

      if (_filter == 'Active') {
        return (workshop['isActive'] ?? false) == true;
      }

      if (_filter == 'Busy') {
        return ((workshop['bookingCount'] ?? 0) as int) > 0;
      }

      if (_filter == 'Available') {
        return ((workshop['bookingCount'] ?? 0) as int) == 0;
      }

      return true;
    }).toList();

    if (_sortNearby) {
      result.sort((a, b) {
        final aDistance = (a['distance'] as num?)?.toDouble() ?? 999999;
        final bDistance = (b['distance'] as num?)?.toDouble() ?? 999999;
        return aDistance.compareTo(bDistance);
      });
    } else {
      result.sort((a, b) {
        final aBookings = (a['bookingCount'] ?? 0) as int;
        final bBookings = (b['bookingCount'] ?? 0) as int;
        return bBookings.compareTo(aBookings);
      });
    }

    return result;
  }

  String _formatDistance(dynamic value) {
    if (value == null) return 'Distance unavailable';
    final distance = (value as num).toDouble();

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  BitmapDescriptor _markerColor(Map<String, dynamic> workshop) {
    final isActive = (workshop['isActive'] ?? false) == true;
    final bookingCount = (workshop['bookingCount'] ?? 0) as int;

    if (!isActive) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    if (bookingCount > 0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> workshops) {
    final markers = <Marker>{};

    for (final workshop in workshops) {
      final lat = (workshop['latitude'] as num?)?.toDouble();
      final lng = (workshop['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      final workshopId = (workshop['id'] ?? '').toString();
      final workshopName = (workshop['name'] ?? 'Workshop').toString();
      final bookingCount = (workshop['bookingCount'] ?? 0) as int;

      markers.add(
        Marker(
          markerId: MarkerId(workshopId),
          position: LatLng(lat, lng),
          icon: _markerColor(workshop),
          onTap: () {
            setState(() {
              _selectedWorkshop = workshop;
            });
          },
          infoWindow: InfoWindow(
            title: workshopName,
            snippet: '$bookingCount active bookings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkshopBookingsPage(
                    workshopId: workshopId,
                    workshopName: workshopName,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return markers;
  }

  LatLng _initialMapTarget(List<Map<String, dynamic>> workshops) {
    final firstWithLocation = workshops.cast<Map<String, dynamic>?>().firstWhere(
      (w) => w?['latitude'] != null && w?['longitude'] != null,
      orElse: () => null,
    );

    if (firstWithLocation != null) {
      return LatLng(
        (firstWithLocation['latitude'] as num).toDouble(),
        (firstWithLocation['longitude'] as num).toDouble(),
      );
    }

    if (_userLat != null && _userLon != null) {
      return LatLng(_userLat!, _userLon!);
    }

    return const LatLng(3.1390, 101.6869);
  }

  void _openWorkshop(Map<String, dynamic> workshop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkshopBookingsPage(
          workshopId: (workshop['id'] ?? '').toString(),
          workshopName: (workshop['name'] ?? 'Workshop').toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Workshops',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
                    hintText: 'Search workshop, address, phone...',
                    hintStyle: GoogleFonts.poppins(
                      color: onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: onSurface.withOpacity(0.65),
                    ),
                    filled: true,
                    fillColor: cardColor,
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
                        _filterChip('All'),
                        const SizedBox(width: 8),
                        _filterChip('Active'),
                        const SizedBox(width: 8),
                        _filterChip('Busy'),
                        const SizedBox(width: 8),
                        _filterChip('Available'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.near_me_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sort by Nearby Workshops',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                      ),
                      Switch(
                        value: _sortNearby,
                        onChanged: (value) {
                          setState(() => _sortNearby = value);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _viewToggleButton(
                          icon: Icons.view_list_rounded,
                          label: 'List',
                          selected: !_showMap,
                          onTap: () => setState(() => _showMap = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _viewToggleButton(
                          icon: Icons.map_outlined,
                          label: 'Map',
                          selected: _showMap,
                          onTap: () => setState(() => _showMap = true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _workshopService.getWorkshopList(
                userLat: _userLat,
                userLon: _userLon,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workshops = _applyFilters(snapshot.data ?? []);

                if (workshops.isEmpty) {
                  return Center(
                    child: Text(
                      'No workshops found.',
                      style: GoogleFonts.poppins(
                        color: onSurface.withOpacity(0.65),
                      ),
                    ),
                  );
                }

                if (_showMap) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _initialMapTarget(workshops),
                              zoom: 12,
                            ),
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            markers: _buildMarkers(workshops),
                            onTap: (_) {
                              setState(() {
                                _selectedWorkshop = null;
                              });
                            },
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                          ),
                          if (_selectedWorkshop != null)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: _buildSelectedWorkshopCard(
                                _selectedWorkshop!,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: workshops.length,
                  itemBuilder: (context, index) {
                    final workshop = workshops[index];
                    return _buildWorkshopRow(workshop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedWorkshopCard(Map<String, dynamic> workshop) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final name = (workshop['name'] ?? 'Workshop').toString();
    final address = (workshop['address'] ?? 'No address').toString();
    final distanceText = _formatDistance(workshop['distance']);
    final bookingCount = (workshop['bookingCount'] ?? 0) as int;
    final isActive = (workshop['isActive'] ?? false) == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.garage_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.4,
                    color: onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniTag(
                      isActive ? 'Active' : 'Inactive',
                      isActive ? Colors.green : Colors.grey,
                    ),
                    _miniTag('$bookingCount active', Colors.orange),
                    _miniTag(distanceText, AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _openWorkshop(workshop),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            child: Text(
              'Open',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkshopRow(Map<String, dynamic> workshop) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final imageUrl = (workshop['imageUrl'] ?? '').toString();
    final bookingCount = (workshop['bookingCount'] ?? 0) as int;
    final completedCount = (workshop['completedCount'] ?? 0) as int;
    final isActive = (workshop['isActive'] ?? false) == true;
    final rating = (workshop['rating'] ?? 0).toString();
    final distanceText = _formatDistance(workshop['distance']);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openWorkshop(workshop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 170,
                    width: double.infinity,
                    color: onSurface.withOpacity(0.06),
                    child: imageUrl.trim().isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.garage_outlined,
                                  size: 54,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.garage_outlined,
                              size: 54,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.92)
                            : Colors.grey.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (workshop['name'] ?? 'Workshop').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (workshop['address'] ?? 'No address').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.45,
                      color: onSurface.withOpacity(0.68),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoBadge(
                        Icons.phone_outlined,
                        (workshop['phone'] ?? 'No phone').toString(),
                      ),
                      _infoBadge(Icons.near_me_rounded, distanceText),
                      _infoBadge(
                        Icons.receipt_long_rounded,
                        '$bookingCount active bookings',
                      ),
                      _infoBadge(
                        Icons.task_alt_rounded,
                        '$completedCount completed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            (workshop['description'] ?? 'No description')
                                .toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              height: 1.4,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openWorkshop(workshop),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Open',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
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
                    color: AppColors.primary.withOpacity(0.18),
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
    );
  }
}