import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminScheduleFormScreen extends StatefulWidget {
  const AdminScheduleFormScreen({super.key});

  @override
  State<AdminScheduleFormScreen> createState() => _AdminScheduleFormScreenState();
}

class _AdminScheduleFormScreenState extends State<AdminScheduleFormScreen> {
  bool _isLoadingData = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _teachers = [];

  String? _selectedClassId;
  String? _selectedTeacherProfileId;
  
  final _mapelCtrl = TextEditingController();
  final _dayCtrl = TextEditingController(text: 'Senin');
  final _startCtrl = TextEditingController(text: '08:00');
  final _endCtrl = TextEditingController(text: '09:30');
  final _roomCtrl = TextEditingController();

  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final classes = await SupabaseService.getClasses();
      final teachers = await SupabaseService.getAllTeachers(); // From 'teachers' table with profiles
      if (mounted) {
        setState(() {
          _classes = classes;
          _teachers = teachers;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data form: $e')));
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedClassId == null || _selectedTeacherProfileId == null || _mapelCtrl.text.isEmpty || _startCtrl.text.isEmpty || _endCtrl.text.isEmpty || _roomCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua field')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.createSchedule(
        classId: _selectedClassId!,
        teacherProfileId: _selectedTeacherProfileId!,
        mapelName: _mapelCtrl.text.trim(),
        day: _dayCtrl.text,
        startTime: _startCtrl.text.trim(),
        endTime: _endCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal berhasil disimpan')));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          duration: const Duration(seconds: 5),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Jadwal Baru', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Kelas', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _classes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text('${c['name']} (Tingkat ${c['level']})', style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                    onChanged: (v) => setState(() => _selectedClassId = v),
                    hint: const Text('Pilih Kelas'),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Pilih Guru', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTeacherProfileId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _teachers.map((t) {
                      final profile = t['profiles'] ?? {};
                      return DropdownMenuItem(value: t['profile_id'].toString(), child: Text('${profile['full_name']} (NIP: ${t['nip']})', style: const TextStyle(fontFamily: 'Poppins')));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedTeacherProfileId = v),
                    hint: const Text('Pilih Guru Pengajar'),
                  ),
                  const SizedBox(height: 16),

                  const Text('Mata Pelajaran', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mapelCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cth: Matematika',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hari', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _dayCtrl.text,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                              onChanged: (v) => setState(() => _dayCtrl.text = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ruangan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _roomCtrl,
                              decoration: InputDecoration(
                                hintText: 'Cth: R. IPA 1',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jam Mulai', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _startCtrl,
                              decoration: InputDecoration(
                                hintText: '08:00',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jam Selesai', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _endCtrl,
                              decoration: InputDecoration(
                                hintText: '09:30',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Jadwal', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
