import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom Navigation Bar adaptif berdasarkan role
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final String role; // 'student', 'teacher', 'admin'
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.role,
    required this.onTap,
  });

  List<BottomNavigationBarItem> get _items {
    switch (role) {
      case 'teacher':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_rounded), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
      case 'admin':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Pengguna'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_rounded), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
      default: // student
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule_rounded), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: _items,
      ),
    );
  }
}
