-- Phase 3 Migration: Kuis & Penilaian

-- ============================================================
-- 1. Quizzes Table
-- ============================================================
CREATE TABLE public.quizzes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_id UUID REFERENCES public.schedules(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER NOT NULL DEFAULT 60,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Quizzes viewable by everyone in schedule" ON public.quizzes FOR SELECT USING (true);
CREATE POLICY "Teachers can manage quizzes" ON public.quizzes FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.schedules s
    JOIN public.teachers tch ON s.teacher_id = tch.profile_id
    WHERE s.id = quizzes.schedule_id AND tch.profile_id = auth.uid()
  )
);

-- ============================================================
-- 2. Quiz Questions Table
-- ============================================================
CREATE TABLE public.quiz_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('multiple_choice', 'short_answer', 'essay')),
  options JSONB, -- For multiple choice: e.g. ["A", "B", "C", "D"]
  correct_answer TEXT,
  points INTEGER DEFAULT 10 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Questions viewable by everyone" ON public.quiz_questions FOR SELECT USING (true);
CREATE POLICY "Teachers can manage questions" ON public.quiz_questions FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.quizzes q
    JOIN public.schedules s ON q.schedule_id = s.id
    JOIN public.teachers tch ON s.teacher_id = tch.profile_id
    WHERE q.id = quiz_questions.quiz_id AND tch.profile_id = auth.uid()
  )
);

-- ============================================================
-- 3. Quiz Submissions Table
-- ============================================================
CREATE TABLE public.quiz_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE NOT NULL,
  student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
  score INTEGER, -- Nullable until graded
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(quiz_id, student_id)
);

ALTER TABLE public.quiz_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students view own submissions" ON public.quiz_submissions FOR SELECT USING (
  student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
);
CREATE POLICY "Teachers view submissions" ON public.quiz_submissions FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.quizzes q
    JOIN public.schedules s ON q.schedule_id = s.id
    JOIN public.teachers tch ON s.teacher_id = tch.profile_id
    WHERE q.id = quiz_submissions.quiz_id AND tch.profile_id = auth.uid()
  )
);
CREATE POLICY "Students can insert submissions" ON public.quiz_submissions FOR INSERT WITH CHECK (
  student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
);
CREATE POLICY "Teachers can grade submissions" ON public.quiz_submissions FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.quizzes q
    JOIN public.schedules s ON q.schedule_id = s.id
    JOIN public.teachers tch ON s.teacher_id = tch.profile_id
    WHERE q.id = quiz_submissions.quiz_id AND tch.profile_id = auth.uid()
  )
);

-- ============================================================
-- 4. Quiz Answers Table
-- ============================================================
CREATE TABLE public.quiz_answers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  submission_id UUID REFERENCES public.quiz_submissions(id) ON DELETE CASCADE NOT NULL,
  question_id UUID REFERENCES public.quiz_questions(id) ON DELETE CASCADE NOT NULL,
  answer_text TEXT NOT NULL,
  is_correct BOOLEAN, -- Nullable until graded (manual or auto)
  points_awarded INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(submission_id, question_id)
);

ALTER TABLE public.quiz_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students view own answers" ON public.quiz_answers FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.quiz_submissions s
    WHERE s.id = quiz_answers.submission_id AND s.student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
  )
);
CREATE POLICY "Teachers view answers" ON public.quiz_answers FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.quiz_submissions s
    JOIN public.quizzes q ON s.quiz_id = q.id
    JOIN public.schedules sch ON q.schedule_id = sch.id
    JOIN public.teachers tch ON sch.teacher_id = tch.profile_id
    WHERE s.id = quiz_answers.submission_id AND tch.profile_id = auth.uid()
  )
);
CREATE POLICY "Students insert answers" ON public.quiz_answers FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.quiz_submissions s
    WHERE s.id = quiz_answers.submission_id AND s.student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
  )
);
CREATE POLICY "Teachers update answers (grading)" ON public.quiz_answers FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.quiz_submissions s
    JOIN public.quizzes q ON s.quiz_id = q.id
    JOIN public.schedules sch ON q.schedule_id = sch.id
    JOIN public.teachers tch ON sch.teacher_id = tch.profile_id
    WHERE s.id = quiz_answers.submission_id AND tch.profile_id = auth.uid()
  )
);
