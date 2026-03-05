import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/storage_service.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_bookings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/features/auth/pages/login_form_page.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android icons white
        statusBarBrightness: Brightness.dark, // iOS icons white
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const _SimplePage(title: "Bookings Page"),
      const _SimplePage(title: "Services Page"),
      const _SimplePage(title: "Stock Page"),
      const _SimplePage(title: "Profile Page"),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          pages[_selectedIndex],

          if (_isSigningOut)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: _buildGradientBottomNav(),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        _buildTopHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 20),

                _buildSectionTitle("RECENTLY ADDED"),
                const SizedBox(height: 12),
                _buildRecentlyAddedSection(),

                const SizedBox(height: 24),
                _buildSectionTitle("WORKSHOP"),
                const SizedBox(height: 12),
                _buildWorkshopSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- TOP HEADER ----------------

  Widget _buildTopHeader() {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, top + 10, 18, 14), // top + your spacing
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          ),
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                "CS",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _isSigningOut ? null : _handleSignOut,
              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HERO BANNER ----------------

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Opacity(
                opacity: 0.18,
                child: Image.network(
                  "https://images.unsplash.com/photo-1503376780353-7e6692767b70",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Admin Home",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage spare parts, workshops, and bookings in one place.",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "View Details",
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTION TITLE ----------------

  Widget _buildSectionTitle(String title) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ---------------- RECENTLY ADDED ----------------

  Widget _buildRecentlyAddedSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storageService.getRecentSpareParts(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (items.isEmpty) {
          return _buildEmptyMessage("No spare parts found.");
        }

        return SizedBox(
          height: 290,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildProductCard(
                title: item['part'] ?? 'No Part',
                subtitle: item['car_model'] ?? 'No Model',
                price: "RM ${item['price'] ?? 0}",
                stock: item['stock'] ?? 0,
                onTap: () {},
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- WORKSHOP ----------------

  Widget _buildWorkshopSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storageService.getWorkshopList(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (items.isEmpty) {
          return _buildEmptyMessage("No workshops found.");
        }

        return SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];

              return _buildWorkshopCard(
                title: item['name'] ?? 'Workshop',
                subtitle: item['address'] ?? 'No address',
                bookingCount: item['bookingCount'] ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkshopBookingsPage(
                        workshopId: item['id'],
                        workshopName: item['name'] ?? 'Workshop',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- PRODUCT CARD ----------------

  Widget _buildProductCard({
    required String title,
    required String subtitle,
    required String price,
    required int stock,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final lowStock = stock <= 5;

    return Container(
      width: 195, // ✅ same as workshop card
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 110, // ✅ same as workshop card
            width: double.infinity,
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.build_circle_outlined, // ✅ product icon
              size: 46,
              color: AppColors.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2, // ✅ same style as workshop
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ Badge like workshop card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lowStock ? "Low Stock: $stock" : "Stock: $stock",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: lowStock ? Colors.red : onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ✅ Price line under badge (still clean)
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            child: GradientButton(
              text: "Add",
              height: 45,
              borderRadius: 12,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- WORKSHOP CARD ----------------

  Widget _buildWorkshopCard({
    required String title,
    required String subtitle,
    required int bookingCount,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: 195,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.garage_outlined,
              size: 46,
              color: AppColors.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$bookingCount bookings",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            child: GradientButton(
              text: "Open",
              height: 45,
              borderRadius: 12,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- EMPTY ----------------

  Widget _buildEmptyMessage(String text) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(color: onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }

  // ---------------- GRADIENT BOTTOM NAV ----------------

  Widget _buildGradientBottomNav() {
    final items = [
      Icons.home_outlined,
      Icons.calendar_today_outlined,
      Icons.build_outlined,
      Icons.inventory_2_outlined,
      Icons.shopping_cart_outlined,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.4,
                ),
              ),
              child: Icon(
                items[index],
                color: isSelected ? AppColors.primary : Colors.white,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------- SIGN OUT ----------------

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginFormPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Sign out failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  const _SimplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
      ),
    );
  }
}
