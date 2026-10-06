-- Migration 036: Update create_activity_with_team RPC to support p_target_gender and p_join_policy

create or replace function public.create_activity_with_team(
  p_title text,
  p_description text,
  p_type text,
  p_location_name text,
  p_starts_at timestamptz,
  p_max_members integer,
  p_skill_level text default 'all',
  p_preparation_notes text default '',
  p_target_gender text default 'all',
  p_join_policy text default 'everyone'
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

  if p_target_gender not in ('all', 'female_only', 'male_only') then
    raise exception 'Yêu cầu giới tính không hợp lệ.';
  end if;

  if p_join_policy not in ('everyone', 'friends_only') then
    raise exception 'Quyền gia nhập không hợp lệ.';
  end if;

  insert into public.activities (
    creator_id, title, description, type, location_name,
    starts_at, max_members, skill_level, preparation_notes, is_public
  ) values (
    current_user_id, trim(p_title), trim(p_description),
    p_type::public.activity_type, trim(p_location_name),
    p_starts_at, p_max_members, p_skill_level, trim(p_preparation_notes), true
  ) returning id into new_activity_id;

  insert into public.activity_members (activity_id, user_id, role, status)
  values (new_activity_id, current_user_id, 'host', 'joined');

  insert into public.teams (
    activity_id, host_id, name, description, max_members,
    skill_level, meeting_area, meeting_at, target_gender, join_policy, status
  ) values (
    new_activity_id, current_user_id, 'Đội ' || trim(p_title),
    trim(p_description), p_max_members, p_skill_level,
    trim(p_location_name), p_starts_at, p_target_gender, p_join_policy, 'recruiting'
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
  text, text, text, text, timestamptz, integer, text, text, text, text
) from public;

grant execute on function public.create_activity_with_team(
  text, text, text, text, timestamptz, integer, text, text, text, text
) to authenticated;

notify pgrst, 'reload schema';
