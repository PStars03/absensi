import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_bottom_nav.dart';

import '../../services/supabase_service.dart';

/// Dashboard Super Admin
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final int _currentNavIndex = 0;
  
  int _totalTeachers = 0;
  int _totalStudents = 0;
  int _totalClasses = 0;
  int _attendancesToday = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final client = SupabaseService.client;
      
      final teachers = await client.from('profiles').select('id').eq('role', 'teacher');
      final students = await client.from('profiles').select('id').eq('role', 'student');
      final classes = await client.from('classes').select('id');
      
      final today = DateTime.now().toIso8601String().split('T').first;
      final attendances = await client.from('attendances').select('id').eq('date', today);

      final profile = await SupabaseService.getCurrentUserProfile();

      if (mounted) {
        setState(() {
          _totalTeachers = teachers.length;
          _totalStudents = students.length;
          _totalClasses = classes.length;
          _attendancesToday = attendances.length;
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/admin-users');
        break;
      case 2:
        Navigator.pushNamed(context, '/admin-schedule');
        break;
      case 3:
        _showProfileSheet();
        break;
    }
  }

  void _showProfileSheet() {
    final name = _userProfile?['full_name'] as String? ?? 'Super Admin';
    final email = SupabaseService.currentUser?.email ?? 'admin@sekolah.com';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryBlue, size: 36),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(email, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  SupabaseService.signOut().then((_) {
                    if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  });
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panel Admin', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
                        Text(_userProfile?['full_name'] as String? ?? 'Super Admin', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.background),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: StatCard(icon: Icons.school_rounded, value: '$_totalTeachers', label: 'Total Guru', color: AppColors.primaryBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.people_rounded, value: '$_totalStudents', label: 'Total Siswa', color: const Color(0xFF6366F1))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: '$_attendancesToday', label: 'Absen Hari Ini', color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.class_rounded, value: '$_totalClasses', label: 'Kelas', color: const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text('Menu Admin', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.people_rounded,
                title: 'Manajemen Pengguna',
                subtitle: 'Kelola akun guru dan siswa',
                color: AppColors.primaryBlue,
                onTap: () => Navigator.pushNamed(context, '/admin-users'),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                icon: Icons.assessment_rounded,
                title: 'Laporan Kehadiran',
                subtitle: 'Lihat rekap absensi semua kelas',
                color: const Color(0xFF10B981),
                onTap: () => Navigator.pushNamed(context, '/admin-reports'),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                icon: Icons.school_rounded,
                title: 'Data Kelas',
                subtitle: 'Kelola kelas dan pemetaan siswa',
                color: const Color(0xFF6366F1),
                onTap: () => Navigator.pushNamed(context, '/admin-classes'),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                icon: Icons.schedule_rounded,
                title: 'Jadwal Mata Pelajaran',
                subtitle: 'Kelola jadwal dan plot guru',
                color: const Color(0xFFEC4899),
                onTap: () => Navigator.pushNamed(context, '/admin-schedule'),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                icon: Icons.location_on_rounded,
                title: 'Pengaturan GPS',
                subtitle: 'Atur lokasi dan radius absensi',
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.pushNamed(context, '/admin-gps'),
              ),
              const SizedBox(height: 24),

              // Recent activity
              const Text('Aktivitas Terbaru', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildActivityItem('Guru baru ditambahkan', 'Pak Ridwan Kamil', Icons.person_add_rounded, AppColors.success, '2 jam lalu'),
              _buildActivityItem('Siswa diverifikasi', 'Eka Putri - 12 IPS 1', Icons.verified_rounded, AppColors.primaryBlue, '3 jam lalu'),
              _buildActivityItem('Absensi dikoreksi', 'Citra Dewi: Alpa → Izin', Icons.edit_rounded, AppColors.warning, '5 jam lalu'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _currentNavIndex, role: 'admin', onTap: _onNavTap),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
