import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendances = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final teacher = await SupabaseService.getTeacherProfile();
      if (teacher == null) throw Exception('Profile guru tidak ditemukan');

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final schedules = await SupabaseService.client
          .from('schedules')
          .select('id, mapel_name, classes(name)')
          .eq('teacher_id', teacher['id']);

      final scheduleIds = schedules.map((e) => e['id']).toList();

      if (scheduleIds.isEmpty) {
        if (mounted) setState(() { _attendances = []; _isLoading = false; });
        return;
      }

      final response = await SupabaseService.client
          .from('attendances')
          .select('''
            *,
            schedules:schedule_id ( mapel_name, classes(name) ),
            profiles:user_id ( full_name )
          ''')
          .eq('date', dateStr)
          .inFilter('schedule_id', scheduleIds)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _attendances = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat laporan: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchReports();
    }
  }

  Future<void> _downloadCSV() async {
    if (_attendances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diunduh')));
      return;
    }

    try {
      // 1. Generate CSV String
      final buffer = StringBuffer();
      buffer.writeln("Nama Siswa,Mata Pelajaran,Kelas,Tanggal,Jam Masuk,Jam Pulang,Status");

      for (var row in _attendances) {
        final name = row['profiles']?['full_name'] ?? '-';
        final mapel = row['schedules']?['mapel_name'] ?? '-';
        final className = row['schedules']?['classes']?['name'] ?? '-';
        final date = row['date'] ?? '-';
        final checkIn = row['check_in'] ?? '-';
        final checkOut = row['check_out'] ?? '-';
        final status = row['status'] ?? '-';

        // Escape commas just in case
        buffer.writeln('"$name","$mapel","$className","$date","$checkIn","$checkOut","$status"');
      }

      // 2. Get Downloads directory
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) {
        dir = await getApplicationDocumentsDirectory();
      }

      final dateStr = DateFormat('yyyyMMdd').format(_selectedDate);
      final file = File('${dir.path}/Laporan_Absen_$dateStr.csv');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Berhasil disimpan di: ${file.path}'),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan file: $e')));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();
    switch (status.toLowerCase()) {
      case 'hadir': color = AppColors.success; break;
      case 'terlambat': color = AppColors.warning; break;
      case 'alpa': color = AppColors.error; break;
      case 'izin': color = AppColors.primaryBlue; break;
      case 'sakit': color = Colors.orange; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harian Guru', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text('Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _attendances.isEmpty ? null : _downloadCSV,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendances.isEmpty
                    ? const Center(child: Text('Tidak ada absen untuk tanggal ini', style: TextStyle(fontFamily: 'Poppins')))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _attendances.length,
                        itemBuilder: (context, index) {
                          final att = _attendances[index];
                          final name = att['profiles']?['full_name'] ?? 'Anonim';
                          final className = att['schedules']?['classes']?['name'] ?? '-';
                          final mapel = att['schedules']?['mapel_name'] ?? '-';
                          final inTime = att['check_in'] ?? '--:--';
                          final outTime = att['check_out'] ?? '--:--';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                                child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('$mapel ($className)\nMasuk: $inTime | Pulang: $outTime', style: const TextStyle(fontSize: 12)),
                              ),
                              trailing: _buildStatusBadge(att['status'] ?? 'alpa'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
