import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class TeacherQuizDetailScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const TeacherQuizDetailScreen({super.key, required this.quiz});

  @override
  State<TeacherQuizDetailScreen> createState() => _TeacherQuizDetailScreenState();
}

class _TeacherQuizDetailScreenState extends State<TeacherQuizDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final submissions = await SupabaseService.getQuizSubmissions(widget.quiz['id']);
      if (mounted) {
        setState(() {
          _submissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat submissions: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz['title'] ?? 'Detail Kuis')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _submissions.isEmpty
          ? const Center(child: Text('Belum ada siswa yang mengumpulkan'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                final sub = _submissions[index];
                final studentName = sub['students']?['profiles']?['full_name'] ?? 'Siswa';
                final isGraded = sub['score'] != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(studentName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    subtitle: Text(isGraded ? 'Nilai: ${sub['score']}' : 'Menunggu Penilaian'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showGradingSheet(sub),
                  ),
                );
              },
            ),
    );
  }

  void _showGradingSheet(Map<String, dynamic> submission) {
    final scoreCtrl = TextEditingController(text: submission['score']?.toString() ?? '');
    bool isSaving = false;
    final answers = submission['quiz_answers'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Beri Nilai', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                
                // Show answers
                if (answers.isNotEmpty) ...[
                  const Text('Jawaban Siswa:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: answers.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('- ${a['answer_text']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: scoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (scoreCtrl.text.isEmpty) return;
                      setStateModal(() => isSaving = true);
                      try {
                        await SupabaseService.gradeQuizSubmission(
                          submissionId: submission['id'],
                          score: int.parse(scoreCtrl.text),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _fetchSubmissions();
                      } catch (e) {
                        setStateModal(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan nilai: $e')));
                      }
                    },
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Nilai'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
