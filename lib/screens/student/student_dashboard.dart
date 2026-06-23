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
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.init(context);
    });
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _notifSub = Supabase.instance.client.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId).listen((data) {
        if (mounted) {
          setState(() {
            _unreadNotifs = data.where((n) => n['is_read'] == false).length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
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
        _showProfileSheet();
        break;
    }
  }

  void _showProfileSheet() {
    final name = _userProfile?['full_name'] as String? ?? 'Siswa';
    final nisn = _userProfile?['identity_number'] as String? ?? '-';
    final className = _userProfile?['class_name'] as String? ?? '-';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

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
              child: Text(initial, style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('NISN: $nisn • $className', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
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
      body: _isLoadingProfile 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.getMyAttendancesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                              child: Text(initial, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primaryBlue, fontSize: 18)),
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
                              icon: Badge(
                                isLabelVisible: _unreadNotifs > 0,
                                label: Text(_unreadNotifs.toString()),
                                child: const Icon(Icons.notifications_outlined),
                              ),
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
