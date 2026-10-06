-- Migration 035: Expansion for Profiles, Friendships, Reputation & Rating, and Teams schema
-- Runs on Supabase SQL Editor to apply database updates.

-- ============================================================================
-- 1. TẠO BẢNG PUBLIC.FRIENDSHIPS (DANH SÁCH & QUẢN LÝ BẠN BÈ)
-- ============================================================================

create table if not exists public.friendships (
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  constraint friendships_different_users check (user_id <> friend_id)
);

-- Index tra cứu bạn bè
create index if not exists friendships_friend_idx on public.friendships(friend_id);
create index if not exists friendships_status_idx on public.friendships(status);

-- Bật RLS cho friendships
alter table public.friendships enable row level security;

-- Policy RLS cho friendships
drop policy if exists "Users can view their friendships" on public.friendships;
create policy "Users can view their friendships"
  on public.friendships for select to authenticated
  using (user_id = auth.uid() or friend_id = auth.uid());

drop policy if exists "Users can send friend requests" on public.friendships;
create policy "Users can send friend requests"
  on public.friendships for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can update their received friend requests" on public.friendships;
create policy "Users can update their received friend requests"
  on public.friendships for update to authenticated
  using (friend_id = auth.uid() or user_id = auth.uid());

drop policy if exists "Users can delete their friendships" on public.friendships;
create policy "Users can delete their friendships"
  on public.friendships for delete to authenticated
  using (user_id = auth.uid() or friend_id = auth.uid());

-- ============================================================================
-- 2. BỔ SUNG CỘT BẢNG PUBLIC.PROFILES (HỒ SƠ, BẢO MẬT, UY TÍN, ĐÁNH GIÁ & THỐNG KÊ)
-- ============================================================================

alter table public.profiles
  add column if not exists birth_date date,
  add column if not exists gender text default 'other',
  add column if not exists district text default '',
  add column if not exists show_age boolean not null default true,
  add column if not exists show_location boolean not null default true,
  add column if not exists allow_friend_requests boolean not null default true,
  add column if not exists opened_treasures_count integer not null default 0,
  add column if not exists total_distance_km numeric(10, 2) not null default 0.00,
  add column if not exists explored_places_count integer not null default 0,
  add column if not exists featured_badge_ids uuid[] not null default '{}',
  add column if not exists reputation_score integer not null default 100,
  add column if not exists rating_avg numeric(3, 2) not null default 5.00,
  add column if not exists rating_count integer not null default 0;

-- Constraints kiểm tra dữ liệu hợp lệ cho profiles
alter table public.profiles
  drop constraint if exists profiles_gender_check,
  add constraint profiles_gender_check
    check (gender in ('male', 'female', 'other')) not valid,
  drop constraint if exists profiles_featured_badges_limit_check,
  add constraint profiles_featured_badges_limit_check
    check (array_length(featured_badge_ids, 1) is null or array_length(featured_badge_ids, 1) <= 5) not valid,
  drop constraint if exists profiles_stats_positive_check,
  add constraint profiles_stats_positive_check
    check (
      opened_treasures_count >= 0
      and total_distance_km >= 0
      and explored_places_count >= 0
      and reputation_score >= 0
      and rating_avg between 1.00 and 5.00
      and rating_count >= 0
    ) not valid;

-- Grant quyền sửa cho user đối với các cột được phép chỉnh sửa
grant insert (
  birth_date,
  gender,
  district,
  show_age,
  show_location,
  allow_friend_requests,
  featured_badge_ids
) on table public.profiles to authenticated;

grant update (
  birth_date,
  gender,
  district,
  show_age,
  show_location,
  allow_friend_requests,
  featured_badge_ids
) on table public.profiles to authenticated;

comment on column public.profiles.birth_date is 'Ngày tháng năm sinh của người dùng.';
comment on column public.profiles.gender is 'Giới tính: male (Nam), female (Nữ), other (Khác).';
comment on column public.profiles.district is 'Quận / Huyện nơi ở.';
comment on column public.profiles.show_age is 'Cờ bảo mật: Hiện/Ẩn tuổi trên Profile.';
comment on column public.profiles.show_location is 'Cờ bảo mật: Hiện/Ẩn khu vực nơi ở trên Profile.';
comment on column public.profiles.allow_friend_requests is 'Cờ bảo mật: Cho phép người lạ gửi lời mời kết bạn.';
comment on column public.profiles.opened_treasures_count is 'Thống kê: Số kho báu đã mở thành công.';
comment on column public.profiles.total_distance_km is 'Thống kê: Tổng quãng đường di chuyển (km).';
comment on column public.profiles.explored_places_count is 'Thống kê: Nhật ký khám phá (Số địa điểm đã ghé thăm).';
comment on column public.profiles.featured_badge_ids is 'Mảng lưu tối đa 5 ID Huy hiệu được ghim lên Profile.';
comment on column public.profiles.reputation_score is 'Điểm uy tín thợ săn (Mặc định 100).';
comment on column public.profiles.rating_avg is 'Điểm đánh giá trung bình từ đồng đội (1.00 đến 5.00).';
comment on column public.profiles.rating_count is 'Tổng số lượt đồng đội đã đánh giá.';

-- ============================================================================
-- 3. BỔ SUNG CỘT BẢNG PUBLIC.TEAMS (LOẠI HOẠT ĐỘNG, KHO BÁU CÁ NHÂN & ĐỊA LÝ)
-- ============================================================================

alter table public.teams
  add column if not exists activity_type text not null default 'treasure_hunt',
  add column if not exists personal_treasure_id uuid,
  add column if not exists meeting_city text not null default '',
  add column if not exists meeting_district text not null default '',
  add column if not exists latitude numeric(10, 6),
  add column if not exists longitude numeric(10, 6);

-- Ràng buộc loại hoạt động
alter table public.teams
  drop constraint if exists teams_activity_type_check,
  add constraint teams_activity_type_check
    check (activity_type in ('treasure_hunt', 'walking', 'running', 'exchange', 'other')) not valid;

comment on column public.teams.activity_type is 'Loại hoạt động: treasure_hunt (Săn kho báu), walking (Đi bộ), running, exchange, other.';
comment on column public.teams.personal_treasure_id is 'ID Kho báu cá nhân gắn liền với đội săn (nếu loại là treasure_hunt).';
comment on column public.teams.meeting_city is 'Thành phố tập hợp (dùng cho Bộ lọc Vùng).';
comment on column public.teams.meeting_district is 'Quận / Huyện tập hợp (dùng cho Bộ lọc Vùng).';
comment on column public.teams.latitude is 'Tọa độ vĩ độ điểm hẹn (dùng tính khoảng cách km).';
comment on column public.teams.longitude is 'Tọa độ kinh độ điểm hẹn (dùng tính khoảng cách km).';

-- ============================================================================
-- 4. CẬP NHẬT HÀM RPC CREATE_TEAM TOÀN DIỆN
-- ============================================================================

create or replace function public.create_team(
  p_name text,
  p_description text,
  p_max_members integer,
  p_skill_level text,
  p_meeting_area text,
  p_meeting_at timestamptz default null,
  p_target_gender text default 'all',
  p_join_policy text default 'everyone',
  p_activity_type text default 'treasure_hunt',
  p_personal_treasure_id uuid default null,
  p_meeting_city text default '',
  p_meeting_district text default '',
  p_latitude numeric default null,
  p_longitude numeric default null
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

  -- Kiểm tra dữ liệu hợp lệ
  if p_target_gender not in ('all', 'female_only', 'male_only') then
    raise exception 'Yêu cầu giới tính không hợp lệ.';
  end if;

  if p_join_policy not in ('everyone', 'friends_only') then
    raise exception 'Quyền tham gia không hợp lệ.';
  end if;

  if p_activity_type not in ('treasure_hunt', 'walking', 'running', 'exchange', 'other') then
    raise exception 'Loại hoạt động không hợp lệ.';
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
    activity_type,
    personal_treasure_id,
    meeting_city,
    meeting_district,
    latitude,
    longitude,
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
    p_activity_type,
    p_personal_treasure_id,
    trim(p_meeting_city),
    trim(p_meeting_district),
    p_latitude,
    p_longitude,
    'recruiting'
  ) returning id into new_team_id;

  insert into public.team_members(team_id, user_id, role, status)
  values (new_team_id, current_user_id, 'host', 'joined');

  return new_team_id;
end;
$$;

notify pgrst, 'reload schema';
