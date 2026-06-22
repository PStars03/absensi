import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = true;
  
  Map<String, dynamic>? _schedule;
  List<Map<String, dynamic>> _attendances = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch schedule info
      final schedules = await SupabaseService.getSchedules();
      final schedule = schedules.firstWhere(
        (s) => s['id'] == widget.scheduleId,
        orElse: () => <String, dynamic>{},
      );
      
      // Fetch tab data
      final results = await Future.wait([
        SupabaseService.getScheduleAttendances(widget.scheduleId),
        SupabaseService.getMaterials(widget.scheduleId),
        SupabaseService.getTasks(widget.scheduleId),
        SupabaseService.getQuizzes(widget.scheduleId),
      ]);

      if (mounted) {
        setState(() {
          _schedule = schedule;
          _attendances = results[0];
          _materials = results[1];
          _tasks = results[2];
          _quizzes = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mapelName = _schedule?['subjects']?['name'] ?? 'Mata Pelajaran';
    final teacherName = _schedule?['profiles']?['full_name'] ?? 'Guru';
    final className = _schedule?['classes']?['name'] ?? 'Kelas';

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
                        mapelName,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$teacherName • $className',
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
        body: RefreshIndicator(
          onRefresh: _fetchData,
          child: _buildBodyContent(),
        ),
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

    IconData icon;
    String tooltip;
    VoidCallback onPressed;

    switch (_currentIndex) {
      case 1:
        icon = Icons.upload_file_rounded;
        tooltip = 'Tambah Materi';
        onPressed = () => _showAddMaterialDialog();
        break;
      case 2:
        icon = Icons.add_task_rounded;
        tooltip = 'Buat Tugas';
        onPressed = () => _showAddTaskDialog();
        break;
      case 3:
        icon = Icons.post_add_rounded;
        tooltip = 'Buat Kuis';
        onPressed = () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kuis coming soon di Phase 3')));
        };
        break;
      default:
        return null;
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  // =========================================================================
  // Absensi
  // =========================================================================

  Widget _buildAbsensiTab() {
    if (_attendances.isEmpty) {
      return const Center(child: Text('Belum ada data absensi', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendances.length,
      itemBuilder: (context, index) {
        final a = _attendances[index];
        final userName = a['profiles']?['full_name'] ?? 'User';
        final checkIn = a['check_in']?.toString().substring(0, 5) ?? '-';
        final checkOut = a['check_out'] != null ? a['check_out'].toString().substring(0, 5) : '-';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(userName.isNotEmpty ? userName[0] : '?', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ),
            title: Text(userName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('${a['date']} • Masuk: $checkIn ${checkOut != "-" ? "• Pulang: $checkOut" : ""}', style: const TextStyle(fontSize: 12)),
            trailing: _buildStatusBadge(a['status'] ?? 'hadir'),
          ),
        );
      },
    );
  }

  // =========================================================================
  // Materi
  // =========================================================================

  Widget _buildMateriTab() {
    if (_materials.isEmpty) {
      return const Center(child: Text('Belum ada materi', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final m = _materials[index];
        final isPdf = m['file_type'] == 'pdf';
        final iconColor = isPdf ? const Color(0xFFEF4444) : const Color(0xFF6366F1);
        final iconData = isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text(m['title'] ?? 'Tanpa Judul', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text(m['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: m['file_url'] != null ? IconButton(
              icon: const Icon(Icons.download_rounded),
              color: AppColors.primaryBlue,
              onPressed: () => _openUrl(m['file_url']),
            ) : null,
          ),
        );
      },
    );
  }

  void _showAddMaterialDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    File? selectedFile;
    bool isUploading = false;

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
                const Text('Tambah Materi', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Materi', prefixIcon: Icon(Icons.title_rounded))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_rounded)), maxLines: 3),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx']);
                    if (result != null) {
                      setStateModal(() => selectedFile = File(result.files.single.path!));
                    }
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(selectedFile != null ? selectedFile!.path.split(Platform.pathSeparator).last : 'Lampirkan File (PDF/Doc)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : () async {
                      if (titleCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong')));
                        return;
                      }

                      setStateModal(() => isUploading = true);

                      try {
                        String? fileUrl;
                        String fileType = 'doc';
                        if (selectedFile != null) {
                          final ext = selectedFile!.path.split('.').last.toLowerCase();
                          fileType = ext == 'pdf' ? 'pdf' : 'doc';
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
                          final bytes = await selectedFile!.readAsBytes();
                          
                          fileUrl = await SupabaseService.uploadFile(
                            bucket: 'materials',
                            path: '${widget.scheduleId}/$fileName',
                            fileBytes: bytes,
                          );
                        }

                        await SupabaseService.addMaterial(
                          scheduleId: widget.scheduleId,
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          fileUrl: fileUrl,
                          fileType: fileType,
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _fetchData(); // Refresh data
                      } catch (e) {
                        setStateModal(() => isUploading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
                      }
                    },
                    child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // =========================================================================
  // Tugas
  // =========================================================================

  Widget _buildTugasTab() {
    if (_tasks.isEmpty) {
      return const Center(child: Text('Belum ada tugas', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final t = _tasks[index];
        final deadlineStr = t['deadline'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(t['deadline'])) : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(t['title'] ?? 'Tugas', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            subtitle: Text('Tenggat: $deadlineStr\n${t['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showTaskDetails(t),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isSaving = false;

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
                const Text('Buat Tugas Baru', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas', prefixIcon: Icon(Icons.title_rounded))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi / Instruksi', prefixIcon: Icon(Icons.description_rounded)), maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (date != null) setStateModal(() => selectedDate = date);
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'Pilih Tanggal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) setStateModal(() => selectedTime = time);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(selectedTime != null ? selectedTime!.format(context) : 'Pilih Jam'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (titleCtrl.text.isEmpty || selectedDate == null || selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Tenggat harus diisi')));
                        return;
                      }

                      setStateModal(() => isSaving = true);

                      try {
                        final deadline = DateTime(
                          selectedDate!.year, selectedDate!.month, selectedDate!.day,
                          selectedTime!.hour, selectedTime!.minute,
                        );

                        await SupabaseService.addTask(
                          scheduleId: widget.scheduleId,
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          deadline: deadline,
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _fetchData();
                      } catch (e) {
                        setStateModal(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat tugas: $e')));
                      }
                    },
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Buat Tugas'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    if (widget.role == 'teacher') {
      _showTeacherTaskSubmissions(task);
    } else {
      _showStudentTaskSubmissionForm(task);
    }
  }

  Future<void> _showTeacherTaskSubmissions(Map<String, dynamic> task) async {
    // Navigate to a new screen or show bottom sheet to see submissions
    // For simplicity, showing a bottom sheet
    final submissions = await SupabaseService.getTaskSubmissions(task['id']);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengumpulan: ${task['title']}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Expanded(
              child: submissions.isEmpty 
                ? const Center(child: Text('Belum ada siswa yang mengumpulkan'))
                : ListView.builder(
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final sub = submissions[index];
                      final studentName = sub['students']?['profiles']?['full_name'] ?? 'Siswa';
                      final score = sub['score'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(score != null ? 'Nilai: $score' : 'Belum dinilai'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download_rounded, color: AppColors.primaryBlue),
                                onPressed: () => _openUrl(sub['file_url']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.grade_rounded, color: AppColors.warning),
                                onPressed: () => _showGradingDialog(sub),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradingDialog(Map<String, dynamic> submission) {
    final scoreCtrl = TextEditingController(text: submission['score']?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: submission['feedback'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Beri Nilai', style: TextStyle(fontFamily: 'Poppins')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: scoreCtrl, 
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackCtrl, 
                  decoration: const InputDecoration(labelText: 'Feedback'),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setStateDialog(() => isSaving = true);
                  try {
                    await SupabaseService.gradeTaskSubmission(
                      submissionId: submission['id'],
                      score: int.parse(scoreCtrl.text),
                      feedback: feedbackCtrl.text,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    Navigator.pop(context); // Close submissions sheet to refresh
                    if (!mounted) return;
                    _fetchData(); // Refresh tasks count or status if needed
                  } catch (e) {
                    setStateDialog(() => isSaving = false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menilai: $e')));
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showStudentTaskSubmissionForm(Map<String, dynamic> task) async {
    final submission = await SupabaseService.getMyTaskSubmission(task['id']);
    File? selectedFile;
    bool isUploading = false;

    if (!mounted) return;

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
                Text(task['title'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(task['description'] ?? '', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade600)),
                const SizedBox(height: 24),

                if (submission != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: submission['score'] != null ? AppColors.success.withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: submission['score'] != null ? AppColors.success : AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Text('Sudah Dikumpulkan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: submission['score'] != null ? AppColors.success : AppColors.primaryBlue)),
                          ],
                        ),
                        if (submission['score'] != null) ...[
                          const SizedBox(height: 8),
                          Text('Nilai: ${submission['score']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (submission['feedback'] != null) Text('Komentar: ${submission['feedback']}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openUrl(submission['file_url']),
                      icon: const Icon(Icons.file_open_rounded),
                      label: const Text('Lihat File yang Dikumpulkan'),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles();
                      if (result != null) {
                        setStateModal(() => selectedFile = File(result.files.single.path!));
                      }
                    },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(selectedFile != null ? selectedFile!.path.split(Platform.pathSeparator).last : 'Pilih File Tugas'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUploading || selectedFile == null ? null : () async {
                        setStateModal(() => isUploading = true);
                        try {
                          final ext = selectedFile!.path.split('.').last.toLowerCase();
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
                          final bytes = await selectedFile!.readAsBytes();
                          
                          final fileUrl = await SupabaseService.uploadFile(
                            bucket: 'submissions',
                            path: '${task['id']}/${SupabaseService.currentUser!.id}_$fileName',
                            fileBytes: bytes,
                          );

                          await SupabaseService.submitTask(
                            taskId: task['id'],
                            fileUrl: fileUrl,
                          );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas berhasil dikumpulkan')));
                          if (!mounted) return;
                          _fetchData();
                        } catch (e) {
                          setStateModal(() => isUploading = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload tugas: $e')));
                        }
                      },
                      child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kumpulkan Tugas'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  // =========================================================================
  // Kuis
  // =========================================================================

  Widget _buildKuisTab() {
    return Column(
      children: [
        if (widget.role == 'teacher')
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddQuizForm,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Buat Kuis Baru'),
              ),
            ),
          ),
        Expanded(
          child: _quizzes.isEmpty
              ? const Center(child: Text('Belum ada kuis', style: TextStyle(fontFamily: 'Poppins')))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final q = _quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          child: const Icon(Icons.quiz_rounded, color: Color(0xFF6366F1)),
                        ),
                        title: Text(q['title'] ?? 'Kuis', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        subtitle: Text('${q['duration_minutes']} menit • Due: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(q['due_date']).toLocal())}', style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showQuizDetails(q),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddQuizForm() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');
    bool isSaving = false;

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
                const Text('Buat Kuis Baru', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Kuis')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
                const SizedBox(height: 12),
                TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Durasi (menit)')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (titleCtrl.text.isEmpty || durationCtrl.text.isEmpty) return;
                      setStateModal(() => isSaving = true);
                      try {
                        // Dummy single essay question for demonstration
                        final dummyQuestion = {
                          'question_text': 'Jelaskan pemahaman Anda mengenai materi ini!',
                          'question_type': 'essay',
                          'points': 100,
                        };

                        await SupabaseService.createQuiz(
                          scheduleId: widget.scheduleId,
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          durationMinutes: int.parse(durationCtrl.text),
                          dueDate: DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String(), // Due tomorrow
                          questions: [dummyQuestion],
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _fetchData();
                      } catch (e) {
                        setStateModal(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat kuis: $e')));
                      }
                    },
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan & Buat Kuis'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showQuizDetails(Map<String, dynamic> quiz) {
    if (widget.role == 'teacher') {
      Navigator.pushNamed(context, '/teacher-quiz-detail', arguments: quiz);
    } else {
      Navigator.pushNamed(context, '/student-quiz-attempt', arguments: quiz);
    }
  }

  // =========================================================================
  // Utilities
  // =========================================================================

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka URL')));
    }
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
