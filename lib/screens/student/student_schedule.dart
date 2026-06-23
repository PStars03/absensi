import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import 'dart:math';
import '../../widgets/app_bottom_nav.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  final int _currentNavIndex = 1; // Jadwal tab
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final allSchedules = await SupabaseService.getSchedules();
      final profile = await SupabaseService.getCurrentUserProfile();
      
      // Filter by current student class
      if (profile != null) {
        final classId = profile['class_id'];
        if (classId != null) {
          _schedules = allSchedules.where((s) => s['class_id'] == classId).toList();
        } else {
          // fallback if no class_id
          _schedules = allSchedules;
        }
      } else {
        _schedules = allSchedules;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat jadwal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/student-dashboard');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran'),
        automaticallyImplyLeading: false, // hidden back button for bottom nav
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('Tidak ada jadwal pelajaran.', style: TextStyle(fontFamily: 'Poppins')))
              : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _schedules.length,
        itemBuilder: (context, index) {
          final schedule = _schedules[index];
          
          final mapelName = schedule['subjects']?['name'] ?? schedule['mapel_name'] ?? 'Mata Pelajaran';
          final className = schedule['classes']?['name'] ?? schedule['class_name'] ?? 'Kelas';
          final teacherName = schedule['profiles']?['full_name'] ?? 'Guru';
          final dayStr = schedule['day'] ?? '-';
          final startStr = schedule['start_time'] ?? '';
          final endStr = schedule['end_time'] ?? '';
          final roomStr = schedule['room'] ?? '-';
          final todayInt = DateTime.now().weekday;
          final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
          final todayStr = todayInt >= 1 && todayInt <= 7 ? days[todayInt - 1] : '';
          
          final isToday = dayStr.trim().toLowerCase() == todayStr.toLowerCase();
          final headerColor = isToday ? AppColors.success : AppColors.error;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  color: headerColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mapelName,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          className,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.calendar_today_rounded, '$dayStr, ${startStr.substring(0, min(startStr.length, 5))} - ${endStr.substring(0, min(endStr.length, 5))}'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.person_rounded, teacherName),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.room_rounded, roomStr),
                    ],
                  ),
                ),
                // Footer
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, 
                        '/mapel-dashboard', 
                        arguments: {'scheduleId': schedule['id'], 'role': 'student'},
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text('Masuk Kelas', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ),
              ],
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
