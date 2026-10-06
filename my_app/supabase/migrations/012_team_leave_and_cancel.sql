-- Thành viên tự rời đội và người gửi tự hủy yêu cầu theo cách đồng bộ.

create or replace function public.cancel_team_request(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Bạn chưa đăng nhập.'; end if;

  update public.team_requests
  set status = 'cancelled', updated_at = now()
  where team_id = p_team_id
    and user_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'Không có yêu cầu đang chờ để hủy.';
  end if;
end;
$$;

create or replace function public.leave_team(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  team_row public.teams%rowtype;
begin
  if auth.uid() is null then raise exception 'Bạn chưa đăng nhập.'; end if;

  select * into team_row from public.teams where id = p_team_id for update;
  if not found then raise exception 'Không tìm thấy đội.'; end if;
  if team_row.host_id = auth.uid() then
    raise exception 'Chủ đội không thể tự rời đội. Hãy chuyển quyền hoặc hủy đội.';
  end if;

  update public.team_members
  set status = 'left'
  where team_id = p_team_id
    and user_id = auth.uid()
    and role = 'member'
    and status = 'joined';

  if not found then raise exception 'Bạn không phải thành viên của đội.'; end if;

  if team_row.activity_id is not null then
    update public.activity_members
    set status = 'left'
    where activity_id = team_row.activity_id
      and user_id = auth.uid()
      and role = 'member';

    update public.activities
    set status = 'open', updated_at = now()
    where id = team_row.activity_id and status = 'full';
  end if;

  update public.teams
  set status = 'recruiting', updated_at = now()
  where id = p_team_id and status = 'full';
end;
$$;

revoke all on function public.cancel_team_request(uuid) from public;
revoke all on function public.leave_team(uuid) from public;
grant execute on function public.cancel_team_request(uuid) to authenticated;
grant execute on function public.leave_team(uuid) to authenticated;

notify pgrst, 'reload schema';
