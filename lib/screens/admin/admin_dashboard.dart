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
  List<Map<String, dynamic>> _recentActivities = [];

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
      final activities = await SupabaseService.getRecentAttendances();

      if (mounted) {
        setState(() {
          _totalTeachers = teachers.length;
          _totalStudents = students.length;
          _totalClasses = classes.length;
          _attendancesToday = attendances.length;
          _userProfile = profile;
          _recentActivities = activities;
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
        Navigator.pushNamed(context, '/profile');
        break;
    }
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
              if (_recentActivities.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Belum ada aktivitas', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                  ),
                )
              else
                ..._recentActivities.map((activity) {
                  final name = activity['profiles']?['full_name'] ?? 'Anonim';
                  final status = activity['status'] ?? 'hadir';
                  final className = activity['schedules']?['classes']?['name'] ?? 'Kelas';
                  final mapel = activity['schedules']?['mapel_name'] ?? 'Mapel';
                  final time = activity['created_at'] != null ? DateTime.parse(activity['created_at']).toLocal() : DateTime.now();
                  final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  
                  IconData icon = Icons.verified_rounded;
                  Color color = AppColors.success;
                  String title = 'Absensi $status';
                  
                  if (status == 'terlambat') {
                    color = AppColors.warning;
                    icon = Icons.access_time_rounded;
                  } else if (status == 'alpa') {
                    color = AppColors.error;
                    icon = Icons.cancel_rounded;
                  } else if (status == 'izin') {
                    color = AppColors.primaryBlue;
                    icon = Icons.info_outline_rounded;
                  }
                  
                  return _buildActivityItem(
                    title.toUpperCase(),
                    '$name • $className ($mapel)',
                    icon,
                    color,
                    timeStr,
                  );
                }),
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
