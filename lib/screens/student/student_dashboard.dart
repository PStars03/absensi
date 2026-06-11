import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/attendance_tile.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../services/supabase_service.dart';

/// Dashboard Siswa
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/student-schedule');
        break;
      case 2:
        _showProfileSheet();
        break;
    }
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Text('A', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
            ),
            const SizedBox(height: 12),
            const Text('Andi Pratama', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('NISN: 0051234567 • 12 IPA 1', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushReplacementNamed(context, '/login');
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          final profile = data?['profile'] as Map<String, dynamic>? ?? {};
          final attendances = (data?['attendances'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          
          final fullName = profile['full_name'] as String? ?? 'Siswa';

          return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: const Text('A', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primaryBlue, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selamat Datang 👋', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
                        Text(fullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    style: IconButton.styleFrom(backgroundColor: AppColors.background),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Removed global scan card per PRD (Scan is now per-mapel)

              // Stats
              Row(
                children: const [
                  Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: '18', label: 'Hadir', color: AppColors.success)),
                  SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.schedule_rounded, value: '3', label: 'Terlambat', color: AppColors.warning)),
                  SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.cancel_rounded, value: '1', label: 'Alpa', color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text('Menu', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMenuCard('Jadwal', Icons.schedule_rounded, AppColors.primaryBlue, () {
                    Navigator.pushNamed(context, '/student-schedule');
                  }),
                  const SizedBox(width: 10),
                  _buildMenuCard('Pengumuman', Icons.campaign_rounded, const Color(0xFFF59E0B), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Pengumuman belum tersedia'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Recent attendance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Absensi Terbaru', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/student-attendance'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              if (attendances.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: Text('Belum ada data absensi', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey))),
                )
              else
                ...attendances.take(3).map((a) => AttendanceTile(
                      name: a['schedules']?['mapel_name'] ?? 'Mapel',
                      date: a['date'] ?? '',
                      checkIn: a['check_in'] ?? '',
                      checkOut: a['check_out'],
                      status: a['status'] ?? 'hadir',
                    )),
            ],
          ),
        ),
      );
    },
  ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        role: 'student',
        onTap: _onNavTap,
      ),
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
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
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

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final profile = await SupabaseService.getCurrentUserProfile();
    final attendances = await SupabaseService.getMyAttendances();
    return {
      'profile': profile,
      'attendances': attendances,
    };
  }
}
