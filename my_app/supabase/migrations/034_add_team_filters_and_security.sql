-- Migration 034: Add target_gender and join_policy filter columns to public.teams
-- and update create_team RPC with security enforcement.

alter table public.teams 
  add column if not exists target_gender text not null default 'all',
  add column if not exists join_policy text not null default 'everyone';

-- Ràng buộc kiểm tra giá trị hợp lệ
alter table public.teams
  drop constraint if exists teams_target_gender_check,
  add constraint teams_target_gender_check
    check (target_gender in ('all', 'female_only', 'male_only')) not valid,
  drop constraint if exists teams_join_policy_check,
  add constraint teams_join_policy_check
    check (join_policy in ('everyone', 'friends_only')) not valid;

-- Chú thích tài liệu trên Supabase schema
comment on column public.teams.target_gender is
  'Bộ lọc giới tính yêu cầu: all (Tất cả), female_only (Chỉ nữ), male_only (Chỉ nam).';
comment on column public.teams.join_policy is
  'Quyền gia nhập đội: everyone (Mọi người), friends_only (Chỉ bạn bè).';

-- Cập nhật hàm tạo đội atomic với tham số bộ lọc mới và bảo mật kiểm tra đầu vào
create or replace function public.create_team(
  p_name text,
  p_description text,
  p_max_members integer,
  p_skill_level text,
  p_meeting_area text,
  p_meeting_at timestamptz default null,
  p_target_gender text default 'all',
  p_join_policy text default 'everyone'
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
  if current_user_id is null then 
    raise exception 'Bạn chưa đăng nhập.'; 
  end if;

  if not exists (select 1 from public.profiles where id = current_user_id) then
    raise exception 'Tài khoản chưa có hồ sơ.';
  end if;

  -- Kiểm tra dữ liệu bộ lọc hợp lệ
  if p_target_gender not in ('all', 'female_only', 'male_only') then
    raise exception 'Yêu cầu giới tính không hợp lệ.';
  end if;

  if p_join_policy not in ('everyone', 'friends_only') then
    raise exception 'Quyền tham gia không hợp lệ.';
  end if;

  insert into public.teams(
    host_id,
    name,
    description,
    max_members,
    skill_level,
    meeting_area,
    meeting_at,
    target_gender,
    join_policy,
    status
  ) values (
    current_user_id,
    trim(p_name),
    trim(p_description),
    p_max_members,
    p_skill_level,
    trim(p_meeting_area),
    p_meeting_at,
    p_target_gender,
    p_join_policy,
    'recruiting'
  ) returning id into new_team_id;

  insert into public.team_members(team_id, user_id, role, status)
  values (new_team_id, current_user_id, 'host', 'joined');

  return new_team_id;
end;
$$;

notify pgrst, 'reload schema';
