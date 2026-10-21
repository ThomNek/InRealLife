-- Migration 040: Fix schema cache – ensure all columns and RPCs are correctly
-- registered and re-grant necessary permissions.
-- Run this on Supabase Dashboard → SQL Editor when the app shows
-- "could not find column/function in schema cache" errors.

-- ─── 1. Profiles: bổ sung cột nếu chưa có ─────────────────────────────────

alter table public.profiles
  add column if not exists birth_year smallint,
  add column if not exists profile_visibility text not null default 'public',
  add column if not exists gender text not null default 'other',
  add column if not exists bio text,
  add column if not exists city text,
  add column if not exists district text,
  add column if not exists education text,
  add column if not exists show_age boolean not null default true,
  add column if not exists show_location boolean not null default true,
  add column if not exists allow_friend_requests boolean not null default true,
  add column if not exists birth_date text;

-- Ràng buộc an toàn
alter table public.profiles
  drop constraint if exists profiles_birth_year_check,
  add constraint profiles_birth_year_check
    check (birth_year is null or birth_year between 1900 and 2100),
  drop constraint if exists profiles_profile_visibility_check,
  add constraint profiles_profile_visibility_check
    check (profile_visibility in ('public', 'shared', 'private')),
  drop constraint if exists profiles_gender_check,
  add constraint profiles_gender_check
    check (gender in ('male', 'female', 'other'));

-- Grant column permissions cho user thường (authenticated)
grant insert (
  birth_year, profile_visibility, gender, bio, city, district,
  education, show_age, show_location, allow_friend_requests, birth_date
) on table public.profiles to authenticated;

grant update (
  birth_year, profile_visibility, gender, bio, city, district,
  education, show_age, show_location, allow_friend_requests, birth_date
) on table public.profiles to authenticated;

-- ─── 2. mark_all_notifications_read – tái tạo hàm ─────────────────────────

create or replace function public.mark_all_notifications_read()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  changed_rows integer;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  update public.notifications
  set read_at = clock_timestamp()
  where user_id = current_user_id
    and read_at is null;

  get diagnostics changed_rows = row_count;
  return changed_rows;
end;
$$;

revoke all on function public.mark_all_notifications_read()
  from public, anon, authenticated;
grant execute on function public.mark_all_notifications_read() to authenticated;

-- ─── 3. mark_notification_read – tái tạo hàm ──────────────────────────────

create or replace function public.mark_notification_read(
  p_notification_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  update public.notifications
  set read_at = coalesce(read_at, clock_timestamp())
  where id = p_notification_id
    and user_id = current_user_id;
end;
$$;

revoke all on function public.mark_notification_read(uuid)
  from public, anon, authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;

-- ─── 4. request_to_join_team – tái tạo hàm ────────────────────────────────

create or replace function public.request_to_join_team(
  p_team_id uuid,
  p_message text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_team public.teams%rowtype;
  request_id uuid;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  select * into target_team from public.teams where id = p_team_id;
  if not found then
    raise exception 'Đội không tồn tại.';
  end if;

  if target_team.status not in ('recruiting', 'full') then
    raise exception 'Đội không còn nhận thành viên.';
  end if;

  if exists (
    select 1 from public.team_members
    where team_id = p_team_id and user_id = current_user_id and status = 'joined'
  ) then
    raise exception 'Bạn đã là thành viên của đội này.';
  end if;

  insert into public.team_requests (team_id, user_id, message, status)
  values (p_team_id, current_user_id, left(trim(coalesce(p_message, '')), 500), 'pending')
  on conflict (team_id, user_id) do update
    set message = excluded.message,
        status = case
          when team_requests.status = 'rejected' then 'pending'
          else team_requests.status
        end,
        updated_at = now()
  returning id into request_id;

  return request_id;
end;
$$;

revoke all on function public.request_to_join_team(uuid, text)
  from public, anon, authenticated;
grant execute on function public.request_to_join_team(uuid, text) to authenticated;

-- ─── 5. Reload PostgREST schema cache ──────────────────────────────────────

notify pgrst, 'reload schema';
