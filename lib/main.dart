import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/face_scan_screen.dart';
import 'screens/face_enrollment_screen.dart';
import 'screens/update_password_screen.dart';
// Student
import 'screens/student/student_dashboard.dart';
import 'screens/student/student_quiz_attempt.dart';
import 'screens/student/student_schedule.dart';
import 'screens/student/notifications_screen.dart';
// Teacher
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/teacher/teacher_quiz_detail.dart';
import 'screens/teacher/teacher_schedule.dart';
import 'screens/teacher/teacher_reports.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_users.dart';
import 'screens/admin/admin_gps_settings.dart';
import 'screens/admin/admin_schedule.dart';
import 'screens/admin/admin_reports.dart';
import 'screens/admin/admin_classes.dart';
import 'screens/admin/admin_class_detail.dart';
import 'screens/admin/admin_schedule_form.dart';

// Shared
import 'screens/shared/mapel_dashboard.dart';
import 'screens/teacher/wali_kelas_monitoring.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://asflwdvbtufxzojlrdhg.supabase.co',
    publishableKey: 'sb_publishable_SZ7Sxxw4v8dHLt-ME3shpg_Qrv9w2bk',
  );
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushNamed('/update-password');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPresence',
      navigatorKey: navigatorKey,
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
          case '/update-password':
            return _buildRoute(const UpdatePasswordScreen(), settings);

          // Face
          case '/face-scan':
            final args =
                settings.arguments as Map<String, dynamic>? ??
                {'type': 'masuk', 'scheduleId': ''};
            return _buildRoute(
              FaceScanScreen(
                type: args['type'] as String,
                scheduleId: args['scheduleId'] as String,
              ),
              settings,
            );
          case '/face-enrollment':
            return _buildRoute(const FaceEnrollmentScreen(), settings);

          // Student
          case '/student-dashboard':
            return _buildRoute(const StudentDashboard(), settings);
          case '/student-schedule':
            return _buildRoute(const StudentScheduleScreen(), settings);
          case '/student-quiz-attempt':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return _buildRoute(StudentQuizAttemptScreen(quiz: args), settings);
          case '/notifications':
            return _buildRoute(const NotificationsScreen(), settings);

          // Teacher
          case '/teacher-dashboard':
            return _buildRoute(const TeacherDashboard(), settings);
          case '/teacher-schedule':
            return _buildRoute(const TeacherScheduleScreen(), settings);
          case '/teacher-quiz-detail':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return _buildRoute(TeacherQuizDetailScreen(quiz: args), settings);
          case '/teacher-reports':
            return _buildRoute(const TeacherReportsScreen(), settings);
          case '/wali-kelas':
            return _buildRoute(const WaliKelasMonitoringScreen(), settings);

          // Admin
          case '/admin-dashboard':
            return _buildRoute(const AdminDashboard(), settings);
          case '/admin-users':
            return _buildRoute(const AdminUsers(), settings);
          case '/admin-gps':
            return _buildRoute(const AdminGpsSettingsScreen(), settings);
          case '/admin-schedule':
            return _buildRoute(const AdminScheduleScreen(), settings);
          case '/admin-reports':
            return _buildRoute(const AdminReportsScreen(), settings);
          case '/admin-classes':
            return _buildRoute(const AdminClassesScreen(), settings);
          case '/admin-class-detail':
            final args = settings.arguments as Map<String, dynamic>;
            return _buildRoute(AdminClassDetailScreen(classData: args), settings);
          case '/admin-schedule-form':
            return _buildRoute(const AdminScheduleFormScreen(), settings);

          // Shared
          case '/mapel-dashboard':
            final args =
                settings.arguments as Map<String, dynamic>? ??
                {'scheduleId': '1', 'role': 'student'};
            return _buildRoute(
              MapelDashboardScreen(
                scheduleId: args['scheduleId'],
                role: args['role'],
              ),
              settings,
            );

          default:
            return _buildRoute(const LoginScreen(), settings);
        }
      },
    );
  }

  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
