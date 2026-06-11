import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';

class MapelDashboardScreen extends StatefulWidget {
  final String scheduleId;
  final String role; // 'student' or 'teacher'

  const MapelDashboardScreen({
    super.key,
    required this.scheduleId,
    required this.role,
  });

  @override
  State<MapelDashboardScreen> createState() => _MapelDashboardScreenState();
}

class _MapelDashboardScreenState extends State<MapelDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Find the schedule details
    final schedule = MockData.schedules.firstWhere(
      (s) => s.id == widget.scheduleId,
      orElse: () => MockData.schedules.first,
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        schedule.mapelName,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${schedule.teacherName} • ${schedule.className}',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 16),
                      // Scan Action
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/face-scan', arguments: {
                                  'type': 'masuk',
                                  'scheduleId': widget.scheduleId,
                                });
                              },
                              icon: const Icon(Icons.face_rounded),
                              label: Text(widget.role == 'teacher' ? 'Mengajar' : 'Masuk'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/face-scan', arguments: {
                                  'type': 'pulang',
                                  'scheduleId': widget.scheduleId,
                                });
                              },
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(widget.role == 'teacher' ? 'Selesai' : 'Pulang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildBodyContent(),
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Absensi'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Kuis'),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildAbsensiTab();
      case 1:
        return _buildMateriTab();
      case 2:
        return _buildTugasTab();
      case 3:
        return _buildKuisTab();
      default:
        return _buildAbsensiTab();
    }
  }

  Widget? _buildFab() {
    if (widget.role != 'teacher') return null;

    // Only teacher sees the FAB to add content based on active tab
    IconData icon;
    String tooltip;
    switch (_currentIndex) {
      case 0: // Absensi - no fab usually, but maybe export?
        return const SizedBox.shrink();
      case 1:
        icon = Icons.upload_file_rounded;
        tooltip = 'Tambah Materi';
        break;
      case 2:
        icon = Icons.add_task_rounded;
        tooltip = 'Buat Tugas';
        break;
      case 3:
        icon = Icons.post_add_rounded;
        tooltip = 'Buat Kuis';
        break;
      default:
        return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: () {},
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  Widget _buildAbsensiTab() {
    // Filter attendances for this mapel
    final attendances = MockData.attendances.where((a) => a.scheduleId == widget.scheduleId).toList();

    if (attendances.isEmpty) {
      return const Center(child: Text('Belum ada data absensi', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendances.length,
      itemBuilder: (context, index) {
        final a = attendances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(a.userName[0], style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ),
            title: Text(a.userName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('${a.date} • Masuk: ${a.checkIn} ${a.checkOut != null && a.checkOut != "-" ? "• Pulang: ${a.checkOut}" : ""}', style: const TextStyle(fontSize: 12)),
            trailing: _buildStatusBadge(a.status),
          ),
        );
      },
    );
  }

  Widget _buildMateriTab() {
    final materials = MockData.materials.where((m) => m.scheduleId == widget.scheduleId).toList();

    if (materials.isEmpty) {
      return const Center(child: Text('Belum ada materi', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final m = materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366F1)),
            ),
            title: Text(m.title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text(m.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildTugasTab() {
    final tasks = MockData.tasks.where((t) => t.scheduleId == widget.scheduleId).toList();

    if (tasks.isEmpty) {
      return const Center(child: Text('Belum ada tugas', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final t = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(t.title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('Tenggat: ${t.deadline}', style: const TextStyle(fontSize: 12)),
            trailing: _buildTaskStatusBadge(t.status),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildKuisTab() {
    final quizzes = MockData.quizzes.where((q) => q.scheduleId == widget.scheduleId).toList();

    if (quizzes.isEmpty) {
      return const Center(child: Text('Belum ada kuis', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final q = quizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(q.title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('${q.questionCount} Soal • ${q.durationMinutes} Menit', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();

    switch (status) {
      case 'hadir':
        color = AppColors.success;
        break;
      case 'terlambat':
        color = AppColors.warning;
        break;
      case 'alpa':
        color = AppColors.error;
        break;
      case 'izin':
        color = AppColors.primaryBlue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildTaskStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();

    switch (status) {
      case 'belum':
        color = AppColors.error;
        break;
      case 'dikumpulkan':
        color = AppColors.primaryBlue;
        break;
      case 'dinilai':
        color = AppColors.success;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
