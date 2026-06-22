import 'package:flutter/material.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Laporan Kehadiran'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Fitur Laporan Kehadiran sedang dalam pengembangan.',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
