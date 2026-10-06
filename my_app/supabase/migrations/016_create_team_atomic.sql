-- Tạo đội và host membership trong cùng transaction, tránh đội mồ côi.

create or replace function public.create_team(
  p_name text,
  p_description text,
  p_max_members integer,
  p_skill_level text,
  p_meeting_area text,
  p_meeting_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_team_id uuid;
begin
  if current_user_id is null then raise exception 'Bạn chưa đăng nhập.'; end if;
  if not exists (select 1 from public.profiles where id = current_user_id) then
    raise exception 'Tài khoản chưa có hồ sơ.';
  end if;

  insert into public.teams(
    host_id,
    name,
    description,
    max_members,
    skill_level,
    meeting_area,
    meeting_at,
    status
  ) values (
    current_user_id,
    trim(p_name),
    trim(p_description),
    p_max_members,
    p_skill_level,
    trim(p_meeting_area),
    p_meeting_at,
    'recruiting'
  ) returning id into new_team_id;

  insert into public.team_members(team_id, user_id, role, status)
  values (new_team_id, current_user_id, 'host', 'joined');

  return new_team_id;
end;
$$;

revoke all on function public.create_team(
  text, text, integer, text, text, timestamptz
) from public;
grant execute on function public.create_team(
  text, text, integer, text, text, timestamptz
) to authenticated;

notify pgrst, 'reload schema';
