// Data dummy untuk UI EduPresence
// Digunakan sebelum integrasi Supabase backend

class MockUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'student', 'teacher', 'admin'
  final String? identifierNumber; // NISN untuk siswa, NIP untuk guru
  final String? className;

  const MockUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.identifierNumber,
    this.className,
  });
}

class MockSchedule {
  final String id;
  final String mapelName;
  final String day;
  final String timeRange;
  final String teacherName;
  final String className;
  final String room;

  const MockSchedule({
    required this.id,
    required this.mapelName,
    required this.day,
    required this.timeRange,
    required this.teacherName,
    required this.className,
    required this.room,
  });
}

class MockAttendance {
  final String id;
  final String scheduleId;
  final String userName;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status; // 'hadir', 'terlambat', 'alpa', 'izin'

  const MockAttendance({
    required this.id,
    required this.scheduleId,
    required this.userName,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
  });
}

class MockMaterial {
  final String id;
  final String scheduleId;
  final String title;
  final String description;
  final String teacherName;
  final String date;
  final String fileType; // 'pdf', 'doc', 'ppt', 'video'
  final String? fileUrl;

  const MockMaterial({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.description,
    required this.teacherName,
    required this.date,
    required this.fileType,
    this.fileUrl,
  });
}

class MockTask {
  final String id;
  final String scheduleId;
  final String title;
  final String description;
  final String teacherName;
  final String deadline;
  final String status; // 'belum', 'dikumpulkan', 'dinilai'
  final int? score;
  final String? feedback;

  const MockTask({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.description,
    required this.teacherName,
    required this.deadline,
    required this.status,
    this.score,
    this.feedback,
  });
}

class MockQuiz {
  final String id;
  final String scheduleId;
  final String title;
  final String teacherName;
  final String type; // 'pg' (pilihan ganda), 'isian'
  final int questionCount;
  final int durationMinutes;
  final String status; // 'belum', 'dikerjakan', 'dinilai'
  final int? score;

  const MockQuiz({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.teacherName,
    required this.type,
    required this.questionCount,
    required this.durationMinutes,
    required this.status,
    this.score,
  });
}

class MockQuizQuestion {
  final String id;
  final String question;
  final String type; // 'pg', 'isian'
  final List<String>? options; // untuk PG
  final String? correctAnswer;

  const MockQuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.correctAnswer,
  });
}

/// ============================================================
/// Data Dummy Instances
/// ============================================================

class MockData {
  MockData._();

  // Users
  static const List<MockUser> students = [
    MockUser(id: '1', name: 'Andi Pratama', email: 'andi@email.com', role: 'student', identifierNumber: '0051234567', className: '12 IPA 1'),
    MockUser(id: '2', name: 'Budi Santoso', email: 'budi@email.com', role: 'student', identifierNumber: '0051234568', className: '12 IPA 1'),
    MockUser(id: '3', name: 'Citra Dewi', email: 'citra@email.com', role: 'student', identifierNumber: '0051234569', className: '12 IPA 2'),
    MockUser(id: '4', name: 'Dian Sari', email: 'dian@email.com', role: 'student', identifierNumber: '0051234570', className: '12 IPS 1'),
    MockUser(id: '5', name: 'Eka Putri', email: 'eka@email.com', role: 'student', identifierNumber: '0051234571', className: '12 IPS 1'),
  ];

  static const List<MockUser> teachers = [
    MockUser(id: '10', name: 'Pak Ahmad Fauzi', email: 'ahmad@sekolah.com', role: 'teacher', identifierNumber: '198501012010011001'),
    MockUser(id: '11', name: 'Bu Siti Nurhaliza', email: 'siti@sekolah.com', role: 'teacher', identifierNumber: '198602022011012002'),
    MockUser(id: '12', name: 'Pak Ridwan Kamil', email: 'ridwan@sekolah.com', role: 'teacher', identifierNumber: '198703032012013003'),
  ];

  static const MockUser admin = MockUser(
    id: '99',
    name: 'Super Admin',
    email: 'admin@sekolah.com',
    role: 'admin',
  );

  // Kelas dropdown options
  static const List<String> classOptions = [
    '10 IPA 1', '10 IPA 2', '10 IPS 1', '10 IPS 2',
    '11 IPA 1', '11 IPA 2', '11 IPS 1', '11 IPS 2',
    '12 IPA 1', '12 IPA 2', '12 IPS 1', '12 IPS 2',
  ];

  // Jadwal Mapel
  static const List<MockSchedule> schedules = [
    MockSchedule(id: '1', mapelName: 'Matematika Wajib', day: 'Senin', timeRange: '07:15 - 09:30', teacherName: 'Pak Ahmad Fauzi', className: '12 IPA 1', room: 'Ruang 12A'),
    MockSchedule(id: '2', mapelName: 'Bahasa Indonesia', day: 'Selasa', timeRange: '09:45 - 11:15', teacherName: 'Bu Siti Nurhaliza', className: '12 IPA 1', room: 'Ruang 12A'),
    MockSchedule(id: '3', mapelName: 'Fisika Dasar', day: 'Rabu', timeRange: '07:15 - 09:30', teacherName: 'Pak Ridwan Kamil', className: '12 IPA 1', room: 'Lab Fisika'),
  ];

  // Attendance data
  static const List<MockAttendance> attendances = [
    MockAttendance(id: '1', scheduleId: '1', userName: 'Andi Pratama', date: '11 Jun 2026', checkIn: '07:15', checkOut: '14:00', status: 'hadir'),
    MockAttendance(id: '2', scheduleId: '1', userName: 'Budi Santoso', date: '11 Jun 2026', checkIn: '07:45', checkOut: '14:00', status: 'terlambat'),
    MockAttendance(id: '3', scheduleId: '1', userName: 'Citra Dewi', date: '11 Jun 2026', checkIn: '-', checkOut: '-', status: 'alpa'),
    MockAttendance(id: '4', scheduleId: '2', userName: 'Dian Sari', date: '11 Jun 2026', checkIn: '07:10', checkOut: '14:00', status: 'hadir'),
    MockAttendance(id: '5', scheduleId: '2', userName: 'Eka Putri', date: '11 Jun 2026', checkIn: '-', checkOut: '-', status: 'izin'),
    MockAttendance(id: '6', scheduleId: '3', userName: 'Andi Pratama', date: '10 Jun 2026', checkIn: '07:05', checkOut: '14:00', status: 'hadir'),
    MockAttendance(id: '7', scheduleId: '3', userName: 'Budi Santoso', date: '10 Jun 2026', checkIn: '07:20', checkOut: '14:00', status: 'hadir'),
    MockAttendance(id: '8', scheduleId: '3', userName: 'Citra Dewi', date: '10 Jun 2026', checkIn: '07:30', checkOut: '14:00', status: 'hadir'),
  ];

  // Materials
  static const List<MockMaterial> materials = [
    MockMaterial(id: '1', scheduleId: '1', title: 'Pengenalan Algoritma', description: 'Materi dasar tentang konsep algoritma dan flowchart dalam pemrograman.', teacherName: 'Pak Ahmad Fauzi', date: '10 Jun 2026', fileType: 'pdf'),
    MockMaterial(id: '2', scheduleId: '1', title: 'Struktur Data Array', description: 'Pembahasan tentang array, operasi CRUD, dan implementasinya.', teacherName: 'Pak Ahmad Fauzi', date: '8 Jun 2026', fileType: 'ppt'),
    MockMaterial(id: '3', scheduleId: '2', title: 'Bahasa Indonesia: Teks Prosedur', description: 'Materi tentang ciri-ciri, struktur, dan contoh teks prosedur.', teacherName: 'Bu Siti Nurhaliza', date: '7 Jun 2026', fileType: 'doc'),
    MockMaterial(id: '4', scheduleId: '3', title: 'Fisika: Hukum Newton', description: 'Video pembelajaran tentang 3 Hukum Newton dan contoh penerapannya.', teacherName: 'Pak Ridwan Kamil', date: '5 Jun 2026', fileType: 'video'),
  ];

  // Tasks
  static const List<MockTask> tasks = [
    MockTask(id: '1', scheduleId: '1', title: 'Latihan Algoritma Sorting', description: 'Buatlah program sorting menggunakan Bubble Sort dan Selection Sort.', teacherName: 'Pak Ahmad Fauzi', deadline: '15 Jun 2026', status: 'belum'),
    MockTask(id: '2', scheduleId: '2', title: 'Esai Teks Prosedur', description: 'Tulislah sebuah teks prosedur tentang cara membuat aplikasi mobile.', teacherName: 'Bu Siti Nurhaliza', deadline: '13 Jun 2026', status: 'dikumpulkan'),
    MockTask(id: '3', scheduleId: '3', title: 'Laporan Praktikum Fisika', description: 'Buat laporan hasil percobaan Hukum Newton III.', teacherName: 'Pak Ridwan Kamil', deadline: '10 Jun 2026', status: 'dinilai', score: 85, feedback: 'Bagus! Analisis data sudah tepat.'),
  ];

  // Quiz
  static const List<MockQuiz> quizzes = [
    MockQuiz(id: '1', scheduleId: '1', title: 'Quiz Algoritma Dasar', teacherName: 'Pak Ahmad Fauzi', type: 'pg', questionCount: 10, durationMinutes: 30, status: 'belum'),
    MockQuiz(id: '2', scheduleId: '2', title: 'Quiz Teks Prosedur', teacherName: 'Bu Siti Nurhaliza', type: 'isian', questionCount: 5, durationMinutes: 20, status: 'dikerjakan'),
    MockQuiz(id: '3', scheduleId: '3', title: 'Quiz Hukum Newton', teacherName: 'Pak Ridwan Kamil', type: 'pg', questionCount: 15, durationMinutes: 45, status: 'dinilai', score: 90),
  ];

  // Quiz Questions (sample)
  static const List<MockQuizQuestion> sampleQuizQuestions = [
    MockQuizQuestion(id: '1', question: 'Apa yang dimaksud dengan algoritma?', type: 'pg', options: ['Bahasa pemrograman', 'Langkah-langkah sistematis untuk menyelesaikan masalah', 'Perangkat lunak komputer', 'Sistem operasi'], correctAnswer: 'Langkah-langkah sistematis untuk menyelesaikan masalah'),
    MockQuizQuestion(id: '2', question: 'Sebutkan 3 struktur dasar algoritma!', type: 'isian', correctAnswer: 'Sekuensial, Percabangan, Perulangan'),
    MockQuizQuestion(id: '3', question: 'Manakah yang termasuk algoritma sorting?', type: 'pg', options: ['Binary Search', 'Bubble Sort', 'Linked List', 'Queue'], correctAnswer: 'Bubble Sort'),
    MockQuizQuestion(id: '4', question: 'Kompleksitas waktu Bubble Sort adalah...', type: 'pg', options: ['O(n)', 'O(n log n)', 'O(n²)', 'O(1)'], correctAnswer: 'O(n²)'),
    MockQuizQuestion(id: '5', question: 'Jelaskan perbedaan antara array dan linked list!', type: 'isian'),
  ];
}
