-- QuestReal: activity participation and team management
-- Requires public.activities(id) and public.profiles(id) to exist.

create table if not exists public.activity_members (
  activity_id uuid not null references public.activities(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('host', 'member')),
  status text not null default 'joined'
    check (status in ('pending', 'joined', 'rejected', 'left')),
  joined_at timestamptz not null default now(),
  primary key (activity_id, user_id)
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid references public.activities(id) on delete set null,
  host_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 80),
  description text not null default '',
  max_members integer not null default 4 check (max_members between 2 and 20),
  skill_level text not null default 'beginner'
    check (skill_level in ('beginner', 'intermediate', 'advanced', 'all')),
  meeting_area text not null default '',
  meeting_at timestamptz,
  status text not null default 'recruiting'
    check (status in ('recruiting', 'full', 'started', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.team_members (
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('host', 'member')),
  status text not null default 'joined'
    check (status in ('pending', 'joined', 'rejected', 'left')),
  joined_at timestamptz not null default now(),
  primary key (team_id, user_id)
);

create table if not exists public.team_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, user_id)
);

create index if not exists activity_members_user_idx
  on public.activity_members(user_id);
create index if not exists teams_activity_idx
  on public.teams(activity_id);
create index if not exists teams_host_idx
  on public.teams(host_id);
create index if not exists team_members_user_idx
  on public.team_members(user_id);
create index if not exists team_requests_team_status_idx
  on public.team_requests(team_id, status);

-- Documentation stored in Supabase so the schema remains understandable later.
comment on table public.activity_members is
  'Danh sách người tham gia từng hoạt động; mỗi dòng nối một user với một activity.';
comment on column public.activity_members.activity_id is
  'ID hoạt động trong public.activities.';
comment on column public.activity_members.user_id is
  'ID người dùng trong public.profiles.';
comment on column public.activity_members.role is
  'Vai trò trong hoạt động: host hoặc member.';
comment on column public.activity_members.status is
  'Trạng thái tham gia: pending, joined, rejected hoặc left.';

comment on table public.teams is
  'Đội được tạo để cùng tham gia một hoạt động ngoài đời.';
comment on column public.teams.activity_id is
  'Hoạt động mục tiêu của đội; có thể null nếu đội chưa chọn hoạt động.';
comment on column public.teams.host_id is
  'ID người tạo và quản lý đội; không phải mã chia sẻ đội.';
comment on column public.teams.id is
  'UUID định danh nội bộ của đội, dùng để liên kết các bảng khác.';

comment on table public.team_members is
  'Danh sách thành viên và trạng thái tham gia của từng đội.';
comment on column public.team_members.team_id is
  'ID đội trong public.teams.';
comment on column public.team_members.user_id is
  'ID thành viên trong public.profiles.';

comment on table public.team_requests is
  'Yêu cầu tham gia đội; host duyệt hoặc từ chối yêu cầu.';
comment on column public.team_requests.team_id is
  'Đội mà người dùng muốn tham gia.';
comment on column public.team_requests.user_id is
  'Người gửi yêu cầu tham gia.';
comment on column public.team_requests.status is
  'Trạng thái yêu cầu: pending, approved, rejected hoặc cancelled.';

alter table public.activity_members enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.team_requests enable row level security;

-- Activity membership: users manage only their own membership row.
create policy "activity members are visible to authenticated users"
  on public.activity_members for select to authenticated using (true);

create policy "users can join activities as themselves"
  on public.activity_members for insert to authenticated
  with check (auth.uid() = user_id);

create policy "users can update their own activity membership"
  on public.activity_members for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users can leave activities"
  on public.activity_members for delete to authenticated
  using (auth.uid() = user_id);

-- Teams are discoverable by signed-in users; only the host owns the team.
create policy "authenticated users can view teams"
  on public.teams for select to authenticated using (true);

create policy "users can create teams as host"
  on public.teams for insert to authenticated
  with check (auth.uid() = host_id);

create policy "hosts can update their teams"
  on public.teams for update to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

create policy "hosts can delete their teams"
  on public.teams for delete to authenticated
  using (auth.uid() = host_id);

create policy "team members are visible to authenticated users"
  on public.team_members for select to authenticated using (true);

create policy "users can join teams as themselves"
  on public.team_members for insert to authenticated
  with check (auth.uid() = user_id);

create policy "users can update their own team membership"
  on public.team_members for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users can leave teams"
  on public.team_members for delete to authenticated
  using (auth.uid() = user_id);

create policy "authenticated users can view team requests"
  on public.team_requests for select to authenticated
  using (auth.uid() = user_id or exists (
    select 1 from public.teams t
    where t.id = team_id and t.host_id = auth.uid()
  ));

create policy "users can request teams as themselves"
  on public.team_requests for insert to authenticated
  with check (auth.uid() = user_id);

create policy "requesters can cancel their requests"
  on public.team_requests for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "hosts can review team requests"
  on public.team_requests for update to authenticated
  using (exists (
    select 1 from public.teams t
    where t.id = team_id and t.host_id = auth.uid()
  ));

create policy "requesters can delete their requests"
  on public.team_requests for delete to authenticated
  using (auth.uid() = user_id);
