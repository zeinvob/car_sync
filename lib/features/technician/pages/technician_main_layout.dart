import 'package:flutter/material.dart';
import 'package:car_sync/features/technician/pages/home.dart';
import 'package:car_sync/features/technician/pages/inventory_page.dart';
import 'package:car_sync/features/technician/pages/profile_page.dart';

class TechnicianMainLayout extends StatefulWidget {
  const TechnicianMainLayout({super.key});

  @override
  State<TechnicianMainLayout> createState() => _TechnicianMainLayoutState();
}

class _TechnicianMainLayoutState extends State<TechnicianMainLayout> {
  int _currentIndex = 0;

  // --- FIXED THESE NAMES TO MATCH YOUR CLASSES ---
  final List<Widget> _pages = [
    const TechnicianHomeScreen(), // Correct (matches home.dart)
    const InventoryPage(),        // FIXED (matches the fixed inventory_page.dart)
    const TechnicianProfilePage(),          // FIXED (check if yours is ProfilePage or TechnicianProfilePage)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            activeIcon: Icon(Icons.build_circle),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Parts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}