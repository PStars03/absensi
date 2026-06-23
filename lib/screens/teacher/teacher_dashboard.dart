import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../services/supabase_service.dart';

/// Dashboard Guru
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final int _currentNavIndex = 0;
  Map<String, dynamic>? _userProfile;
  late final Future<Map<String, int>> _statsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _statsFuture = SupabaseService.getTeacherDashboardStats();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final profile = await SupabaseService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/teacher-schedule');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _userProfile?['full_name'] as String? ?? 'Guru';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Scaffold(
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          final stats = snapshot.data ?? {'total_siswa': 0, 'hadir_hari_ini': 0, 'tugas_aktif': 0};
          
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                      backgroundImage: _userProfile?['avatar_url'] != null ? NetworkImage(_userProfile!['avatar_url']) : null,
                      child: _userProfile?['avatar_url'] == null 
                          ? Text(initial, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primaryBlue, fontSize: 18))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selamat Datang 👋', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
                        Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    icon: const Icon(Icons.notifications_outlined),
                    style: IconButton.styleFrom(backgroundColor: AppColors.background),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Removed global scan card per PRD (Scan is now per-mapel)
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: StatCard(icon: Icons.people_rounded, value: '${stats['total_siswa']}', label: 'Total Siswa', color: AppColors.primaryBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: '${stats['hadir_hari_ini']}', label: 'Hadir Hari Ini', color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.assignment_rounded, value: '${stats['tugas_aktif']}', label: 'Tugas Aktif', color: const Color(0xFFEC4899))),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text('Menu Guru', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMenuCard('Jadwal', Icons.schedule_rounded, AppColors.primaryBlue, () {
                    Navigator.pushNamed(context, '/teacher-schedule');
                  }),
                  const SizedBox(width: 10),
                  _buildMenuCard('Wali Kelas', Icons.admin_panel_settings_rounded, const Color(0xFFF59E0B), () {
                    Navigator.pushNamed(context, '/wali-kelas');
                  }),
                  const SizedBox(width: 10),
                  _buildMenuCard('Laporan', Icons.insert_chart_outlined_rounded, AppColors.success, () {
                    Navigator.pushNamed(context, '/teacher-reports');
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Today's student attendance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Absensi Siswa Hari Ini', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/teacher-attendance'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Data absensi ditampilkan per kelas melalui menu Jadwal.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey)),
              ),
            ],
          ),
        ),
      );
    }),
    bottomNavigationBar: AppBottomNav(currentIndex: _currentNavIndex, role: 'teacher', onTap: _onNavTap),
  );
}


  Widget _buildMenuCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
