-- Atomically creates an activity, its default team and the creator memberships.
-- Run this file once in the Supabase SQL Editor.
create or replace function public.create_activity_with_team(
  p_title text,
  p_description text,
  p_type text,
  p_location_name text,
  p_starts_at timestamptz,
  p_max_members integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_activity_id uuid;
  new_team_id uuid;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  if not exists (select 1 from public.profiles where id = current_user_id) then
    raise exception 'Tài khoản chưa có hồ sơ.';
  end if;

  insert into public.activities (
    creator_id, title, description, type, location_name,
    starts_at, max_members, is_public
  ) values (
    current_user_id, trim(p_title), trim(p_description),
    p_type::public.activity_type, trim(p_location_name),
    p_starts_at, p_max_members, true
  ) returning id into new_activity_id;

  insert into public.activity_members (activity_id, user_id, role, status)
  values (new_activity_id, current_user_id, 'host', 'joined');

  insert into public.teams (
    activity_id, host_id, name, description, max_members,
    skill_level, meeting_area, meeting_at, status
  ) values (
    new_activity_id, current_user_id, 'Đội ' || trim(p_title),
    trim(p_description), p_max_members, 'all',
    trim(p_location_name), p_starts_at, 'recruiting'
  ) returning id into new_team_id;

  insert into public.team_members (team_id, user_id, role, status)
  values (new_team_id, current_user_id, 'host', 'joined');

  return jsonb_build_object(
    'activity_id', new_activity_id,
    'team_id', new_team_id
  );
end;
$$;

revoke all on function public.create_activity_with_team(
  text, text, text, text, timestamptz, integer
) from public;

grant execute on function public.create_activity_with_team(
  text, text, text, text, timestamptz, integer
) to authenticated;
