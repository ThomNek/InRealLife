-- Chuẩn hóa nội dung yêu cầu và không báo thành công cho transition no-op.

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
  if not exists (select 1 from public.profiles where id = current_user_id) then
    raise exception 'Tài khoản chưa có hồ sơ.';
  end if;

  select * into target_team
  from public.teams
  where id = p_team_id
  for update;

  if not found then raise exception 'Không tìm thấy đội.'; end if;
  if target_team.host_id = current_user_id then
    raise exception 'Bạn đã là chủ đội.';
  end if;
  if target_team.status <> 'recruiting' then
    raise exception 'Đội hiện không nhận thêm thành viên.';
  end if;
  if exists (
    select 1
    from public.team_members tm
    where tm.team_id = p_team_id
      and tm.user_id = current_user_id
      and tm.status = 'joined'
  ) then
    raise exception 'Bạn đã ở trong đội.';
  end if;

  insert into public.team_requests(team_id, user_id, message, status, updated_at)
  values (
    p_team_id,
    current_user_id,
    left(trim(coalesce(p_message, '')), 500),
    'pending',
    clock_timestamp()
  )
  on conflict (team_id, user_id) do update
    set message = excluded.message,
        status = 'pending',
        updated_at = clock_timestamp()
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
  current_user_id uuid := auth.uid();
  request_row public.team_requests%rowtype;
begin
  if current_user_id is null then raise exception 'Bạn chưa đăng nhập.'; end if;

  select * into request_row
  from public.team_requests
  where id = p_request_id
  for update;

  if not found then raise exception 'Không tìm thấy yêu cầu.'; end if;
  if not exists (
    select 1
    from public.teams t
    where t.id = request_row.team_id
      and t.host_id = current_user_id
  ) then
    raise exception 'Chỉ chủ đội được từ chối yêu cầu.';
  end if;
  if request_row.status <> 'pending' then
    raise exception 'Yêu cầu này không còn ở trạng thái chờ duyệt.';
  end if;

  update public.team_requests
  set status = 'rejected', updated_at = clock_timestamp()
  where id = p_request_id;
end;
$$;

revoke all on function public.request_to_join_team(uuid, text)
  from public, anon, authenticated;
revoke all on function public.reject_team_request(uuid)
  from public, anon, authenticated;
grant execute on function public.request_to_join_team(uuid, text)
  to authenticated;
grant execute on function public.reject_team_request(uuid)
  to authenticated;

comment on function public.request_to_join_team(uuid, text) is
  'QuestReal migration 026: normalized message and locked request creation.';
comment on function public.reject_team_request(uuid) is
  'QuestReal migration 026: only pending requests can transition to rejected.';

notify pgrst, 'reload schema';
