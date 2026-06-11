import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../widgets/attendance_tile.dart';
import '../../theme/app_theme.dart';

/// Riwayat Absensi Siswa
class StudentAttendance extends StatelessWidget {
  const StudentAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    final attendances = MockData.attendances
        .where((a) => a.userName == 'Andi Pratama')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('18', 'Hadir', Colors.white),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _buildSummaryItem('3', 'Terlambat', Colors.white),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _buildSummaryItem('1', 'Alpa', Colors.white),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _buildSummaryItem('1', 'Izin', Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // List
          ...attendances.map((a) => AttendanceTile(
                name: a.userName,
                date: a.date,
                checkIn: a.checkIn,
                checkOut: a.checkOut,
                status: a.status,
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}
