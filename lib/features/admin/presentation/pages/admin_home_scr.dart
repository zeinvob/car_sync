import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final StorageService _storageService = StorageService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      /*_buildDashboardPage()*/
      const Center(child: Text("Bookings Page")),
      const Center(child: Text("Services Page")),
      const Center(child: Text("Stock Page")),
      const Center(child: Text("Profile Page")),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          setState(() => _selectedIndex = value);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            label: "Services",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: "Stock",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  /*Widget _buildDashboardPage() {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _storageService.getAdminDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};

          final todayBookings = data['todayBookings'] ?? 0;
          final carsInService = data['carsInService'] ?? 0;
          final completedServices = data['completedServices'] ?? 0;
          final activeTowing = data['activeTowingRequests'] ?? 0;
          final todayRevenue = data['todayRevenue'] ?? 0.0;
          final lowStockItems = data['lowStockItems'] ?? 0;
          final appointments = List<Map<String, dynamic>>.from(
            data['appointments'] ?? [],
          );
          final statusOverview = Map<String, int>.from(
            data['statusOverview'] ?? {},
          );
          final alerts = List<String>.from(data['alerts'] ?? []);
          final recentActivities = List<String>.from(
            data['recentActivities'] ?? [],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(todayBookings),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _summaryCard(
                      "Today's Bookings",
                      todayBookings.toString(),
                      Icons.calendar_today_outlined,
                    ),
                    _summaryCard(
                      "Cars In Service",
                      carsInService.toString(),
                      Icons.car_repair_outlined,
                    ),
                    _summaryCard(
                      "Completed",
                      completedServices.toString(),
                      Icons.check_circle_outline,
                    ),
                    _summaryCard(
                      "Towing Requests",
                      activeTowing.toString(),
                      Icons.local_shipping_outlined,
                    ),
                    _summaryCard(
                      "Revenue",
                      "RM ${todayRevenue.toStringAsFixed(2)}",
                      Icons.payments_outlined,
                    ),
                    _summaryCard(
                      "Low Stock",
                      lowStockItems.toString(),
                      Icons.warning_amber_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _sectionTitle("Today's Appointments"),
                const SizedBox(height: 10),
                ...appointments.map((item) => _appointmentTile(item)).toList(),

                const SizedBox(height: 20),
                _sectionTitle("Service Status Overview"),
                const SizedBox(height: 10),
                _statusCard(statusOverview),

                const SizedBox(height: 20),
                _sectionTitle("Alerts / Notifications"),
                const SizedBox(height: 10),
                _alertsCard(alerts),

                const SizedBox(height: 20),
                _sectionTitle("Quick Actions"),
                const SizedBox(height: 10),
                _quickActions(),

                const SizedBox(height: 20),
                _sectionTitle("Recent Activity"),
                const SizedBox(height: 10),
                _recentActivityCard(recentActivities),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(int bookings) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, Admin",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat("EEEE, dd MMM yyyy • hh:mm a").format(now),
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            "You have $bookings bookings today.",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _appointmentTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${item['time'] ?? '-'} • ${item['customerName'] ?? '-'}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "${item['carPlate'] ?? '-'} | ${item['serviceType'] ?? '-'} | ${item['status'] ?? '-'}",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _smallActionButton("Assign"),
              _smallActionButton("Check-in"),
              _smallActionButton("Details"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallActionButton(String text) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12),
      ),
    );
  }

  Widget _statusCard(Map<String, int> statusOverview) {
    final entries = statusOverview.entries.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: GoogleFonts.poppins()),
                Text(
                  e.value.toString(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _alertsCard(List<String> alerts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts.isEmpty
            ? [
                Text(
                  "No alerts for now.",
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ]
            : alerts
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text("⚠ $alert", style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      "Add Booking",
      "Check-in Vehicle",
      "Assign Foreman",
      "Generate Invoice",
      "Add Stock",
      "Request Towing",
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (action) => ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                action,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _recentActivityCard(List<String> activities) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: activities.isEmpty
            ? [
                Text(
                  "No recent activity.",
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ]
            : activities
                  .map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text("• $activity", style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }*/
}
