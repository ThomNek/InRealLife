-- Hoàn thiện hai trường đã có trên giao diện chỉnh sửa hồ sơ.
-- ADD COLUMN IF NOT EXISTS bảo toàn toàn bộ dữ liệu hiện có.

alter table public.profiles
  add column if not exists birth_year smallint,
  add column if not exists profile_visibility text not null default 'public';

alter table public.profiles
  drop constraint if exists profiles_birth_year_check,
  add constraint profiles_birth_year_check
    check (birth_year is null or birth_year between 1900 and 2100),
  drop constraint if exists profiles_profile_visibility_check,
  add constraint profiles_profile_visibility_check
    check (profile_visibility in ('public', 'shared', 'private'));

-- Chính chủ luôn xem được mình. Hồ sơ shared chỉ hiện cho người cùng đội hoặc
-- hai phía của một yêu cầu tham gia đang chờ; private chỉ hiện cho chính chủ.
drop policy if exists "Authenticated users can view profiles" on public.profiles;
create policy "Authenticated users can view allowed profiles"
  on public.profiles for select to authenticated
  using (
    id = auth.uid()
    or profile_visibility = 'public'
    or (
      profile_visibility = 'shared'
      and (
        exists (
          select 1
          from public.team_members viewer
          join public.team_members target
            on target.team_id = viewer.team_id
           and target.user_id = profiles.id
           and target.status = 'joined'
          where viewer.user_id = auth.uid()
            and viewer.status = 'joined'
        )
        or exists (
          select 1
          from public.team_requests request
          join public.teams team on team.id = request.team_id
          where request.status = 'pending'
            and (
              (team.host_id = auth.uid() and request.user_id = profiles.id)
              or (request.user_id = auth.uid() and team.host_id = profiles.id)
            )
        )
      )
    )
  );

-- Migration 014 đã giới hạn column privileges; chỉ bổ sung đúng hai cột hồ sơ
-- thông thường. RLS "Users can update own profile" vẫn giới hạn đúng auth.uid().
grant insert (birth_year, profile_visibility)
  on table public.profiles to authenticated;
grant update (birth_year, profile_visibility)
  on table public.profiles to authenticated;

comment on column public.profiles.birth_year is
  'Năm sinh tùy chọn; không dùng để phân quyền.';
comment on column public.profiles.profile_visibility is
  'Mức hiển thị hồ sơ: public, shared (cùng đội/yêu cầu) hoặc private.';

notify pgrst, 'reload schema';
