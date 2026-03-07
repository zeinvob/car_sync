import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/storage_service.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_bookings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/features/auth/pages/login_form_page.dart';
import 'package:car_sync/core/theme/theme_controller.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/features/admin/presentation/pages/notifications_page.dart';
import 'dart:async';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  int _activeBookingsCount = 0;
  StreamSubscription<int>? _activeBookingsSubscription;
  int _unreadNotificationCount = 0;
  int _unreadBookingCount = 0;
  StreamSubscription<int>? _notificationCountSubscription;
  StreamSubscription<int>? _bookingCountSubscription;
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  int _selectedIndex = 0;
  String _adminName = 'Admin';
  String _adminEmail = '';
  bool _isLoadingAdmin = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _listenToActiveBookingsCount() {
    _activeBookingsSubscription?.cancel();

    _activeBookingsSubscription = _storageService
        .getActiveBookingsCountStream()
        .listen((count) {
          if (mounted) {
            setState(() {
              _activeBookingsCount = count;
            });
          }
        });
  }

  @override
  void initState() {
    super.initState();
    _listenToNotificationCounts();
    _listenToActiveBookingsCount();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _loadAdminData();
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel();
    _bookingCountSubscription?.cancel();
    _activeBookingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoadingAdmin = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userData = await _storageService.getUserData(user.uid);

        setState(() {
          _adminName =
              userData?['name'] ??
              userData?['fullName'] ??
              userData?['username'] ??
              user.displayName ??
              'Admin';
          _adminEmail = userData?['email'] ?? user.email ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAdmin = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const _SimplePage(title: "Bookings Page"),
      const _SimplePage(title: "Services Page"),
      const _SimplePage(title: "Stock Page"),
      const _SimplePage(title: "Parts Order Page"),
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildAdminDrawer(),
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
      ),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        _buildTopHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAdminData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("QUICK ACTIONS"),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
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
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, top + 10, 18, 14),
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
          // Drawer menu button
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          ),

          // App logo in the center
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/logo/white_carsync.png',
                height: 43,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Notification button on the right
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Notifications',
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : '$_unreadNotificationCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildAdminDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                "Admin Menu",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Divider(height: 1),

            // Profile section
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                "Profile",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: _adminEmail.isNotEmpty
                  ? Text(
                      _adminEmail,
                      style: GoogleFonts.poppins(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                );
              },
            ),

            const Divider(height: 1),

            // Theme switch
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.themeMode,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;

                return SwitchListTile(
                  title: Text(
                    "Dark mode",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: isDark,
                  onChanged: (val) {
                    ThemeController.toggleTheme();
                  },
                );
              },
            ),

            const Divider(height: 1),

            // Sign out option
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(
                "Sign out",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _handleSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
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
                opacity: 0.22,
                child: Image.network(
                  "https://images.unsplash.com/photo-1503376780353-7e6692767b70",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(
                      _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _isLoadingAdmin
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _adminName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Welcome back! Manage bookings, services, stock, and parts easily.",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildBookingsActionCard()),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.build_outlined,
                  label: 'Services',
                  color: Colors.orange,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock',
                  color: Colors.teal,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Parts Order',
                  color: Colors.deepPurple,
                  onTap: () {
                    setState(() => _selectedIndex = 4);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsActionCard() {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = 1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bookings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (_activeBookingsCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _activeBookingsCount > 99 ? '99+' : '$_activeBookingsCount',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              Icons.build_circle_outlined,
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
                    lowStock ? "Low Stock: $stock" : "Stock: $stock",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: lowStock ? Colors.red : onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
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
  maxLines: 1,
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
          const SizedBox(height: 10),
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

  Widget _buildGradientBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.calendar_today_outlined,
        'activeIcon': Icons.calendar_today,
        'label': 'Bookings',
      },
      {
        'icon': Icons.build_outlined,
        'activeIcon': Icons.build,
        'label': 'Services',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'activeIcon': Icons.inventory_2,
        'label': 'Stock',
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart,
        'label': 'Parts',
      },
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
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
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 58,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected
                              ? items[index]['activeIcon'] as IconData
                              : items[index]['icon'] as IconData,
                          color: isSelected ? AppColors.primary : Colors.white,
                          size: 22,
                        ),
                        if (index == 1 && _activeBookingsCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _activeBookingsCount > 99
                                    ? '99+'
                                    : '$_activeBookingsCount',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index]['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

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

  // Notification handling
  void _listenToNotificationCounts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationCountSubscription?.cancel();
    _bookingCountSubscription?.cancel();

    _notificationCountSubscription = _notificationService
        .unreadNotificationCountStream(role: 'admin', currentUserId: user.uid)
        .listen((count) {
          if (mounted) {
            setState(() {
              _unreadNotificationCount = count;
            });
          }
        });

    _bookingCountSubscription = _notificationService
        .unreadBookingNotificationCountStream(
          role: 'admin',
          currentUserId: user.uid,
        )
        .listen((count) {
          if (mounted) {
            setState(() {
              _unreadBookingCount = count;
            });
          }
        });
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  const _SimplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: Center(
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
