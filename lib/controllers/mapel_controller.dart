import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class MapelController extends ChangeNotifier {
  bool isLoading = true;
  List<Map<String, dynamic>> materiList = [];
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> attendances = [];
  Map<String, dynamic>? schedule;
  String? errorMessage;

  Future<void> loadDashboardData(String scheduleId, String classId, String role) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final schedules = await SupabaseService.getSchedules();
      schedule = schedules.firstWhere(
        (s) => s['id'] == scheduleId,
        orElse: () => <String, dynamic>{},
      );

      final results = await Future.wait([
        role == 'teacher'
            ? SupabaseService.getScheduleAttendances(scheduleId)
            : SupabaseService.getMeetingsWithAttendances(scheduleId),
        SupabaseService.getMaterials(scheduleId),
        SupabaseService.getTasks(scheduleId),
      ]);

      attendances = results[0];
      materiList = results[1];
      tasks = results[2];
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasTeacherStartedClass(String scheduleId) async {
    return await SupabaseService.hasTeacherStartedClass(scheduleId);
  }

  void showAddMaterialDialog(BuildContext context, String scheduleId) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form tambah materi (coming soon)')));
  }

  void showAddTaskDialog(BuildContext context, String scheduleId) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form tambah tugas (coming soon)')));
  }

  void showIzinForm(BuildContext context, String scheduleId) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form izin (coming soon)')));
  }

  void showRangkumanDialog(BuildContext context, String scheduleId) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form rangkuman (coming soon)')));
  }
}
