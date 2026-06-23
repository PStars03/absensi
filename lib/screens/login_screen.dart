import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Halaman Login EduPresence
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // Real auth logic
      await SupabaseService.signIn(email, password);

      // Get profile to determine role
      final profile = await SupabaseService.getCurrentUserProfile();
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (profile == null) {
        // Fallback or error if profile missing, but allow login
        // Actually, we should route based on role if exists
        _showError('Profil pengguna tidak ditemukan.');
        await SupabaseService.signOut();
        return;
      }

      final role = profile['role'] as String?;
      
      if (role != 'admin') {
        final hasFace = await SupabaseService.hasFaceEnrolled();
        if (!hasFace) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/face-enrollment');
          return;
        }
      }

      String route;
      if (role == 'admin') {
        route = '/admin-dashboard';
      } else if (role == 'teacher') {
        route = '/teacher-dashboard';
      } else {
        route = '/student-dashboard';
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.statusCode == '400' || e.message.toLowerCase().contains('invalid login credentials')) {
        _showError('Email atau kata sandi salah. Silakan coba lagi.');
      } else {
        _showError('Gagal masuk: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Terjadi kesalahan: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image not found
                              return const Icon(Icons.fingerprint_rounded, size: 80, color: AppColors.primaryBlue);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App name
                      const Text(
                        'EduPresence',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Absensi Biometrik & E-Learning',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib diisi';
                          if (v.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showForgotPasswordModal,
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Login button
                      GradientButton(
                        text: 'Masuk',
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 20),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordModal() {
    final emailCtrl = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Reset Password', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Masukkan email Anda untuk menerima tautan reset password.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending ? null : () async {
                        if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) return;
                        setStateModal(() => isSending = true);
                        try {
                          await SupabaseService.resetPassword(emailCtrl.text.trim());
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tautan reset password telah dikirim ke email Anda')));
                        } catch (e) {
                          setStateModal(() => isSending = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim email: $e')));
                        }
                      },
                      child: isSending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kirim Tautan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
