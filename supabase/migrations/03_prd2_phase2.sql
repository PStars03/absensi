-- Phase 2 Migration: Materi & Tugas
-- Modifies: materials
-- Adds: task_submissions

-- ============================================================
-- 1. Materials Enhancements
-- ============================================================
-- Add file_type to materials to differentiate pdf, ppt, video, etc.
ALTER TABLE public.materials ADD COLUMN IF NOT EXISTS file_type TEXT DEFAULT 'doc';
ALTER TABLE public.materials ADD COLUMN IF NOT EXISTS teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL;

-- ============================================================
-- 2. Task Submissions
-- ============================================================
CREATE TABLE public.task_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
  file_url TEXT NOT NULL,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  score INTEGER,
  feedback TEXT,
  UNIQUE(task_id, student_id) -- One submission per task per student
);

ALTER TABLE public.task_submissions ENABLE ROW LEVEL SECURITY;

-- Students can view their own submissions
CREATE POLICY "Students can view own submissions" ON public.task_submissions FOR SELECT USING (
  student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
);

-- Teachers can view all submissions for tasks in schedules they teach
CREATE POLICY "Teachers can view submissions for their tasks" ON public.task_submissions FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.tasks t
    JOIN public.schedules s ON t.schedule_id = s.id
    JOIN public.teachers tch ON s.teacher_id = tch.profile_id
    WHERE t.id = task_submissions.task_id AND tch.profile_id = auth.uid()
  )
);

-- Students can insert their own submissions
CREATE POLICY "Students can insert own submissions" ON public.task_submissions FOR INSERT WITH CHECK (
  student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
);

-- Students can update their own submissions (e.g., re-upload before deadline)
CREATE POLICY "Students can update own submissions" ON public.task_submissions FOR UPDATE USING (
  student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
);

-- Teachers can update submissions (to add score and feedback)
CREATE POLICY "Teachers can update submissions for grading" ON public.task_submissions FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.tasks t
    JOIN public.schedules s ON t.schedule_id = s.id
    JOIN public.teachers tch ON s.teacher_id = tch.profile_id
    WHERE t.id = task_submissions.task_id AND tch.profile_id = auth.uid()
  )
);
