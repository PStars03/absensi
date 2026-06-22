import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class WaliKelasMonitoringScreen extends StatefulWidget {
  const WaliKelasMonitoringScreen({super.key});

  @override
  State<WaliKelasMonitoringScreen> createState() => _WaliKelasMonitoringScreenState();
}

class _WaliKelasMonitoringScreenState extends State<WaliKelasMonitoringScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _attendances = [];
  String? _classId;
  String? _className;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Get teacher info
        final teacherRes = await SupabaseService.client.from('teachers').select('wali_class_id, classes(name)').eq('profile_id', user.id).maybeSingle();
        if (teacherRes != null && teacherRes['wali_class_id'] != null) {
          _classId = teacherRes['wali_class_id'];
          _className = teacherRes['classes']?['name'];

          // Fetch students
          final students = await SupabaseService.getClassStudents(_classId!);
          
          // Fetch attendances
          final attendances = await SupabaseService.getClassAttendanceRecap(_classId!);

          if (mounted) {
            setState(() {
              _students = students;
              _attendances = attendances;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda bukan Wali Kelas atau kelas belum diatur')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_classId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monitoring Wali Kelas')),
        body: const Center(child: Text('Akses ditolak: Anda bukan Wali Kelas.', style: TextStyle(fontFamily: 'Poppins'))),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monitoring Wali Kelas', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
              Text('Kelas: $_className', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'Daftar Siswa'),
              Tab(text: 'Rekap Absensi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentsList(),
            _buildAttendanceRecap(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return const Center(child: Text('Belum ada siswa di kelas ini'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final name = student['profiles']?['full_name'] ?? 'Siswa';
        final nis = student['nis'] ?? '-';

        // Calculate attendance stats (simple logic)
        final studentAttendances = _attendances.where((a) => a['user_id'] == student['profile_id']).toList();
        final hadir = studentAttendances.where((a) => a['status'] == 'hadir').length;
        final terlambat = studentAttendances.where((a) => a['status'] == 'terlambat').length;
        final alpa = studentAttendances.where((a) => a['status'] == 'alpa').length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('NIS: $nis', style: const TextStyle(fontSize: 12)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Hadir', hadir, AppColors.success),
                    _buildStatCol('Terlambat', terlambat, AppColors.warning),
                    _buildStatCol('Alpa', alpa, AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildAttendanceRecap() {
    if (_attendances.isEmpty) {
      return const Center(child: Text('Belum ada data absensi untuk kelas ini'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendances.length,
      itemBuilder: (context, index) {
        final a = _attendances[index];
        final name = a['profiles']?['full_name'] ?? 'Siswa';
        final mapel = a['schedules']?['mapel_name'] ?? 'Mapel';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('${a['date']} • $mapel\nMasuk: ${a['check_in'] ?? '-'}', style: const TextStyle(fontSize: 12)),
            isThreeLine: true,
            trailing: _buildStatusBadge(a['status'] ?? 'hadir'),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();
    switch (status) {
      case 'hadir': color = AppColors.success; break;
      case 'terlambat': color = AppColors.warning; break;
      case 'alpa': color = AppColors.error; break;
      case 'izin': color = AppColors.primaryBlue; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
