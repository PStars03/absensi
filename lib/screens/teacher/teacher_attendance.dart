import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../widgets/attendance_tile.dart';
import '../../theme/app_theme.dart';

/// Kelola Absensi Siswa (Guru)
class TeacherAttendance extends StatelessWidget {
  const TeacherAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Absensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('3', 'Hadir'),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _summaryItem('1', 'Terlambat'),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _summaryItem('1', 'Alpa'),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _summaryItem('1', 'Izin'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filter
          const Text('11 Juni 2026', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          ...MockData.attendances
              .where((a) => a.date == '11 Jun 2026')
              .map((a) => AttendanceTile(
                    name: a.userName,
                    date: a.date,
                    checkIn: a.checkIn,
                    checkOut: a.checkOut,
                    status: a.status,
                    onEditStatus: () => _editStatus(context, a),
                  )),

          const SizedBox(height: 20),
          const Text('10 Juni 2026', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          ...MockData.attendances
              .where((a) => a.date == '10 Jun 2026')
              .map((a) => AttendanceTile(
                    name: a.userName,
                    date: a.date,
                    checkIn: a.checkIn,
                    checkOut: a.checkOut,
                    status: a.status,
                    onEditStatus: () => _editStatus(context, a),
                  )),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  void _editStatus(BuildContext context, MockAttendance a) {
    String? status = a.status;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit: ${a.userName}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
        content: StatefulBuilder(
          builder: (_, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['hadir', 'terlambat', 'alpa', 'izin'].map((s) {
              // ignore: deprecated_member_use
              return RadioListTile<String>(
                value: s,
                // ignore: deprecated_member_use
                groupValue: status,
                title: Text(s[0].toUpperCase() + s.substring(1), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                // ignore: deprecated_member_use
                onChanged: (v) => setDialogState(() => status = v),
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
                SnackBar(content: Text('Status diubah ke $status (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
