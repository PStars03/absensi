-- Seeder untuk EduPresence
-- Script ini dirancang untuk dijalankan dengan Supabase CLI atau SQL Editor.

DO $$
DECLARE
  -- UUIDs for Users
  s1_id UUID := '00000000-0000-0000-0000-000000000101';
  s2_id UUID := '00000000-0000-0000-0000-000000000102';
  s3_id UUID := '00000000-0000-0000-0000-000000000103';
  s4_id UUID := '00000000-0000-0000-0000-000000000104';
  s5_id UUID := '00000000-0000-0000-0000-000000000105';
  
  t1_id UUID := '00000000-0000-0000-0000-000000000201';
  t2_id UUID := '00000000-0000-0000-0000-000000000202';
  t3_id UUID := '00000000-0000-0000-0000-000000000203';
  
  a1_id UUID := '00000000-0000-0000-0000-000000000301';

  -- UUIDs for Subjects
  sub1_id UUID := '44444444-4444-4444-4444-444444444441';
  sub2_id UUID := '44444444-4444-4444-4444-444444444442';
  sub3_id UUID := '44444444-4444-4444-4444-444444444443';

  -- UUIDs for Classes
  cls1_id UUID := '55555555-5555-5555-5555-555555555551';
  cls2_id UUID := '55555555-5555-5555-5555-555555555552';
  cls3_id UUID := '55555555-5555-5555-5555-555555555553';

  -- UUIDs for Schedules
  sch1_id UUID := '11111111-1111-1111-1111-111111111111';
  sch2_id UUID := '22222222-2222-2222-2222-222222222222';
  sch3_id UUID := '33333333-3333-3333-3333-333333333333';
BEGIN

  -- 1. Hapus data lama jika ada (berdasarkan email)
  DELETE FROM auth.users WHERE email IN (
    'andi@email.com', 'budi@email.com', 'citra@email.com', 'dian@email.com', 'eka@email.com',
    'ahmad@sekolah.com', 'siti@sekolah.com', 'ridwan@sekolah.com',
    'admin@sekolah.com'
  );
  DELETE FROM public.schedules WHERE id IN (sch1_id, sch2_id, sch3_id);
  DELETE FROM public.classes WHERE id IN (cls1_id, cls2_id, cls3_id);
  DELETE FROM public.subjects WHERE id IN (sub1_id, sub2_id, sub3_id);

  -- 2. Insert Students
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
  VALUES 
    (s1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'andi@email.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Andi Pratama", "role": "student", "identity_number": "0051234567", "class_name": "12 IPA 1"}', now(), now(), '', '', '', ''),
    (s2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'budi@email.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Budi Santoso", "role": "student", "identity_number": "0051234568", "class_name": "12 IPA 1"}', now(), now(), '', '', '', ''),
    (s3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'citra@email.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Citra Dewi", "role": "student", "identity_number": "0051234569", "class_name": "12 IPA 2"}', now(), now(), '', '', '', ''),
    (s4_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'dian@email.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Dian Sari", "role": "student", "identity_number": "0051234570", "class_name": "12 IPS 1"}', now(), now(), '', '', '', ''),
    (s5_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'eka@email.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Eka Putri", "role": "student", "identity_number": "0051234571", "class_name": "12 IPS 1"}', now(), now(), '', '', '', '');

  -- 3. Insert Teachers
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
  VALUES 
    (t1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ahmad@sekolah.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Pak Ahmad Fauzi", "role": "teacher", "identity_number": "198501012010011001"}', now(), now(), '', '', '', ''),
    (t2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'siti@sekolah.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Bu Siti Nurhaliza", "role": "teacher", "identity_number": "198602022011012002"}', now(), now(), '', '', '', ''),
    (t3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ridwan@sekolah.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Pak Ridwan Kamil", "role": "teacher", "identity_number": "198703032012013003"}', now(), now(), '', '', '', '');

  -- 4. Insert Admin
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
  VALUES 
    (a1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@sekolah.com', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}', '{"full_name": "Super Admin", "role": "admin"}', now(), now(), '', '', '', '');

  -- 5. Insert Subjects & Classes
  INSERT INTO public.subjects (id, name, type) VALUES 
    (sub1_id, 'Matematika Wajib', 'wajib'),
    (sub2_id, 'Bahasa Indonesia', 'wajib'),
    (sub3_id, 'Fisika Dasar', 'peminatan');

  INSERT INTO public.classes (id, name, grade) VALUES 
    (cls1_id, '12 IPA 1', '12'),
    (cls2_id, '12 IPA 2', '12'),
    (cls3_id, '12 IPS 1', '12');

  -- 6. Insert Jadwal (Schedules)
  -- Catatan: Pastikan table schedules sudah dibuat melalui migration
  INSERT INTO public.schedules (id, mapel_name, subject_id, teacher_id, class_name, class_id, day, start_time, end_time, room, kode_mtk, sks, kel_praktek, kode_gabung)
  VALUES 
    (sch1_id, 'Matematika Wajib', sub1_id, t1_id, '12 IPA 1', cls1_id, 'Senin', '07:15:00', '09:30:00', 'Ruang 12A', 'MTK302', 3, '-', '-'),
    (sch2_id, 'Bahasa Indonesia', sub2_id, t2_id, '12 IPA 1', cls1_id, 'Selasa', '09:45:00', '11:15:00', 'Ruang 12A', 'BIN401', 2, '-', '-'),
    (sch3_id, 'Fisika Dasar', sub3_id, t3_id, '12 IPA 1', cls1_id, 'Rabu', '07:15:00', '09:30:00', 'Lab Fisika', 'FIS401', 3, 'Praktek', '-');

  -- 6. Insert Attendances Dummy
  INSERT INTO public.attendances (schedule_id, user_id, date, check_in, check_out, status)
  VALUES
    (sch1_id, s1_id, current_date, '07:15:00', '14:00:00', 'hadir'),
    (sch1_id, s2_id, current_date, '07:45:00', '14:00:00', 'terlambat'),
    (sch1_id, s3_id, current_date, '00:00:00', NULL, 'alpa'),
    (sch2_id, s4_id, current_date, '07:10:00', '14:00:00', 'hadir'),
    (sch2_id, s5_id, current_date, '00:00:00', NULL, 'izin');

END $$;
