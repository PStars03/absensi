import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/face_scan_screen.dart';
// Student
import 'screens/student/student_dashboard.dart';
import 'screens/student/student_attendance.dart';
import 'screens/student/student_materials.dart';
import 'screens/student/student_tasks.dart';
import 'screens/student/student_quiz.dart';
import 'screens/student/student_schedule.dart';
// Teacher
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/teacher/teacher_attendance.dart';
import 'screens/teacher/teacher_materials.dart';
import 'screens/teacher/teacher_tasks.dart';
import 'screens/teacher/teacher_quiz.dart';
import 'screens/teacher/teacher_schedule.dart';
// Admin
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_users.dart';
import 'screens/admin/admin_schedule.dart';

// Shared
import 'screens/shared/mapel_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ydoryrdmwoibxnwqzdcj.supabase.co',
    publishableKey: 'sb_publishable_6ulK5n2egCVu7pdAYftqzw_Ehsyf0Xo',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPresence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          // Auth
          case '/login':
            return _buildRoute(const LoginScreen(), settings);
          case '/register':
            return _buildRoute(const RegisterScreen(), settings);

          // Face Scan
          case '/face-scan':
            final args = settings.arguments as Map<String, dynamic>? ?? {'type': 'masuk', 'scheduleId': ''};
            return _buildRoute(FaceScanScreen(
              type: args['type'] as String,
              scheduleId: args['scheduleId'] as String,
            ), settings);

          // Student
          case '/student-dashboard':
            return _buildRoute(const StudentDashboard(), settings);
          case '/student-schedule':
            return _buildRoute(const StudentScheduleScreen(), settings);
          case '/student-attendance':
            return _buildRoute(const StudentAttendance(), settings);
          case '/student-materials':
            return _buildRoute(const StudentMaterials(), settings);
          case '/student-tasks':
            return _buildRoute(const StudentTasks(), settings);
          case '/student-quiz':
            return _buildRoute(const StudentQuiz(), settings);

          // Teacher
          case '/teacher-dashboard':
            return _buildRoute(const TeacherDashboard(), settings);
          case '/teacher-schedule':
            return _buildRoute(const TeacherScheduleScreen(), settings);
          case '/teacher-attendance':
            return _buildRoute(const TeacherAttendance(), settings);
          case '/teacher-materials':
            return _buildRoute(const TeacherMaterials(), settings);
          case '/teacher-tasks':
            return _buildRoute(const TeacherTasks(), settings);
          case '/teacher-quiz':
            return _buildRoute(const TeacherQuiz(), settings);

          // Admin
          case '/admin-dashboard':
            return _buildRoute(const AdminDashboard(), settings);
          case '/admin-schedule':
            return _buildRoute(const AdminScheduleScreen(), settings);
          case '/admin-users':
            return _buildRoute(const AdminUsers(), settings);
            
          // Shared
          case '/mapel-dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {'scheduleId': '1', 'role': 'student'};
            return _buildRoute(MapelDashboardScreen(scheduleId: args['scheduleId'], role: args['role']), settings);

          default:
            return _buildRoute(const LoginScreen(), settings);
        }
      },
    );
  }

  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
