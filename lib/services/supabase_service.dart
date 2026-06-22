import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  static User? get currentUser => _client.auth.currentUser;

  // ============================================================
  // Auth Methods
  // ============================================================

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

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ============================================================
  // Profile Methods
  // ============================================================

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

  // ============================================================
  // Admin User Management
  // ============================================================

  static Future<void> createUserByAdmin({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String identityNumber,
    String? className,
  }) async {
    final params = {
      'new_email': email,
      'new_password': password,
      'new_full_name': fullName,
      'new_role': role,
      'new_identity_number': identityNumber,
    };
    if (className != null) {
      params['new_class_name'] = className;
    }
    
    await _client.rpc('create_user_by_admin', params: params);
  }

  static Future<void> deleteUserByAdmin(String userId) async {
    await _client.rpc('delete_user_by_admin', params: {
      'target_user_id': userId,
    });
  }


  // ============================================================
  // Student Methods
  // ============================================================

  static Future<Map<String, dynamic>?> getStudentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('students')
          .select('''
            *,
            profiles:profile_id ( full_name, email, role ),
            classes:class_id ( name, level )
          ''')
          .eq('profile_id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasFaceEnrolled() async {
    final profile = await getCurrentUserProfile();
    if (profile == null) return false;

    if (profile['role'] == 'teacher') {
      final data = await getTeacherProfile();
      return data?['face_embedding'] != null;
    } else {
      final data = await getStudentProfile();
      return data?['face_embedding'] != null;
    }
  }

  static Future<void> saveFaceEmbedding(List<double> embedding) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    // Convert List<double> to Float32List, then to Uint8List
    final floatList = Float32List.fromList(embedding);
    final uint8List = floatList.buffer.asUint8List();

    // Convert Uint8List to Postgres BYTEA hex string (\x...)
    final String hexString = '\\x${uint8List.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}';

    final profile = await getCurrentUserProfile();
    if (profile?['role'] == 'teacher') {
      await _client
          .from('teachers')
          .update({'face_embedding': hexString})
          .eq('profile_id', user.id);
    } else {
      await _client
          .from('students')
          .update({'face_embedding': hexString})
          .eq('profile_id', user.id);
    }
  }

  static List<double>? decodeFaceEmbedding(String? hexString) {
    if (hexString == null || !hexString.startsWith('\\x')) return null;
    final hexData = hexString.substring(2);
    if (hexData.isEmpty || hexData.length % 2 != 0) return null;

    final bytes = Uint8List(hexData.length ~/ 2);
    for (int i = 0; i < hexData.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hexData.substring(i, i + 2), radix: 16);
    }
    return Float32List.view(bytes.buffer).toList();
  }

  // ============================================================
  // Teacher Methods
  // ============================================================

  static Future<Map<String, dynamic>?> getTeacherProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('teachers')
          .select('''
            *,
            profiles:profile_id ( full_name, email, role ),
            classes:wali_class_id ( name, level )
          ''')
          .eq('profile_id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // Subjects & Classes Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getSubjects() async {
    final response = await _client.from('subjects').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getClasses() async {
    final response = await _client.from('classes').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // Attendance Methods
  // ============================================================

  static Future<void> checkIn(String scheduleId, {double? latitude, double? longitude, bool faceVerified = false}) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    final today = DateTime.now().toIso8601String().split('T').first;
    final currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00";

    // 1. Cek profil untuk memastikan role
    final profile = await getCurrentUserProfile();
    if (profile?['role'] == 'student') {
      // 2. Ambil data schedule untuk mengetahui siapa teacher_id
      final scheduleData = await _client.from('schedules').select('teacher_id').eq('id', scheduleId).maybeSingle();
      if (scheduleData != null) {
        final teacherId = scheduleData['teacher_id'];
        
        // 3. Cek apakah teacher_id sudah absen (hadir) hari ini
        final teacherAttendance = await _client
            .from('attendances')
            .select('id')
            .eq('schedule_id', scheduleId)
            .eq('user_id', teacherId)
            .eq('date', today)
            .maybeSingle();
            
        if (teacherAttendance == null) {
          throw Exception('Guru belum membuka kelas (belum absen masuk). Anda belum bisa absen.');
        }
      }
    }

    await _client.from('attendances').upsert({
      'schedule_id': scheduleId,
      'user_id': user.id,
      'date': today,
      'check_in': currentTime,
      'status': 'hadir',
      'latitude': latitude,
      'longitude': longitude,
      'face_verified': faceVerified,
    });
  }

  static Future<void> checkInIzin({
    required String scheduleId,
    required String suratIjinUrl,
    required String fotoBersamaOrtuUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    final today = DateTime.now().toIso8601String().split('T').first;
    final currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00";

    await _client.from('attendances').upsert({
      'schedule_id': scheduleId,
      'user_id': user.id,
      'date': today,
      'check_in': currentTime,
      'status': 'izin',
      'surat_ijin_url': suratIjinUrl,
      'foto_bersama_ortu_url': fotoBersamaOrtuUrl,
      'face_verified': false,
    });
  }

  static Future<void> checkOut(String scheduleId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    final today = DateTime.now().toIso8601String().split('T').first;
    final currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00";

    await _client.from('attendances').update({
      'check_out': currentTime,
    }).eq('schedule_id', scheduleId).eq('user_id', user.id).eq('date', today);

    // Auto-Alpa Logic (Only if the person checking out is a teacher)
    try {
      final profile = await getCurrentUserProfile();
      if (profile?['role'] == 'teacher') {
        // 1. Get class_id for this schedule
        final schedule = await _client.from('schedules').select('class_id').eq('id', scheduleId).maybeSingle();
        if (schedule != null) {
          final classId = schedule['class_id'];
          
          // 2. Get all students in this class
          final students = await _client.from('students').select('profile_id').eq('class_id', classId);
          
          // 3. Get existing attendance for today's schedule
          final existingAttendances = await _client.from('attendances')
              .select('user_id')
              .eq('schedule_id', scheduleId)
              .eq('date', today);
          final existingIds = existingAttendances.map((e) => e['user_id']).toSet();

          // 4. Mark un-attended students as Alpa
          for (var s in students) {
            final studentId = s['profile_id'];
            if (!existingIds.contains(studentId)) {
              await _client.from('attendances').upsert({
                'schedule_id': scheduleId,
                'user_id': studentId,
                'date': today,
                'status': 'alpa',
                'face_verified': false,
              });
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors in background Alpa logic to not fail the checkout
      debugPrint('Auto-alpa error: $e');
    }
  }

  static Future<void> updateAttendanceStatus({
    required String attendanceId,
    required String status,
  }) async {
    await _client.from('attendances').update({
      'status': status,
    }).eq('id', attendanceId);
  }


  // ============================================================
  // Attendance Location (GPS) Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAttendanceLocations() async {
    final response = await _client
        .from('attendance_locations')
        .select()
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addAttendanceLocation({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    await _client.from('attendance_locations').insert({
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_active': true,
    });
  }

  static Future<void> updateAttendanceLocation(String id, {
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;
    if (radiusMeters != null) updates['radius_meters'] = radiusMeters;
    if (isActive != null) updates['is_active'] = isActive;

    await _client.from('attendance_locations').update(updates).eq('id', id);
  }

  static Future<void> deleteAttendanceLocation(String id) async {
    await _client.from('attendance_locations').delete().eq('id', id);
  }

  // ============================================================
  // Schedule Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await _client.from('schedules').select('''
      *,
      profiles:teacher_id ( full_name ),
      subjects:subject_id ( code, name ),
      classes:class_id ( name )
    ''').order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // Fetch Methods for Dashboard
  // ============================================================

  static Stream<List<Map<String, dynamic>>> getMyAttendancesStream() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _client
        .from('attendances')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .asyncMap((_) => getMyAttendances());
  }

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

  static Stream<Map<String, int>> getTeacherDashboardStatsStream() {
    final user = currentUser;
    if (user == null) return Stream.value({'total_siswa': 0, 'hadir_hari_ini': 0, 'tugas_aktif': 0});

    // Listen to attendances and tasks (we'll just listen to attendances for simplicity, or we can yield a future first)
    return _client.from('attendances').stream(primaryKey: ['id']).asyncMap((_) async {
      return await getTeacherDashboardStats();
    });
  }

  static Future<Map<String, int>> getTeacherDashboardStats() async {
    final user = currentUser;
    if (user == null) return {'total_siswa': 0, 'hadir_hari_ini': 0, 'tugas_aktif': 0};

    int totalSiswa = 0;
    int hadirHariIni = 0;
    int tugasAktif = 0;

    try {
      // Get teacher id
      final teacher = await getTeacherProfile();
      if (teacher != null) {
        final teacherId = teacher['id'];
        
        // Total Siswa (count all students for simplicity, or students in their wali kelas)
        // Let's just count all students for now
        final studentsRes = await _client.from('students').select('id');
        totalSiswa = studentsRes.length;

        // Hadir hari ini (where teacher teaches the schedule)
        final today = DateTime.now().toIso8601String().split('T').first;
        final schedulesRes = await _client.from('schedules').select('id').eq('teacher_id', teacherId);
        final scheduleIds = schedulesRes.map((e) => e['id']).toList();

        if (scheduleIds.isNotEmpty) {
          final attendancesRes = await _client.from('attendances')
              .select('id')
              .eq('date', today)
              .inFilter('schedule_id', scheduleIds)
              .eq('status', 'hadir');
          hadirHariIni = attendancesRes.length;

          // Tugas aktif
          final tasksRes = await _client.from('tasks')
              .select('id, deadline')
              .inFilter('schedule_id', scheduleIds);
          
          final now = DateTime.now();
          tugasAktif = tasksRes.where((t) {
            final dl = DateTime.tryParse(t['deadline'] ?? '');
            return dl != null && dl.isAfter(now);
          }).length;
        }
      }
    } catch (e) {
      // ignore
    }

    return {
      'total_siswa': totalSiswa,
      'hadir_hari_ini': hadirHariIni,
      'tugas_aktif': tugasAktif,
    };
  }

  static Future<List<Map<String, dynamic>>> getScheduleAttendances(String scheduleId) async {
    final response = await _client.from('attendances').select('''
      *,
      profiles:user_id ( full_name )
    ''').eq('schedule_id', scheduleId).order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // Materials Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getMaterials(String scheduleId) async {
    final response = await _client
        .from('materials')
        .select()
        .eq('schedule_id', scheduleId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addMaterial({
    required String scheduleId,
    required String title,
    String? description,
    String? fileUrl,
    String? fileType,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    final teacher = await getTeacherProfile();

    await _client.from('materials').insert({
      'schedule_id': scheduleId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_type': fileType ?? 'doc',
      'teacher_id': teacher?['id'],
    });
  }

  // ============================================================
  // Tasks Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getTasks(String scheduleId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('schedule_id', scheduleId)
        .order('deadline', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addTask({
    required String scheduleId,
    required String title,
    String? description,
    required DateTime deadline,
    String? fileUrl,
  }) async {
    await _client.from('tasks').insert({
      'schedule_id': scheduleId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'file_url': fileUrl,
    });
  }

  static Future<List<Map<String, dynamic>>> getTaskSubmissions(String taskId) async {
    final response = await _client
        .from('task_submissions')
        .select('''
          *,
          students (
            nis,
            profiles ( full_name )
          )
        ''')
        .eq('task_id', taskId)
        .order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getMyTaskSubmission(String taskId) async {
    final student = await getStudentProfile();
    if (student == null) return null;

    try {
      final response = await _client
          .from('task_submissions')
          .select()
          .eq('task_id', taskId)
          .eq('student_id', student['id'])
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<void> submitTask({
    required String taskId,
    required String fileUrl,
  }) async {
    final student = await getStudentProfile();
    if (student == null) throw Exception('Not logged in as student');

    await _client.from('task_submissions').upsert({
      'task_id': taskId,
      'student_id': student['id'],
      'file_url': fileUrl,
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> gradeTaskSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  }) async {
    await _client.from('task_submissions').update({
      'score': score,
      'feedback': feedback,
    }).eq('id', submissionId);
  }

  // ============================================================
  // Quizzes Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getQuizzes(String scheduleId) async {
    final response = await _client
        .from('quizzes')
        .select()
        .eq('schedule_id', scheduleId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createQuiz({
    required String scheduleId,
    required String title,
    String? description,
    required int durationMinutes,
    required String dueDate,
    required List<Map<String, dynamic>> questions,
  }) async {
    final quizRes = await _client.from('quizzes').insert({
      'schedule_id': scheduleId,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'due_date': dueDate,
    }).select().single();

    final quizId = quizRes['id'];

    final questionsToInsert = questions.map((q) => {
      'quiz_id': quizId,
      'question_text': q['question_text'],
      'question_type': q['question_type'],
      'options': q['options'],
      'correct_answer': q['correct_answer'],
      'points': q['points'] ?? 10,
    }).toList();

    await _client.from('quiz_questions').insert(questionsToInsert);
  }

  static Future<List<Map<String, dynamic>>> getQuizQuestions(String quizId) async {
    final response = await _client
        .from('quiz_questions')
        .select()
        .eq('quiz_id', quizId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getQuizSubmissions(String quizId) async {
    final response = await _client.from('quiz_submissions').select('''
      *,
      students:student_id (
        profiles:profile_id ( full_name )
      ),
      quiz_answers (*)
    ''').eq('quiz_id', quizId).order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> submitQuizAnswers({
    required String quizId,
    required String studentId,
    required List<Map<String, dynamic>> answers,
  }) async {
    // 1. Create submission
    final submissionRes = await _client.from('quiz_submissions').insert({
      'quiz_id': quizId,
      'student_id': studentId,
    }).select().single();

    final submissionId = submissionRes['id'];

    // 2. Insert answers
    final answersToInsert = answers.map((a) => {
      'submission_id': submissionId,
      'question_id': a['question_id'],
      'answer_text': a['answer_text'],
    }).toList();

    await _client.from('quiz_answers').insert(answersToInsert);
  }

  static Future<void> gradeQuizSubmission({
    required String submissionId,
    required int score,
  }) async {
    await _client.from('quiz_submissions').update({
      'score': score,
    }).eq('id', submissionId);
  }

  // ============================================================
  // Storage Methods
  // ============================================================

  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
      path,
      fileBytes as dynamic,
      fileOptions: FileOptions(contentType: contentType),
    );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<String> getPublicUrl(String bucket, String path) async {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // ============================================================
  // Admin Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final response = await _client.from('profiles').select().order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await _client.from('students').select('''
      *,
      profiles:profile_id ( full_name, email, role ),
      classes:class_id ( name )
    ''').order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final response = await _client.from('teachers').select('''
      *,
      profiles:profile_id ( full_name, email, role ),
      classes:wali_class_id ( name )
    ''').order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // Wali Kelas Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getClassStudents(String classId) async {
    final response = await _client.from('students').select('''
      *,
      profiles:profile_id ( full_name, email )
    ''').eq('class_id', classId).order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getClassAttendanceRecap(String classId) async {
    final response = await _client.from('attendances').select('''
      *,
      profiles:user_id ( full_name ),
      schedules:schedule_id ( mapel_name, class_id )
    ''').order('date', ascending: false);

    // Filter by class_id on client side (schedule has class_id)
    return List<Map<String, dynamic>>.from(response)
        .where((a) => a['schedules']?['class_id'] == classId)
        .toList();
  }

  // ============================================================
  // App Settings (Admin GPS)
  // ============================================================

  static Future<Map<String, dynamic>> getAppSettings(String key) async {
    try {
      final response = await _client.from('app_settings').select('value').eq('key', key).maybeSingle();
      if (response != null && response['value'] != null) {
        return response['value'] as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignored
    }
    // Default fallback
    if (key == 'gps_settings') {
      return {'latitude': -6.200000, 'longitude': 106.816666, 'radius_meters': 50};
    }
    return {};
  }

  static Future<void> updateAppSettings(String key, Map<String, dynamic> value) async {
    final existing = await _client.from('app_settings').select('id').eq('key', key).maybeSingle();
    if (existing != null) {
      await _client.from('app_settings').update({'value': value, 'updated_at': DateTime.now().toIso8601String()}).eq('key', key);
    } else {
      await _client.from('app_settings').insert({'key': key, 'value': value});
    }
  }

  // ============================================================
  // Admin Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getProfilesByRole(String role) async {
    final response = await _client.from('profiles').select().eq('role', role).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // Admin Class Management
  // ============================================================

  static Future<void> createClass({
    required String name,
    required String level,
    required String academicYear,
  }) async {
    await _client.from('classes').insert({
      'name': name,
      'level': level,
      'academic_year': academicYear,
    });
  }

  static Future<List<Map<String, dynamic>>> getUnassignedStudents() async {
    final response = await _client.from('students').select('''
      *,
      profiles:profile_id ( full_name, email )
    ''').filter('class_id', 'is', null).order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> assignStudentToClass(String studentId, String classId) async {
    await _client.from('students').update({'class_id': classId}).eq('id', studentId);
  }

  static Future<void> removeStudentFromClass(String studentId) async {
    await _client.from('students').update({'class_id': null}).eq('id', studentId);
  }

  // ============================================================
  // Teacher / Schedule Methods
  // ============================================================

  static Future<List<Map<String, dynamic>>> getMySchedules() async {
    final user = currentUser;
    if (user == null) return [];
    
    final response = await _client.from('schedules').select('''
      *,
      classes:class_id ( name ),
      profiles:teacher_id ( full_name )
    ''').eq('teacher_id', user.id).order('day').order('start_time');
    
    return List<Map<String, dynamic>>.from(response);
  }


  // ============================================================
  // Admin Schedule Management
  // ============================================================

  static Future<List<Map<String, dynamic>>> getSchedulesAdmin() async {
    final response = await _client.from('schedules').select('''
      *,
      classes:class_id ( name ),
      profiles:teacher_id ( full_name )
    ''').order('day').order('start_time');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createSchedule({
    required String classId,
    required String teacherProfileId,
    required String mapelName,
    required String day,
    required String startTime,
    required String endTime,
    required String room,
  }) async {
    // Validation: Enforce "One Subject, One Teacher per Class" rule
    final existingConflicts = await _client.from('schedules')
        .select('teacher_id')
        .eq('class_id', classId)
        .eq('mapel_name', mapelName)
        .neq('teacher_id', teacherProfileId);

    if (existingConflicts.isNotEmpty) {
      throw Exception('Mata pelajaran ini di kelas tersebut sudah diajar oleh guru lain. Satu pelajaran di satu kelas hanya boleh diajar oleh satu guru.');
    }

    await _client.from('schedules').insert({
      'class_id': classId,
      'teacher_id': teacherProfileId,
      'mapel_name': mapelName,
      'class_name': '', // Will be deprecated, but satisfying DB non-null if needed
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    });
  }

  static Future<void> deleteSchedule(String scheduleId) async {
    await _client.from('schedules').delete().eq('id', scheduleId);
  }
}
