-- Phase 1 Migration: PRD2 Alignment
-- Adds: subjects, classes, students, teachers, attendance_locations
-- Modifies: profiles (role CHECK), schedules (subject_id, class_id)

-- ============================================================
-- 1. Subjects (Mata Pelajaran)
-- ============================================================
CREATE TABLE public.subjects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Subjects viewable by everyone" ON public.subjects FOR SELECT USING (true);
CREATE POLICY "Admin can manage subjects" ON public.subjects FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================================
-- 2. Classes (Kelas)
-- ============================================================
CREATE TABLE public.classes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,       -- e.g. '12 IPA 1'
  level TEXT NOT NULL,             -- e.g. '10', '11', '12'
  academic_year TEXT NOT NULL,     -- e.g. '2025/2026'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Classes viewable by everyone" ON public.classes FOR SELECT USING (true);
CREATE POLICY "Admin can manage classes" ON public.classes FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================================
-- 3. Students (extends profiles for student-specific data)
-- ============================================================
CREATE TABLE public.students (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  class_id UUID REFERENCES public.classes(id) ON DELETE SET NULL,
  nis TEXT,                         -- Nomor Induk Siswa
  face_embedding BYTEA,            -- Face embedding placeholder
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students viewable by authenticated" ON public.students FOR SELECT USING (true);
CREATE POLICY "Own student record insert" ON public.students FOR INSERT WITH CHECK (
  profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Own student record update" ON public.students FOR UPDATE USING (
  profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================================
-- 4. Teachers (extends profiles for teacher-specific data)
-- ============================================================
CREATE TABLE public.teachers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  nip TEXT,                         -- Nomor Induk Pegawai
  is_wali_kelas BOOLEAN DEFAULT false,
  wali_class_id UUID REFERENCES public.classes(id) ON DELETE SET NULL,
  face_embedding BYTEA,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Teachers viewable by authenticated" ON public.teachers FOR SELECT USING (true);
CREATE POLICY "Own teacher record update" ON public.teachers FOR UPDATE USING (
  profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Admin can manage teachers" ON public.teachers FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================================
-- 5. Attendance Locations (GPS settings for Admin)
-- ============================================================
CREATE TABLE public.attendance_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,               -- e.g. 'Gerbang Utama Sekolah'
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER NOT NULL DEFAULT 50,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.attendance_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Locations viewable by everyone" ON public.attendance_locations FOR SELECT USING (true);
CREATE POLICY "Admin can manage locations" ON public.attendance_locations FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================================
-- 6. Add subject_id and class_id to schedules
-- ============================================================
ALTER TABLE public.schedules ADD COLUMN IF NOT EXISTS subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL;
ALTER TABLE public.schedules ADD COLUMN IF NOT EXISTS class_id UUID REFERENCES public.classes(id) ON DELETE SET NULL;

-- ============================================================
-- 7. Add GPS columns to attendances
-- ============================================================
ALTER TABLE public.attendances ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.attendances ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.attendances ADD COLUMN IF NOT EXISTS face_verified BOOLEAN DEFAULT false;

-- ============================================================
-- 8. Update handle_new_user trigger to also create student/teacher record
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  user_role TEXT;
BEGIN
  user_role := COALESCE(new.raw_user_meta_data->>'role', 'student');
  
  -- Insert into profiles
  INSERT INTO public.profiles (id, email, full_name, role, identity_number, class_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    user_role,
    new.raw_user_meta_data->>'identity_number',
    new.raw_user_meta_data->>'class_name'
  );

  -- Create role-specific record
  IF user_role = 'student' THEN
    INSERT INTO public.students (profile_id, nis)
    VALUES (new.id, new.raw_user_meta_data->>'identity_number');
  ELSIF user_role = 'teacher' THEN
    INSERT INTO public.teachers (profile_id, nip)
    VALUES (new.id, new.raw_user_meta_data->>'identity_number');
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 9. Storage Buckets
-- ============================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('materials', 'materials', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('submissions', 'submissions', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('face-data', 'face-data', false) ON CONFLICT DO NOTHING;

-- Storage policies for materials bucket (public read, teacher/admin write)
CREATE POLICY "Materials public read" ON storage.objects FOR SELECT USING (bucket_id = 'materials');
CREATE POLICY "Materials teacher write" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'materials' AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Materials teacher delete" ON storage.objects FOR DELETE USING (
  bucket_id = 'materials' AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

-- Storage policies for submissions bucket (own read, student write)
CREATE POLICY "Submissions own read" ON storage.objects FOR SELECT USING (
  bucket_id = 'submissions' AND (auth.uid()::text = (storage.foldername(name))[1] OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'admin')))
);
CREATE POLICY "Submissions student write" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'submissions' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage policies for face-data bucket (own read/write only)
CREATE POLICY "Face-data own access" ON storage.objects FOR SELECT USING (
  bucket_id = 'face-data' AND auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Face-data own write" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'face-data' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================
-- 5. Admin RPC for User Management
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.create_user_by_admin(new_email text, new_password text, new_full_name text, new_role text, new_identity_number text, new_class_name text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_user_id UUID;
    meta_data JSONB;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
        RAISE EXCEPTION 'Only admins can create users';
    END IF;

    -- Build raw_user_meta_data for the trigger
    meta_data := jsonb_build_object(
        'full_name', new_full_name,
        'role', new_role,
        'identity_number', new_identity_number
    );
    
    IF new_class_name IS NOT NULL THEN
        meta_data := meta_data || jsonb_build_object('class_name', new_class_name);
    END IF;

    -- Insert into auth.users (with bcrypt cost 10)
    -- The handle_new_user trigger will automatically create the profile, teacher, and student records!
    INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change_token_current, email_change, phone_change, phone_change_token, reauthentication_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', new_email, crypt(new_password, gen_salt('bf', 10)), now(), '{"provider":"email","providers":["email"]}', meta_data, now(), now(), '', '', '', '', '', '', '', ''
    ) RETURNING id INTO new_user_id;

    -- Insert into auth.identities
    INSERT INTO auth.identities (
        id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
    ) VALUES (
        gen_random_uuid(), new_user_id, new_user_id::text, jsonb_build_object('sub', new_user_id::text, 'email', new_email), 'email', now(), now(), now()
    );

    RETURN new_user_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_user_by_admin(
    target_user_id UUID
) RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
        RAISE EXCEPTION 'Only admins can delete users';
    END IF;
    DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
