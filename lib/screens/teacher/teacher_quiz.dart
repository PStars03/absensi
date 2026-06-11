import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';

/// Kelola Kuis (Guru)
class TeacherQuiz extends StatelessWidget {
  const TeacherQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kuis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddQuiz(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Kuis'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockData.quizzes.length,
        itemBuilder: (context, index) {
          final q = MockData.quizzes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (q.type == 'pg' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          q.type == 'pg' ? Icons.quiz_rounded : Icons.edit_note_rounded,
                          color: q.type == 'pg' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${q.questionCount} soal • ${q.durationMinutes} menit', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'results', child: Text('Lihat Hasil')),
                          const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                        onSelected: (v) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$v: ${q.title} (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip('Tipe: ${q.type == 'pg' ? 'Pilihan Ganda' : 'Isian'}'),
                      const SizedBox(width: 8),
                      _chip('Peserta: 28'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
    );
  }

  void _showAddQuiz(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Buat Kuis Baru', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: 'Judul Kuis', prefixIcon: Icon(Icons.quiz_rounded))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipe Kuis', prefixIcon: Icon(Icons.category_rounded)),
              items: const [
                DropdownMenuItem(value: 'pg', child: Text('Pilihan Ganda')),
                DropdownMenuItem(value: 'isian', child: Text('Isian')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Durasi (menit)', prefixIcon: Icon(Icons.timer_rounded)), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Kuis dibuat (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                },
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
