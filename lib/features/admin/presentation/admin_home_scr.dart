import 'dart:async';
import 'dart:convert';

import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/services/booking_service.dart';
import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/core/services/user_service.dart';
import 'package:car_sync/core/services/workshop_service.dart';
import 'package:car_sync/core/theme/admin_theme_controller.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_chat_inbox_page.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_profile_page.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_workshops_browser_page.dart';
import 'package:car_sync/features/admin/presentation/pages/manage_workshops_page.dart';
import 'package:car_sync/features/admin/presentation/pages/notifications_page.dart';
import 'package:car_sync/features/admin/presentation/pages/stock_page.dart';
import 'package:car_sync/features/admin/presentation/pages/workshop_bookings_page.dart';
import 'package:car_sync/features/admin/presentation/widgets/floating_support_chat_button.dart';
import 'package:car_sync/features/admin/presentation/pages/technicians_page.dart';
import 'package:car_sync/features/admin/presentation/pages/parts_orders_page.dart';
import 'package:car_sync/features/admin/presentation/pages/ratings_page.dart';
import 'package:car_sync/features/auth/pages/login_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final WorkshopService _workshopService = WorkshopService();
  final AuthService _authService = AuthService();

  int _activeBookingsCount = 0;
  int _unreadNotificationCount = 0;
  int _unreadChatCount = 0;

  StreamSubscription<int>? _activeBookingsSubscription;
  StreamSubscription<int>? _notificationCountSubscription;
  StreamSubscription<int>? _chatCountSubscription;

  bool _isSigningOut = false;
  bool _isLoadingAdmin = true;
  int _selectedIndex = 0;

  String _adminName = 'Admin';
  String _adminEmail = '';
  String _adminProfileImageUrl = '';

  Timer? _chatRefreshTimer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  CollectionReference get _sparePartsCollection =>
      FirebaseFirestore.instance.collection('spareparts');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _listenToNotificationCounts();
    _listenToActiveBookingsCount();
    _listenToUnreadChatCount();
    _startChatCountAutoRefresh();
    _loadAdminData();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel();
    _activeBookingsSubscription?.cancel();
    _chatCountSubscription?.cancel();
    _chatRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listenToNotificationCounts();
      _listenToActiveBookingsCount();
      _listenToUnreadChatCount();
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

    _notificationCountSubscription = _notificationService
        .unreadNotificationCountStream(role: 'admin', currentUserId: user.uid)
        .listen((count) {
          if (mounted) {
            setState(() {
              _unreadNotificationCount = count;
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
    return sale <= 0 ? original : sale;
  }

  int _readDiscountPercent(Map<String, dynamic> data) {
    final stored = _toInt(data['discountPercent']);
    if (stored > 0) return stored;

    final original = _readOriginalPrice(data);
    final sale = _readSalePrice(data);

    if (original <= 0 || sale >= original) return 0;
    return (((original - sale) / original) * 100).round();
  }

  bool _isOnSale(Map<String, dynamic> data) {
    final original = _readOriginalPrice(data);
    final sale = _readSalePrice(data);
    return sale < original;
  }

  String _timeBadgeText(Map<String, dynamic> data) {
    final updatedAt = data['updatedAt'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final now = DateTime.now();

    final updated = updatedAt?.toDate();
    final created = createdAt?.toDate();

    if (updated != null) {
      final diff = now.difference(updated);
      final isRecentCreate =
          created != null && now.difference(created).inMinutes <= 30;

      if (isRecentCreate) return 'Just added';
      if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Updated yesterday';
      return 'Updated ${diff.inDays}d ago';
    }

    if (created != null) {
      final diff = now.difference(created);
      if (diff.inMinutes < 60) return 'Added ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Added ${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Added yesterday';
      return 'Added ${diff.inDays}d ago';
    }

    return 'Recently added';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const AdminWorkshopsBrowserPage(),
      const TechniciansPage(),
      const StockPage(),
      const PartsOrdersPage(),
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
            FloatingSupportChatButton(adminName: _adminName),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _adminProfileImageUrl.trim().isNotEmpty
                            ? Builder(
                                builder: (context) {
                                  try {
                                    return Image.memory(
                                      base64Decode(_adminProfileImageUrl),
                                      fit: BoxFit.cover,
                                    );
                                  } catch (_) {
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _adminName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _adminEmail.isEmpty ? 'Admin account' : _adminEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                              'Admin Panel',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
                      'Menu',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: AdminThemeController.isDark,
                    builder: (context, isDark, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
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
                          border: Border.all(
                            color: onSurface.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.dark_mode_outlined,
                                color: AppColors.primary,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dark mode',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                              ),
                            ),
                            Switch(
                              value: isDark,
                              onChanged: (val) {
                                AdminThemeController.setTheme(val);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildModernDrawerTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    onTap: () async {
                      Navigator.pop(context);
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProfilePage(),
                        ),
                      );

                      if (updated == true) {
                        _loadAdminData();
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildModernDrawerTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Customer Chats',
                    badgeText: _unreadChatCount > 0
                        ? (_unreadChatCount > 99 ? '99+' : '$_unreadChatCount')
                        : null,
                    onTap: () async {
                      Navigator.pop(context);

                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminChatInboxPage(),
                        ),
                      );

                      if (changed == true) {
                        await _refreshUnreadChatCountOnce();
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildModernDrawerTile(
                    icon: Icons.garage_outlined,
                    title: 'Manage Workshops',
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

                  const SizedBox(height: 10),

                  _buildModernDrawerTile(
                    icon: Icons.star_outline_rounded,
                    title: 'Ratings & Feedback',
                    onTap: () async {
                      Navigator.pop(context);

                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RatingsPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
                      'Session',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await _handleSignOut();
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.red.withOpacity(0.16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sign out',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: onSurface.withOpacity(0.45),
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
          SizedBox(
            width: double.infinity,
            child: _buildRatingsWideActionCard(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildBookingsActionCard()),
              const SizedBox(width: 12),
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

  Widget _buildRatingsWideActionCard() {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RatingsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.20),
                    Colors.orange.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: Colors.orange,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ratings and Feedback',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Latest customer reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: onSurface.withOpacity(0.60),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRatingsTicker(),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildRatingsQuickActionCard() {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RatingsPage()),
        );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.20),
                    Colors.orange.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: Colors.orange,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ratings',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Latest customer feedback',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: onSurface.withOpacity(0.60),
              ),
            ),
            const SizedBox(height: 10),
            _buildRatingsTicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsTicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final onSurface = Theme.of(context).colorScheme.onSurface;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 52,
            alignment: Alignment.centerLeft,
            child: Text(
              'Loading feedback...',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: onSurface.withOpacity(0.55),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 52,
            alignment: Alignment.centerLeft,
            child: Text(
              'Unable to load feedback',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            height: 52,
            alignment: Alignment.centerLeft,
            child: Text(
              'No customer feedback yet',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: onSurface.withOpacity(0.55),
              ),
            ),
          );
        }

        final reviews = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'userName': (data['userName'] ?? 'Customer').toString(),
            'comment': (data['comment'] ?? '').toString(),
            'rating': _toDouble(data['rating']),
          };
        }).toList();

        return SizedBox(
          height: 52,
          child: _AutoSlidingReviewTicker(reviews: reviews),
        );
      },
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
    return StreamBuilder<QuerySnapshot>(
      stream: _sparePartsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyMessage("Failed to load spare parts.");
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyMessage("No spare parts found.");
        }

        final sortedDocs = [...docs];
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTime =
              (aData['updatedAt'] as Timestamp?) ??
              (aData['createdAt'] as Timestamp?);
          final bTime =
              (bData['updatedAt'] as Timestamp?) ??
              (bData['createdAt'] as Timestamp?);

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        final items = sortedDocs.take(10).toList();

        return SizedBox(
          height: 320,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final doc = items[index];
              final item = doc.data() as Map<String, dynamic>;

              return _buildRecentStockCard(
                item: item,
                onTap: () {
                  setState(() => _selectedIndex = 3);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentStockCard({
    required Map<String, dynamic> item,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final title = (item['part'] ?? 'No Part').toString();
    final carModel = _readCarModel(item);
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final type = (item['type'] ?? 'Other').toString();

    final stock = _toInt(item['stock']);
    final originalPrice = _readOriginalPrice(item);
    final salePrice = _readSalePrice(item);
    final discountPercent = _readDiscountPercent(item);
    final onSale = _isOnSale(item);

    final lowStock = stock > 0 && stock <= 5;
    final unavailable = stock <= 0;

    Color statusColor;
    String statusText;

    if (unavailable) {
      statusColor = Colors.red;
      statusText = 'Unavailable';
    } else if (lowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
    } else {
      statusColor = Colors.green;
      statusText = 'Available';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
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
          border: Border.all(color: onSurface.withOpacity(0.05)),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gradientStart.withOpacity(0.12),
                          AppColors.gradientEnd.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: imageUrl.trim().isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 42,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      type,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (onSale && discountPercent > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                      carModel.isEmpty ? 'No car model' : carModel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: onSurface.withOpacity(0.68),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$statusText • $stock',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _timeBadgeText(item),
                        style: GoogleFonts.poppins(
                          fontSize: 10.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (onSale && discountPercent > 0)
                                Text(
                                  'RM ${originalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                'RM ${salePrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        'icon': Icons.engineering_outlined,
        'activeIcon': Icons.engineering,
        'label': 'Foremen',
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

class _AutoSlidingReviewTicker extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;

  const _AutoSlidingReviewTicker({required this.reviews});

  @override
  State<_AutoSlidingReviewTicker> createState() =>
      _AutoSlidingReviewTickerState();
}

class _AutoSlidingReviewTickerState extends State<_AutoSlidingReviewTicker> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);

    if (widget.reviews.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_pageController.hasClients) return;

        _currentIndex++;
        if (_currentIndex >= widget.reviews.length) {
          _currentIndex = 0;
        }

        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.reviews.length,
      itemBuilder: (context, index) {
        final review = widget.reviews[index];
        final userName = review['userName'].toString();
        final comment = review['comment'].toString();
        final rating = (review['rating'] as num).toDouble();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$userName • ${rating.toStringAsFixed(1)}★',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.isEmpty ? 'No written feedback' : comment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        height: 1.35,
                        color: onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
