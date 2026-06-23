import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminClassesScreen extends StatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  State<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends State<AdminClassesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getClasses();
      final locations = await SupabaseService.getAttendanceLocations();
      if (mounted) {
        setState(() {
          _classes = data;
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat kelas: $e')));
      }
    }
  }

  void _showAddClassModal() {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2025/2026');
    String? selectedLocationId;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Kelas Baru', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Kelas (mis: 10 IPA 1)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelCtrl,
                decoration: const InputDecoration(labelText: 'Tingkat (mis: 10, 11, 12)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: 'Tahun Ajaran'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedLocationId,
                decoration: const InputDecoration(labelText: 'Lokasi Absensi'),
                items: _locations.map((loc) {
                  return DropdownMenuItem<String>(
                    value: loc['id'],
                    child: Text(loc['name']),
                  );
                }).toList(),
                onChanged: (val) => setStateModal(() => selectedLocationId = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameCtrl.text.isEmpty || levelCtrl.text.isEmpty || yearCtrl.text.isEmpty || selectedLocationId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua form dan lokasi harus diisi!')));
                      return;
                    }
                    setStateModal(() => isSaving = true);
                    try {
                      await SupabaseService.createClass(
                        name: nameCtrl.text.trim(),
                        level: levelCtrl.text.trim(),
                        academicYear: yearCtrl.text.trim(),
                        locationId: selectedLocationId!,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      _fetchClasses();
                    } catch (e) {
                      setStateModal(() => isSaving = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan kelas: $e')));
                    }
                  },
                  child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Kelas', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(child: Text('Belum ada data kelas', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _classes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cls = _classes[index];
                    return InkWell(
                      onTap: () => Navigator.pushNamed(context, '/admin-class-detail', arguments: cls).then((_) => _fetchClasses()),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.school_rounded, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cls['name'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('Tingkat: ${cls['level']} • TA: ${cls['academic_year']}', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600)),
                                  const SizedBox(height: 2),
                                  Text('Lokasi: ${cls['attendance_locations']?['name'] ?? 'Belum disetel'}', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primaryBlue)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassModal,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
