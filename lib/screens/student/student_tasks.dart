import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';

/// Daftar Tugas Siswa
class StudentTasks extends StatelessWidget {
  const StudentTasks({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'belum': return AppColors.error;
      case 'dikumpulkan': return AppColors.warning;
      case 'dinilai': return AppColors.success;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'belum': return 'Belum Dikumpulkan';
      case 'dikumpulkan': return 'Dikumpulkan';
      case 'dinilai': return 'Dinilai';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'belum': return Icons.warning_rounded;
      case 'dikumpulkan': return Icons.check_rounded;
      case 'dinilai': return Icons.grading_rounded;
      default: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockData.tasks.length,
        itemBuilder: (context, index) {
          final t = MockData.tasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showTaskDetail(context, t),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(t.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon(t.status), size: 14, color: _statusColor(t.status)),
                              const SizedBox(width: 4),
                              Text(_statusLabel(t.status), style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(t.status))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(t.teacherName, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                        const Spacer(),
                        Icon(Icons.event_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('Deadline: ${t.deadline}', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    if (t.score != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.success, size: 18),
                            const SizedBox(width: 6),
                            Text('Nilai: ${t.score}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                            if (t.feedback != null) ...[
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: AppColors.success)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(t.feedback!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.success), overflow: TextOverflow.ellipsis)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTaskDetail(BuildContext context, MockTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text(task.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(task.description, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            _detailRow(Icons.person_rounded, 'Guru', task.teacherName),
            _detailRow(Icons.event_rounded, 'Deadline', task.deadline),
            _detailRow(Icons.info_rounded, 'Status', _statusLabel(task.status)),
            if (task.score != null) _detailRow(Icons.star_rounded, 'Nilai', '${task.score}'),
            if (task.feedback != null) _detailRow(Icons.comment_rounded, 'Feedback', task.feedback!),
            const SizedBox(height: 24),
            if (task.status == 'belum')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Tugas berhasil dikumpulkan (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Kumpulkan Tugas'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600))),
        ],
      ),
    );
  }
}
