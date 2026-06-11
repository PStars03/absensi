import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  static User? get currentUser => _client.auth.currentUser;

  // --- Auth Methods ---

  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? identityNumber,
    String? className,
  }) async {
    final Map<String, dynamic> authData = {
      'full_name': fullName,
      'role': role,
    };

    if (identityNumber != null) authData['identity_number'] = identityNumber;
    if (className != null) authData['class_name'] = className;

    return await _client.auth.signUp(
      email: email,
      password: password,
      data: authData,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --- Profile Methods ---
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  // --- Attendance Methods ---

  static Future<void> checkIn(String scheduleId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    final today = DateTime.now().toIso8601String().split('T').first;
    final currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00";

    await _client.from('attendances').upsert({
      'schedule_id': scheduleId,
      'user_id': user.id,
      'date': today,
      'check_in': currentTime,
      'status': 'hadir',
    });
  }

  static Future<void> checkOut(String scheduleId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    final today = DateTime.now().toIso8601String().split('T').first;
    final currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00";

    await _client.from('attendances').update({
      'check_out': currentTime,
    }).eq('schedule_id', scheduleId)
      .eq('user_id', user.id)
      .eq('date', today);
  }

  // --- Schedule Methods ---
  static Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await _client.from('schedules').select('''
      *,
      profiles:teacher_id ( full_name )
    ''').order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Fetch Methods for Dashboard ---
  static Future<List<Map<String, dynamic>>> getMyAttendances() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _client.from('attendances').select('''
      *,
      schedules:schedule_id ( mapel_name ),
      profiles:user_id ( full_name )
    ''').eq('user_id', user.id).order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getScheduleAttendances(String scheduleId) async {
    final response = await _client.from('attendances').select('''
      *,
      profiles:user_id ( full_name )
    ''').eq('schedule_id', scheduleId).order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
