-- Vá quyền thành viên/yêu cầu đội. Client không thể tự duyệt hoặc tự nâng role.

drop policy if exists "users can join teams as themselves" on public.team_members;
drop policy if exists "users can update their own team membership" on public.team_members;
drop policy if exists "users can leave teams" on public.team_members;

-- Chỉ host được tự thêm dòng host của chính đội họ vừa tạo.
create policy "hosts can add their own host membership"
  on public.team_members for insert to authenticated
  with check (
    user_id = auth.uid()
    and role = 'host'
    and status = 'joined'
    and exists (
      select 1 from public.teams t
      where t.id = team_id and t.host_id = auth.uid()
    )
  );

-- Thành viên thường chỉ được chuyển chính mình sang left, không được đổi role.
create policy "members can mark themselves left"
  on public.team_members for update to authenticated
  using (user_id = auth.uid() and role = 'member')
  with check (
    user_id = auth.uid()
    and role = 'member'
    and status = 'left'
  );

create policy "members can delete their own membership"
  on public.team_members for delete to authenticated
  using (user_id = auth.uid() and role = 'member');

drop policy if exists "users can join activities as themselves" on public.activity_members;
drop policy if exists "users can update their own activity membership" on public.activity_members;
drop policy if exists "users can leave activities" on public.activity_members;

create policy "activity creators can add own host membership"
  on public.activity_members for insert to authenticated
  with check (
    user_id = auth.uid()
    and role = 'host'
    and status = 'joined'
    and exists (
      select 1 from public.activities a
      where a.id = activity_id and a.creator_id = auth.uid()
    )
  );

create policy "activity members can mark themselves left"
  on public.activity_members for update to authenticated
  using (user_id = auth.uid() and role = 'member')
  with check (
    user_id = auth.uid()
    and role = 'member'
    and status = 'left'
  );

create policy "activity members can delete their own membership"
  on public.activity_members for delete to authenticated
  using (user_id = auth.uid() and role = 'member');

drop policy if exists "users can request teams as themselves" on public.team_requests;
drop policy if exists "requesters can cancel their requests" on public.team_requests;
drop policy if exists "hosts can review team requests" on public.team_requests;

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
  if current_user_id is null then raise exception 'Bạn chưa đăng nhập.'; end if;

  select * into target_team from public.teams where id = p_team_id for update;
  if not found then raise exception 'Không tìm thấy đội.'; end if;
  if target_team.host_id = current_user_id then
    raise exception 'Bạn đã là chủ đội.';
  end if;
  if target_team.status <> 'recruiting' then
    raise exception 'Đội hiện không nhận thêm thành viên.';
  end if;
  if exists (
    select 1 from public.team_members tm
    where tm.team_id = p_team_id
      and tm.user_id = current_user_id
      and tm.status = 'joined'
  ) then
    raise exception 'Bạn đã ở trong đội.';
  end if;

  insert into public.team_requests(team_id, user_id, message, status, updated_at)
  values (p_team_id, current_user_id, left(trim(p_message), 500), 'pending', now())
  on conflict (team_id, user_id) do update
    set message = excluded.message, status = 'pending', updated_at = now()
  returning id into request_id;

  return request_id;
end;
$$;

create or replace function public.reject_team_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.team_requests%rowtype;
begin
  select * into request_row
  from public.team_requests where id = p_request_id for update;
  if not found then raise exception 'Không tìm thấy yêu cầu.'; end if;
  if not exists (
    select 1 from public.teams t
    where t.id = request_row.team_id and t.host_id = auth.uid()
  ) then
    raise exception 'Chỉ chủ đội được từ chối yêu cầu.';
  end if;

  update public.team_requests
  set status = 'rejected', updated_at = now()
  where id = p_request_id and status = 'pending';
end;
$$;

revoke all on function public.request_to_join_team(uuid, text) from public;
revoke all on function public.reject_team_request(uuid) from public;
grant execute on function public.request_to_join_team(uuid, text) to authenticated;
grant execute on function public.reject_team_request(uuid) to authenticated;

notify pgrst, 'reload schema';
