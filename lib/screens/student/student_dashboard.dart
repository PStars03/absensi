import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
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
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  int _unreadNotifs = 0;
  late final Future<List<Map<String, dynamic>>> _attendancesFuture;

  @override
  void initState() {
    super.initState();
    _attendancesFuture = SupabaseService.getMyAttendances();
    _fetchProfile();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.init(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final profile = await SupabaseService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/student-schedule');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingProfile 
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _attendancesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                final attendances = snapshot.data ?? [];
                final fullName = _userProfile?['full_name'] as String? ?? 'Siswa';
                final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S';

                int countHadir = attendances.where((a) => a['status'] == 'hadir').length;
                int countTerlambat = attendances.where((a) => a['status'] == 'terlambat').length;
                int countAlpa = attendances.where((a) => a['status'] == 'alpa').length;
                int countIzin = attendances.where((a) => a['status'] == 'izin').length;

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
                                  Text(fullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/notifications');
                              },
                              icon: const Icon(Icons.notifications_outlined),
                              style: IconButton.styleFrom(backgroundColor: AppColors.background),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: countHadir.toString(), label: 'Hadir', color: AppColors.success)),
                                const SizedBox(width: 10),
                                Expanded(child: StatCard(icon: Icons.schedule_rounded, value: countTerlambat.toString(), label: 'Terlambat', color: AppColors.warning)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: StatCard(icon: Icons.assignment_rounded, value: countIzin.toString(), label: 'Izin/Sakit', color: AppColors.primaryBlue)),
                                const SizedBox(width: 10),
                                Expanded(child: StatCard(icon: Icons.cancel_rounded, value: countAlpa.toString(), label: 'Alpa', color: AppColors.error)),
                              ],
                            ),
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
                  _buildMenuCard('Daftar Wajah', Icons.face_retouching_natural_rounded, AppColors.success, () {
                    Navigator.pushNamed(context, '/face-enrollment');
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


}
