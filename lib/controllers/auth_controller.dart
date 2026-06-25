import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String? routeToNavigate;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    successMessage = message;
    errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    routeToNavigate = null;
  }

  Future<void> login(String email, String password) async {
    clearMessages();
    _setLoading(true);

    try {
      await SupabaseService.signIn(email, password);

      final profile = await SupabaseService.getCurrentUserProfile();
      if (profile == null) {
        _setError('Profil tidak ditemukan');
        _setLoading(false);
        return;
      }
      
      if (profile['is_active'] == false) {
        await Supabase.instance.client.auth.signOut();
        _setError('Akun Anda telah dinonaktifkan oleh Admin.');
        _setLoading(false);
        return;
      }

      final role = profile['role'] as String?;
      
      if (role != 'admin') {
        final hasFace = await SupabaseService.hasFaceEnrolled();
        if (!hasFace) {
          routeToNavigate = '/face-enrollment';
          _setLoading(false);
          notifyListeners();
          return;
        }
      }

      if (role == 'admin') {
        routeToNavigate = '/admin-dashboard';
      } else if (role == 'teacher') {
        routeToNavigate = '/teacher-dashboard';
      } else {
        routeToNavigate = '/student-dashboard';
      }
      notifyListeners();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String identityNumber,
    required String password,
    required String role,
    String? classId,
  }) async {
    clearMessages();
    _setLoading(true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await Supabase.instance.client.from('profiles').update({
          'full_name': fullName,
          'role': role,
          'identity_number': identityNumber,
        }).eq('id', res.user!.id);

        if (role == 'student' && classId != null) {
          await Supabase.instance.client.from('students').insert({
            'profile_id': res.user!.id,
            'class_id': classId,
            'nis': identityNumber,
          });
        } else if (role == 'teacher') {
          await Supabase.instance.client.from('teachers').insert({
            'profile_id': res.user!.id,
            'nip': identityNumber,
          });
        }
        
        _setSuccess('Registrasi berhasil! Silakan login.');
      }
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    clearMessages();
    _setLoading(true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _setSuccess('Kata sandi berhasil diperbarui');
    } catch (e) {
      _setError('Gagal memperbarui kata sandi: $e');
    } finally {
      _setLoading(false);
    }
  }
}
