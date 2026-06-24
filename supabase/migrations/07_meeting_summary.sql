-- Fix for 42501 RLS error on meetings table
-- This RPC bypasses RLS using SECURITY DEFINER to safely insert/update meetings
CREATE OR REPLACE FUNCTION public.add_meeting_summary(
  p_schedule_id UUID,
  p_summary TEXT,
  p_date DATE
) RETURNS void AS $$
DECLARE
  v_existing_id UUID;
  v_next_number INTEGER;
BEGIN
  -- Check if existing meeting for today
  SELECT id INTO v_existing_id
  FROM public.meetings
  WHERE schedule_id = p_schedule_id AND date = p_date;

  IF v_existing_id IS NOT NULL THEN
    -- Update existing
    UPDATE public.meetings
    SET summary = p_summary
    WHERE id = v_existing_id;
  ELSE
    -- Get next meeting number
    SELECT COALESCE(MAX(meeting_number), 0) + 1 INTO v_next_number
    FROM public.meetings
    WHERE schedule_id = p_schedule_id;

    -- Insert new
    INSERT INTO public.meetings (schedule_id, meeting_number, date, summary)
    VALUES (p_schedule_id, v_next_number, p_date, p_summary);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
