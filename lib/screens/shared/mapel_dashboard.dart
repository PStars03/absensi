import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

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
        widget.role == 'teacher'
            ? SupabaseService.getScheduleAttendances(widget.scheduleId)
            : SupabaseService.getMeetingsWithAttendances(widget.scheduleId),
        SupabaseService.getMaterials(widget.scheduleId),
        SupabaseService.getTasks(widget.scheduleId),
      ]);

      if (mounted) {
        setState(() {
          _schedule = schedule;
          _attendances = results[0];
          _materials = results[1];
          _tasks = results[2];
          _isLoading = false;
        });
        
        // Schedule deadline notifications for students
        if (widget.role == 'student') {
          for (var t in _tasks) {
            if (t['due_date'] != null) {
              final due = DateTime.parse(t['due_date']).toLocal();
              // Create a unique numeric ID for the notification based on task ID string
              final notifId = t['id'].hashCode;
              NotificationService.scheduleDeadlineNotification(
                notifId, 
                '⏰ Pengingat Deadline Tugas', 
                'Tugas "${t['title']}" akan ditutup dalam 5 menit!', 
                due
              );
            }
          }
        }
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

  bool _isTimeAllowed(bool isCheckOut) {
    if (_schedule == null || _schedule!.isEmpty) return false;
    final dayStr = _schedule!['day'] ?? '';
    final startStr = _schedule!['start_time'] ?? '';
    final endStr = _schedule!['end_time'] ?? '';
    
    final todayInt = DateTime.now().weekday;
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayStr = todayInt >= 1 && todayInt <= 7 ? days[todayInt - 1] : '';
    
    if (dayStr.trim().toLowerCase() != todayStr.trim().toLowerCase()) return false;
    
    try {
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;
      
      final startParts = startStr.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      
      final endParts = endStr.split(':');
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      
      // Allow 30 minutes before class starts
      final allowedStart = startMinutes - 30;
      
      if (isCheckOut) {
        return nowMinutes >= allowedStart;
      } else {
        return nowMinutes >= allowedStart && nowMinutes <= endMinutes;
      }
    } catch (e) {
      return false; 
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
              expandedHeight: widget.role == 'student' ? 280 : 230,
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
                                if (!_isTimeAllowed(false)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum waktunya jadwal kelas ini.')));
                                  return;
                                }
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
                              onPressed: () async {
                                if (!_isTimeAllowed(true)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal kelas belum dimulai.')));
                                  return;
                                }
                                await Navigator.pushNamed(context, '/face-scan', arguments: {
                                  'type': 'pulang',
                                  'scheduleId': widget.scheduleId,
                                });

                                if (widget.role == 'teacher' && context.mounted) {
                                  _showRangkumanDialog();
                                }
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
                      if (widget.role == 'student') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showIzinForm,
                            icon: const Icon(Icons.edit_document),
                            label: const Text('Ajukan Izin / Sakit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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
  // Absensi & Izin
  // =========================================================================

  void _showIzinForm() {
    File? suratIzinFile;
    File? fotoOrtuFile;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return SingleChildScrollView(
            child: Padding(
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
                const Text('Pengajuan Izin / Sakit', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                
                // Surat Izin
                const Text('Lampirkan Surat Izin/Sakit (Foto)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(type: FileType.image);
                    if (result != null) setStateModal(() => suratIzinFile = File(result.files.single.path!));
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(suratIzinFile != null ? '✅ Surat Terlampir' : 'Pilih Foto Surat'),
                ),
                const SizedBox(height: 16),

                // Foto Ortu
                const Text('Foto Bersama Orang Tua/Wali', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(type: FileType.image);
                    if (result != null) setStateModal(() => fotoOrtuFile = File(result.files.single.path!));
                  },
                  icon: const Icon(Icons.family_restroom_rounded),
                  label: Text(fotoOrtuFile != null ? '✅ Foto Terlampir' : 'Pilih Foto Bersama'),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving || suratIzinFile == null || fotoOrtuFile == null ? null : () async {
                      setStateModal(() => isSaving = true);
                      try {
                        final studentId = SupabaseService.currentUser!.id;
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        
                        final suratBytes = await suratIzinFile!.readAsBytes();
                        final ortuBytes = await fotoOrtuFile!.readAsBytes();

                        final suratExt = suratIzinFile!.path.split('.').last;
                        final ortuExt = fotoOrtuFile!.path.split('.').last;

                        final suratUrl = await SupabaseService.uploadFile(
                          bucket: 'attendance_docs',
                          path: '${widget.scheduleId}/${studentId}_surat_$timestamp.$suratExt',
                          fileBytes: suratBytes,
                        );

                        final ortuUrl = await SupabaseService.uploadFile(
                          bucket: 'attendance_docs',
                          path: '${widget.scheduleId}/${studentId}_ortu_$timestamp.$ortuExt',
                          fileBytes: ortuBytes,
                        );

                        await SupabaseService.checkInIzin(
                          scheduleId: widget.scheduleId,
                          suratIjinUrl: suratUrl,
                          fotoBersamaOrtuUrl: ortuUrl,
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin berhasil diajukan')));
                        _fetchData();
                      } catch (e) {
                        setStateModal(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengajukan izin: $e')));
                      }
                    },
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Ajukan Izin'),
                  ),
                ),
              ],
            ),
            ),
          );
        }
      ),
    );
  }

  void _showRangkumanDialog() {
    final summaryCtrl = TextEditingController();
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
                const Text('Rangkuman Pertemuan', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Silakan isi rangkuman materi untuk pertemuan ini.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Rangkuman Materi', alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (summaryCtrl.text.isEmpty) return;
                      setStateModal(() => isSaving = true);
                      try {
                        await SupabaseService.addMeetingSummary(widget.scheduleId, summaryCtrl.text);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rangkuman berhasil disimpan')));
                        _fetchData();
                      } catch (e) {
                        setStateModal(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan rangkuman: $e')));
                      }
                    },
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildAbsensiTab() {
    if (_attendances.isEmpty) {
      return Center(child: Text(widget.role == 'teacher' ? 'Belum ada data absensi' : 'Belum ada data pertemuan', style: const TextStyle(fontFamily: 'Poppins')));
    }

    if (widget.role == 'student') {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attendances.length,
        itemBuilder: (context, index) {
          final m = _attendances[index];
          final pertemuan = m['meeting_number'] ?? '-';
          final date = m['date'] ?? '-';
          final mapel = m['schedules']?['mapel_name'] ?? '-';
          final summary = m['summary'] ?? 'Tidak ada rangkuman';
          final status = m['status'] ?? 'alpa';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pertemuan $pertemuan', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$date • $mapel', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  const Text('Rangkuman:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(summary, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        },
      );
    }

    // Teacher View (Absensi List)
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
            onTap: widget.role == 'teacher' ? () => _showEditAttendanceDialog(a) : null,
          ),
        );
      },
    );
  }

  void _showEditAttendanceDialog(Map<String, dynamic> attendance) {
    String currentStatus = attendance['status'] ?? 'hadir';
    final userName = attendance['profiles']?['full_name'] ?? 'Siswa';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Ubah Absensi: $userName', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: currentStatus,
                  decoration: const InputDecoration(labelText: 'Status Kehadiran'),
                  items: const [
                    DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                    DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateModal(() => currentStatus = val);
                  },
                ),
                if ((attendance['surat_ijin_url'] != null || attendance['foto_bersama_ortu_url'] != null) && (currentStatus == 'izin' || currentStatus == 'sakit')) ...[
                  const SizedBox(height: 16),
                  const Text('Lampiran Izin/Sakit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (attendance['surat_ijin_url'] != null)
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(attendance['surat_ijin_url']),
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Lihat Surat Izin'),
                    ),
                  if (attendance['foto_bersama_ortu_url'] != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(attendance['foto_bersama_ortu_url']),
                      icon: const Icon(Icons.family_restroom_rounded),
                      label: const Text('Lihat Foto Bersama Ortu'),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await SupabaseService.upsertAttendanceStatus(
                          attendanceId: attendance['id'],
                          userId: attendance['user_id'],
                          scheduleId: widget.scheduleId,
                          status: currentStatus,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diperbarui')));
                        _fetchData();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
                      }
                    },
                    child: const Text('Simpan Perubahan'),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tenggat: $deadlineStr\n${t['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                if (t['file_url'] != null)
                  InkWell(
                    onTap: () => _openUrl(t['file_url']),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('📎 Lihat Lampiran', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
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
    File? selectedFile;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return SingleChildScrollView(
            child: Padding(
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx']);
                    if (result != null) {
                      setStateModal(() => selectedFile = File(result.files.single.path!));
                    }
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(selectedFile != null ? selectedFile!.path.split(Platform.pathSeparator).last : 'Lampirkan File (Opsional)'),
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
                        String? fileUrl;
                        if (selectedFile != null) {
                          final ext = selectedFile!.path.split('.').last.toLowerCase();
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
                          final bytes = await selectedFile!.readAsBytes();
                          
                          fileUrl = await SupabaseService.uploadFile(
                            bucket: 'tasks',
                            path: '${widget.scheduleId}/$fileName',
                            fileBytes: bytes,
                          );
                        }

                        final deadline = DateTime(
                          selectedDate!.year, selectedDate!.month, selectedDate!.day,
                          selectedTime!.hour, selectedTime!.minute,
                        );

                        await SupabaseService.addTask(
                          scheduleId: widget.scheduleId,
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          deadline: deadline,
                          fileUrl: fileUrl,
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
          return SingleChildScrollView(
            child: Padding(
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
                        if (!context.mounted) return;
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
                          if (!context.mounted) return;
                          setStateModal(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
                        }
                      },
                      child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kumpulkan Tugas'),
                    ),
                  ),
                ],
              ],
            ),
            ),
          );
        }
      ),
    );
  }



  // =========================================================================
  // Utilities
  // =========================================================================

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka URL: $e')));
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
