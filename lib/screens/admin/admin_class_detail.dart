import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const AdminClassDetailScreen({super.key, required this.classData});

  @override
  State<AdminClassDetailScreen> createState() => _AdminClassDetailScreenState();
}

class _AdminClassDetailScreenState extends State<AdminClassDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getClassStudents(widget.classData['id']);
      if (mounted) {
        setState(() {
          _students = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat siswa: $e')));
      }
    }
  }

  void _showAddStudentModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddStudentToClassSheet(
        classId: widget.classData['id'],
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchStudents();
        },
      ),
    );
  }

  Future<void> _removeStudent(String studentId) async {
    try {
      await SupabaseService.removeStudentFromClass(studentId);
      _fetchStudents();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siswa dikeluarkan dari kelas')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kelas ${widget.classData['name']}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryBlue),
            onPressed: _showAddStudentModal,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('Belum ada siswa di kelas ini', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _students.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final profile = student['profiles'] ?? {};
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile['full_name'] ?? 'Siswa', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('NIS: ${student['nis'] ?? '-'}', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                            onPressed: () => _removeStudent(student['id']),
                            tooltip: 'Keluarkan Siswa',
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddStudentToClassSheet extends StatefulWidget {
  final String classId;
  final VoidCallback onSuccess;

  const _AddStudentToClassSheet({required this.classId, required this.onSuccess});

  @override
  State<_AddStudentToClassSheet> createState() => _AddStudentToClassSheetState();
}

class _AddStudentToClassSheetState extends State<_AddStudentToClassSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _unassignedStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchUnassigned();
  }

  Future<void> _fetchUnassigned() async {
    try {
      final data = await SupabaseService.getUnassignedStudents();
      if (mounted) {
        setState(() {
          _unassignedStudents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assign(String studentId) async {
    try {
      await SupabaseService.assignStudentToClass(studentId, widget.classId);
      widget.onSuccess();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah Siswa ke Kelas', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Text('Berikut adalah daftar siswa yang belum memiliki kelas:', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_unassignedStudents.isEmpty)
            const Center(child: Text('Semua siswa sudah memiliki kelas', style: TextStyle(fontFamily: 'Poppins')))
          else
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: _unassignedStudents.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final student = _unassignedStudents[index];
                  final profile = student['profiles'] ?? {};
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(profile['full_name'] ?? 'Siswa', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    subtitle: Text('NIS: ${student['nis'] ?? '-'}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                    trailing: ElevatedButton(
                      onPressed: () => _assign(student['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                      child: const Text('Tambah'),
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
