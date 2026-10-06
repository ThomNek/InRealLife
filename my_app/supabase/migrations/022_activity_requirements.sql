-- Lưu đầy đủ hai trường đã có trên form tạo hoạt động. Migration chỉ bổ sung
-- cột và giữ nguyên toàn bộ hoạt động hiện có bằng giá trị mặc định an toàn.

alter table public.activities
  add column if not exists skill_level text not null default 'all',
  add column if not exists preparation_notes text not null default '';

alter table public.activities
  drop constraint if exists activities_skill_level_check,
  add constraint activities_skill_level_check
    check (skill_level in ('beginner', 'basic', 'intermediate', 'advanced', 'all')),
  drop constraint if exists activities_preparation_notes_length_check,
  add constraint activities_preparation_notes_length_check
    check (char_length(preparation_notes) <= 2000);

create or replace function public.create_activity_with_team(
  p_title text,
  p_description text,
  p_type text,
  p_location_name text,
  p_starts_at timestamptz,
  p_max_members integer,
  p_skill_level text,
  p_preparation_notes text
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
  if current_user_id is null then raise exception 'Bạn chưa đăng nhập.'; end if;
  if not exists (select 1 from public.profiles where id = current_user_id) then
    raise exception 'Tài khoản chưa có hồ sơ.';
  end if;

  insert into public.activities (
    creator_id, title, description, type, location_name, starts_at,
    max_members, is_public, skill_level, preparation_notes
  ) values (
    current_user_id, trim(p_title), trim(p_description),
    p_type::public.activity_type, trim(p_location_name), p_starts_at,
    p_max_members, true, p_skill_level, left(trim(p_preparation_notes), 2000)
  ) returning id into new_activity_id;

  insert into public.activity_members(activity_id, user_id, role, status)
  values (new_activity_id, current_user_id, 'host', 'joined');

  insert into public.teams (
    activity_id, host_id, name, description, max_members,
    skill_level, meeting_area, meeting_at, status
  ) values (
    new_activity_id, current_user_id, 'Đội ' || trim(p_title),
    trim(p_description), p_max_members,
    case when p_skill_level = 'basic' then 'beginner' else p_skill_level end,
    trim(p_location_name), p_starts_at, 'recruiting'
  ) returning id into new_team_id;

  insert into public.team_members(team_id, user_id, role, status)
  values (new_team_id, current_user_id, 'host', 'joined');

  return jsonb_build_object(
    'activity_id', new_activity_id,
    'team_id', new_team_id
  );
end;
$$;

revoke all on function public.create_activity_with_team(
  text, text, text, text, timestamptz, integer, text, text
) from public;
grant execute on function public.create_activity_with_team(
  text, text, text, text, timestamptz, integer, text, text
) to authenticated;

comment on column public.activities.skill_level is
  'Trình độ phù hợp: beginner, basic, intermediate, advanced hoặc all.';
comment on column public.activities.preparation_notes is
  'Vật dụng cần chuẩn bị và quy tắc do người tổ chức cung cấp.';

notify pgrst, 'reload schema';
