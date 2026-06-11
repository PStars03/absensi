import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/attendance_tile.dart';
import '../../widgets/app_bottom_nav.dart';

/// Dashboard Guru
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/teacher-schedule');
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Text('A', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
            ),
            const SizedBox(height: 12),
            const Text('Pak Ahmad Fauzi', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('NIP: 198501012010011001', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
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
    final todayAttendances = MockData.attendances
        .where((a) => a.date == '11 Jun 2026')
        .toList();

    return Scaffold(
      body: SafeArea(
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
                        const Text('Pak Ahmad Fauzi', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
              const SizedBox(height: 24),

              // Stats
              Row(
                children: const [
                  Expanded(child: StatCard(icon: Icons.people_rounded, value: '32', label: 'Total Siswa', color: AppColors.primaryBlue)),
                  SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: '28', label: 'Hadir Hari Ini', color: AppColors.success)),
                  SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.assignment_rounded, value: '5', label: 'Tugas Aktif', color: Color(0xFFEC4899))),
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
                  _buildMenuCard('Pengumuman', Icons.campaign_rounded, const Color(0xFFF59E0B), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Pengumuman belum tersedia'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    );
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
              ...todayAttendances.map((a) => AttendanceTile(
                    name: a.userName,
                    date: a.date,
                    checkIn: a.checkIn,
                    checkOut: a.checkOut,
                    status: a.status,
                    onEditStatus: () => _showEditStatusDialog(a),
                  )),
            ],
          ),
        ),
      ),
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

  void _showEditStatusDialog(MockAttendance attendance) {
    String? selectedStatus = attendance.status;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Status: ${attendance.userName}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
        content: StatefulBuilder(
          builder: (_, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['hadir', 'terlambat', 'alpa', 'izin'].map((s) {
              // ignore: deprecated_member_use
              return RadioListTile<String>(
                value: s,
                // ignore: deprecated_member_use
                groupValue: selectedStatus,
                title: Text(s[0].toUpperCase() + s.substring(1), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                // ignore: deprecated_member_use
                onChanged: (v) => setDialogState(() => selectedStatus = v),
                dense: true,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Status ${attendance.userName} diubah ke $selectedStatus (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
