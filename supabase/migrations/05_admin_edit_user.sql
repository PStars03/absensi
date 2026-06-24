-- 05_admin_edit_user.sql
-- Adds an RPC function to allow Super Admins to edit a user's profile

CREATE OR REPLACE FUNCTION update_user_profile_by_admin(
  target_user_id UUID,
  new_full_name TEXT DEFAULT NULL,
  new_nisn_nip TEXT DEFAULT NULL
) RETURNS void AS $$
BEGIN
  -- Verify caller is superadmin
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'superadmin') THEN
    RAISE EXCEPTION 'Unauthorized: Only superadmin can update profiles';
  END IF;

  UPDATE public.profiles
  SET 
    full_name = COALESCE(new_full_name, full_name),
    identity_number = COALESCE(new_nisn_nip, identity_number)
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
