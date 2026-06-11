-- Seeder untuk EduPresence
-- Script ini dirancang untuk dijalankan di panel SQL Editor Supabase untuk keperluan pengujian.

-- 1. Buat User Dummy di auth.users
-- Password untuk semua user ini adalah: password123
-- Peringatan: Jalankan ini HANYA untuk database development/testing!

DO $$
DECLARE
  student_id UUID := '00000000-0000-0000-0000-000000000001';
  teacher_id UUID := '00000000-0000-0000-0000-000000000002';
  admin_id UUID := '00000000-0000-0000-0000-000000000003';
  schedule1_id UUID := '11111111-1111-1111-1111-111111111111';
  schedule2_id UUID := '22222222-2222-2222-2222-222222222222';
BEGIN

  -- Hapus data lama jika ada (menghindari duplikasi saat testing ulang)
  DELETE FROM auth.users WHERE email IN ('student@test.com', 'teacher@test.com', 'admin@test.com');
  DELETE FROM public.schedules WHERE id IN (schedule1_id, schedule2_id);

  -- Insert Student
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES (
    student_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'student@test.com',
    crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}',
    '{"full_name": "Andi Pratama", "role": "student", "identity_number": "0051234567", "class_name": "12 IPA 1"}',
    now(), now()
  );

  -- Insert Teacher
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES (
    teacher_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'teacher@test.com',
    crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}',
    '{"full_name": "Budi Santoso", "role": "teacher", "identity_number": "198001012005011003"}',
    now(), now()
  );

  -- Insert Admin
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES (
    admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@test.com',
    crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"]}',
    '{"full_name": "Super Admin", "role": "admin"}',
    now(), now()
  );

  -- Tunggu sejenak memastikan Trigger `handle_new_user` berhasil membuat profile di `public.profiles`

  -- 2. Insert Jadwal (Schedules)
  INSERT INTO public.schedules (id, mapel_name, teacher_id, class_name, day, start_time, end_time, room, kode_mtk, sks, kel_praktek, kode_gabung)
  VALUES 
    (schedule1_id, 'Matematika Lanjut', teacher_id, '12 IPA 1', 'Senin', '07:30:00', '09:00:00', 'Ruang 101', 'MTK302', 3, '-', '-'),
    (schedule2_id, 'Fisika Terapan', teacher_id, '12 IPA 1', 'Senin', '09:15:00', '11:30:00', 'Lab Fisika', 'FIS401', 2, 'Praktek', 'GAB1');

  -- 3. Insert Attendances Dummy
  INSERT INTO public.attendances (schedule_id, user_id, date, check_in, check_out, status)
  VALUES
    (schedule1_id, student_id, current_date - interval '1 day', '07:25:00', '09:05:00', 'hadir'),
    (schedule2_id, student_id, current_date - interval '1 day', '09:20:00', '11:35:00', 'terlambat');

  -- 4. Insert Materials Dummy
  INSERT INTO public.materials (schedule_id, title, description, file_url)
  VALUES
    (schedule1_id, 'Materi Bab 1: Integral', 'Pelajari modul integral tentu dan tak tentu sebelum ujian.', 'https://example.com/modul1.pdf'),
    (schedule1_id, 'Latihan Soal Matematika', 'Kumpulan soal latihan untuk dipecahkan bersama di kelas.', NULL);

  -- 5. Insert Tasks Dummy
  INSERT INTO public.tasks (schedule_id, title, description, deadline)
  VALUES
    (schedule1_id, 'Tugas Mandiri 1', 'Kerjakan LKS halaman 24-25 dan kumpulkan format PDF.', now() + interval '3 days');

  -- 6. Insert Quizzes Dummy
  INSERT INTO public.quizzes (schedule_id, title, question_count, duration_minutes)
  VALUES
    (schedule1_id, 'Kuis Harian Integral', 10, 15);

END $$;
