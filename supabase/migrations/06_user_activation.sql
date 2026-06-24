-- 06_user_activation.sql
-- Adds is_active column and RPC to toggle user status

ALTER TABLE public.profiles ADD COLUMN is_active BOOLEAN DEFAULT true NOT NULL;

CREATE OR REPLACE FUNCTION toggle_user_status_by_admin(
  target_user_id UUID,
  new_status BOOLEAN
) RETURNS void AS $$
BEGIN
  -- Verify caller is admin
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Unauthorized: Only admin can toggle status';
  END IF;

  UPDATE public.profiles
  SET is_active = new_status
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
