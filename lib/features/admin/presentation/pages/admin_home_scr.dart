import 'dart:async';
import 'dart:convert';

import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/services/booking_service.dart';
import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/core/services/sparepart_service.dart';
import 'package:car_sync/core/services/user_service.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:car_sync/core/theme/admin_theme_controller.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_chat_inbox_page.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_profile_page.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_workshops_browser_page.dart';
import 'package:car_sync/features/admin/presentation/pages/manage_workshops_page.dart';
import 'package:car_sync/features/admin/presentation/pages/notifications_page.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_bookings_page.dart';
import 'package:car_sync/features/auth/pages/login_form_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService.instance;
  final BookingService _bookingService = BookingService();
  final UserService _userService = UserService();
  final SparePartService _sparePartService = SparePartService();
  final WorkshopService _workshopService = WorkshopService();
  final AuthService _authService = AuthService();

  int _activeBookingsCount = 0;
  int _unreadNotificationCount = 0;
  int _unreadBookingCount = 0;
  int _unreadChatCount = 0;

  StreamSubscription<int>? _activeBookingsSubscription;
  StreamSubscription<int>? _notificationCountSubscription;
  StreamSubscription<int>? _bookingCountSubscription;
  StreamSubscription<int>? _chatCountSubscription;

  bool _isSigningOut = false;
  bool _isLoadingAdmin = true;
  int _selectedIndex = 0;

  String _adminName = 'Admin';
  String _adminEmail = '';
  String _adminProfileImageUrl = '';

  Timer? _chatRefreshTimer;
  Timer? _homeRefreshTimer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _listenToNotificationCounts();
    _listenToActiveBookingsCount();
    _listenToUnreadChatCount();
    _startChatCountAutoRefresh();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _loadAdminData();
    _startHomeAutoRefresh();
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel();
    _bookingCountSubscription?.cancel();
    _activeBookingsSubscription?.cancel();
    _chatCountSubscription?.cancel();
    _chatRefreshTimer?.cancel();
    _homeRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listenToUnreadChatCount();
      _refreshHomeData();
    }
  }

  void _listenToActiveBookingsCount() {
    _activeBookingsSubscription?.cancel();

    _activeBookingsSubscription = _bookingService
        .getActiveBookingsCountStream()
        .listen((count) {
          if (mounted) {
            setState(() {
              _activeBookingsCount = count;
            });
          }
        });
  }

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

  void _listenToUnreadChatCount() {
    _chatCountSubscription?.cancel();

    _chatCountSubscription = _workshopService
        .unreadCustomerMessagesCountStream()
        .listen(
          (count) {
            debugPrint('Live unread chat count: $count');
            if (mounted) {
              setState(() {
                _unreadChatCount = count;
              });
            }
          },
          onError: (error) {
            debugPrint('Unread chat stream error: $error');
          },
        );
  }

  Future<void> _refreshUnreadChatCountOnce() async {
    try {
      final count = await _workshopService.getUnreadCustomerMessagesCountOnce();

      if (mounted) {
        setState(() {
          _unreadChatCount = count;
        });
      }
    } catch (e) {
      debugPrint('Refresh unread chat count failed: $e');
    }
  }

  void _startChatCountAutoRefresh() {
    _chatRefreshTimer?.cancel();

    _chatRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshUnreadChatCountOnce();
    });
  }

  void _startHomeAutoRefresh() {
    _homeRefreshTimer?.cancel();

    _homeRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _refreshHomeData();
    });
  }

  Future<void> _refreshHomeData() async {
    await _loadAdminData();
    await _refreshUnreadChatCountOnce();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAdminData() async {
    if (mounted) {
      setState(() => _isLoadingAdmin = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userData = await _userService.getUserData(user.uid);

        if (!mounted) return;

        setState(() {
          _adminName =
              userData?['name'] ??
              userData?['fullName'] ??
              userData?['username'] ??
              user.displayName ??
              'Admin';

          _adminEmail = userData?['email'] ?? user.email ?? '';

          _adminProfileImageUrl = (userData?['profileImageUrl'] ?? '')
              .toString();
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
      const AdminWorkshopsBrowserPage(),
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
            onRefresh: _refreshHomeData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(),
                  const SizedBox(height: 18),
                  _buildDashboardStats(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    "Quick Actions",
                    subtitle: "Manage your workshop faster",
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    "Recently Added Parts",
                    subtitle: "Latest inventory items in stock",
                  ),
                  const SizedBox(height: 12),
                  _buildRecentlyAddedSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    "Workshop Overview",
                    subtitle: "View active workshops only",
                  ),
                  const SizedBox(height: 12),
                  _buildWorkshopSection(),
                  const SizedBox(height: 28),
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
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/logo/white_carsync.png',
                height: 43,
                fit: BoxFit.contain,
              ),
            ),
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
              onTap: () async {
                Navigator.pop(context);
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                );

                if (updated == true) {
                  _loadAdminData();
                }
              },
            ),
            const Divider(height: 1),
            ValueListenableBuilder<bool>(
              valueListenable: AdminThemeController.isDark,
              builder: (context, isDark, _) {
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
                    AdminThemeController.setTheme(val);
                  },
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded),
                  if (_unreadChatCount > 0)
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
                          _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
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
              title: Text(
                "Customer Chats",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminChatInboxPage()),
                );

                if (changed == true) {
                  await _refreshUnreadChatCountOnce();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.garage_outlined),
              title: Text(
                "Manage Workshops",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageWorkshopsPage(),
                  ),
                );

                await _refreshHomeData();
              },
            ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                "https://images.unsplash.com/photo-1503376780353-7e6692767b70",
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D1B4C).withOpacity(0.88),
                      AppColors.gradientStart.withOpacity(0.72),
                      AppColors.gradientEnd.withOpacity(0.99),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -15,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -25,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _adminProfileImageUrl.trim().isNotEmpty
                              ? Builder(
                                  builder: (context) {
                                    try {
                                      return Image.memory(
                                        base64Decode(_adminProfileImageUrl),
                                        fit: BoxFit.cover,
                                      );
                                    } catch (e) {
                                      return Center(
                                        child: Text(
                                          _adminName.isNotEmpty
                                              ? _adminName[0].toUpperCase()
                                              : 'A',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : Center(
                                  child: Text(
                                    _adminName.isNotEmpty
                                        ? _adminName[0].toUpperCase()
                                        : 'A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _isLoadingAdmin
                            ? const SizedBox(
                                height: 26,
                                width: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.20),
                                      ),
                                    ),
                                    child: Text(
                                      "Admin Dashboard",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Manage bookings, spare parts, stock, and workshop activity from one place.",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroMiniStat(
                          title: "Bookings",
                          value: "$_activeBookingsCount",
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHeroMiniStat(
                          title: "Alerts",
                          value: "$_unreadNotificationCount",
                          icon: Icons.notifications_active_rounded,
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

  Widget _buildHeroMiniStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: "Active",
              value: "$_activeBookingsCount",
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Chats",
              value: "$_unreadChatCount",
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: onSurface.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: onSurface.withOpacity(0.60),
                fontSize: 12,
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: onSurface.withOpacity(0.06)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.20),
                        AppColors.primary.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track workshop jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.60),
                  ),
                ),
              ],
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
                    ),
                    borderRadius: BorderRadius.circular(999),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: onSurface.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.20), color.withOpacity(0.10)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Open and manage",
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: onSurface.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyAddedSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sparePartService.getRecentSpareParts(),
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
          height: 315,
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
                imageUrl: (item['imageUrl'] ?? '').toString(),
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
      future: _workshopService.getWorkshopList(),
      builder: (context, snapshot) {
        final rawItems = snapshot.data ?? [];

        final items = rawItems.where((item) {
          return (item['isActive'] ?? false) == true;
        }).toList();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (items.isEmpty) {
          return _buildEmptyMessage("No active workshops found.");
        }

        return SizedBox(
          height: 310,
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
                imageUrl: (item['imageUrl'] ?? '').toString(),
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
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final lowStock = stock <= 5;
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: 205,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: Container(
                  height: 125,
                  width: double.infinity,
                  color: onSurface.withOpacity(0.06),
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.build_circle_outlined,
                                size: 46,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.build_circle_outlined,
                            size: 46,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: lowStock
                        ? Colors.red.withOpacity(0.92)
                        : Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    lowStock ? "Low Stock" : "Available",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.4,
                      color: onSurface.withOpacity(0.68),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
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
                          "Stock: $stock",
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: lowStock ? Colors.red : onSurface,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: "Add",
                      height: 42,
                      borderRadius: 12,
                      onPressed: onTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required int bookingCount,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: Container(
                  height: 125,
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
                                size: 46,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.garage_outlined,
                            size: 46,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "$bookingCount bookings",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.4,
                      color: onSurface.withOpacity(0.68),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: "Open",
                      height: 42,
                      borderRadius: 12,
                      onPressed: onTap,
                    ),
                  ),
                ],
              ),
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