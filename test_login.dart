import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  print('Initializing Supabase Client...');
  final client = SupabaseClient(
    'https://ydoryrdmwoibxnwqzdcj.supabase.co',
    'sb_publishable_6ulK5n2egCVu7pdAYftqzw_Ehsyf0Xo',
  );

  try {
    print('Attempting to sign in...');
    final response = await client.auth.signInWithPassword(
      email: 'student@test.com',
      password: 'password123',
    );
    print('Sign in successful! User ID: ${response.user?.id}');
  } on AuthException catch (e) {
    print('Supabase Auth Error: ${e.message} (Status: ${e.statusCode})');
  } catch (e) {
    print('Unknown Error: $e');
  }
  exit(0);
}
