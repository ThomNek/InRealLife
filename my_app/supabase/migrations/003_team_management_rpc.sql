-- Host-only operations. Run once in the Supabase SQL Editor.
create or replace function public.approve_team_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.team_requests%rowtype;
  team_row public.teams%rowtype;
  member_count integer;
begin
  select * into request_row from public.team_requests where id = p_request_id for update;
  if not found then raise exception 'Không tìm thấy yêu cầu.'; end if;

  select * into team_row from public.teams where id = request_row.team_id for update;
  if team_row.host_id <> auth.uid() then raise exception 'Chỉ chủ đội được duyệt.'; end if;

  select count(*) into member_count from public.team_members
  where team_id = team_row.id and status = 'joined';
  if member_count >= team_row.max_members then raise exception 'Đội đã đủ thành viên.'; end if;

  update public.team_requests
  set status = 'approved', updated_at = now()
  where id = p_request_id;

  insert into public.team_members (team_id, user_id, role, status)
  values (team_row.id, request_row.user_id, 'member', 'joined')
  on conflict (team_id, user_id)
  do update set status = 'joined', role = 'member', joined_at = now();

  if team_row.activity_id is not null then
    insert into public.activity_members (activity_id, user_id, role, status)
    values (team_row.activity_id, request_row.user_id, 'member', 'joined')
    on conflict (activity_id, user_id)
    do update set status = 'joined', role = 'member', joined_at = now();
  end if;
end;
$$;

create or replace function public.kick_team_member(p_team_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  team_host uuid;
  linked_activity_id uuid;
begin
  select host_id, activity_id into team_host, linked_activity_id
  from public.teams where id = p_team_id;
  if team_host is null then raise exception 'Không tìm thấy đội.'; end if;
  if team_host <> auth.uid() then raise exception 'Chỉ chủ đội được kích thành viên.'; end if;
  if p_user_id = team_host then raise exception 'Không thể kích chủ đội.'; end if;

  update public.team_members
  set status = 'left'
  where team_id = p_team_id and user_id = p_user_id and role <> 'host';

  if linked_activity_id is not null then
    update public.activity_members
    set status = 'left'
    where activity_id = linked_activity_id and user_id = p_user_id and role <> 'host';
  end if;
end;
$$;

revoke all on function public.approve_team_request(uuid) from public;
revoke all on function public.kick_team_member(uuid, uuid) from public;
grant execute on function public.approve_team_request(uuid) to authenticated;
grant execute on function public.kick_team_member(uuid, uuid) to authenticated;

-- Ask PostgREST to discover the newly created RPC functions immediately.
notify pgrst, 'reload schema';
