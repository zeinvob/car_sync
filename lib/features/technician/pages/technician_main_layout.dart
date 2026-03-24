import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/constants/app_colors.dart';

import 'package:car_sync/features/technician/pages/home.dart';
import 'package:car_sync/features/technician/pages/inventory_page.dart';
import 'package:car_sync/features/technician/pages/profile_page.dart';

class TechnicianMainLayout extends StatefulWidget {
  const TechnicianMainLayout({super.key});

  @override
  State<TechnicianMainLayout> createState() => _TechnicianMainLayoutState();
}

class _TechnicianMainLayoutState extends State<TechnicianMainLayout> {
  int _selectedIndex = 0;

  /// 🔥 KEEP PAGES ALIVE (GOOD PRACTICE)
  late final List<Widget> _pages = [
    const TechnicianHomeScreen(),
    const InventoryPage(),
    const TechnicianProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // prevent unnecessary rebuild
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      /// 🔥 MODERN NAV BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,

          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,

          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
          ),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}