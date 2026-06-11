import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';

/// Halaman Kuis Siswa
class StudentQuiz extends StatelessWidget {
  const StudentQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockData.quizzes.length,
        itemBuilder: (context, index) {
          final q = MockData.quizzes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (q.status == 'belum') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _QuizAttemptScreen(quiz: q),
                  ));
                }
              },
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
                              const SizedBox(height: 2),
                              Text(q.teacherName, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        _buildStatusBadge(q.status, q.score),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _infoChip(Icons.help_outline_rounded, '${q.questionCount} Soal'),
                        const SizedBox(width: 8),
                        _infoChip(Icons.timer_rounded, '${q.durationMinutes} Menit'),
                        const SizedBox(width: 8),
                        _infoChip(Icons.category_rounded, q.type == 'pg' ? 'Pilihan Ganda' : 'Isian'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status, int? score) {
    Color color;
    String label;
    switch (status) {
      case 'belum':
        color = AppColors.error;
        label = 'Mulai';
        break;
      case 'dikerjakan':
        color = AppColors.warning;
        label = 'Proses';
        break;
      case 'dinilai':
        color = AppColors.success;
        label = score != null ? '$score' : 'Dinilai';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Halaman mengerjakan kuis (mock)
class _QuizAttemptScreen extends StatefulWidget {
  final MockQuiz quiz;

  const _QuizAttemptScreen({required this.quiz});

  @override
  State<_QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<_QuizAttemptScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  final List<MockQuizQuestion> _questions = MockData.sampleQuizQuestions;

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soal ${_currentIndex + 1}/${_questions.length}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${widget.quiz.durationMinutes}:00', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),

            // Question
            Text(q.question, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // Answer options
            if (q.type == 'pg' && q.options != null)
              ...q.options!.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _answers[_currentIndex] = e.value),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _answers[_currentIndex] == e.value
                              ? AppColors.primaryBlue.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _answers[_currentIndex] == e.value
                                ? AppColors.primaryBlue
                                : AppColors.cardBorder,
                            width: _answers[_currentIndex] == e.value ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _answers[_currentIndex] == e.value
                                    ? AppColors.primaryBlue
                                    : AppColors.background,
                                border: Border.all(
                                  color: _answers[_currentIndex] == e.value
                                      ? AppColors.primaryBlue
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + e.key),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _answers[_currentIndex] == e.value
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14))),
                          ],
                        ),
                      ),
                    ),
                  ))
            else
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tulis jawaban di sini...',
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => _answers[_currentIndex] = v,
              ),

            const Spacer(),

            // Navigation
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      child: const Text('Sebelumnya'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < _questions.length - 1) {
                        setState(() => _currentIndex++);
                      } else {
                        // Submit
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Selesai!', style: TextStyle(fontFamily: 'Poppins')),
                            content: const Text('Kuis berhasil dikumpulkan.', style: TextStyle(fontFamily: 'Poppins')),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Text(_currentIndex < _questions.length - 1 ? 'Selanjutnya' : 'Kumpulkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
