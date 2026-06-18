// ignore_for_file: avoid_print
import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  print('Initializing Supabase Client...');
  final client = SupabaseClient(
    'https://asflwdvbtufxzojlrdhg.supabase.co',
    'sb_publishable_SZ7Sxxw4v8dHLt-ME3shpg_Qrv9w2bk',
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  try {
    print('Attempting to sign up...');
    final response = await client.auth.signUp(
      email: 'student_${DateTime.now().millisecondsSinceEpoch}@test.com',
      password: 'password123',
    );
    print('Sign up successful! User ID: ${response.user?.id}');
  } on AuthException catch (e) {
    print('Supabase Auth Error: ${e.message} (Status: ${e.statusCode})');
  } catch (e, st) {
    print('Unknown Error: $e');
    print(st);
  }
  exit(0);
}
