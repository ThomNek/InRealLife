-- Đánh dấu thông báo đã đọc qua RPC để user_id và thời gian luôn do server xác định.
-- Client không còn UPDATE trực tiếp public.notifications.

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
  changed_rows integer;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  update public.notifications
  set read_at = coalesce(read_at, clock_timestamp())
  where id = p_notification_id
    and user_id = current_user_id;

  get diagnostics changed_rows = row_count;
  if changed_rows = 0 then
    raise exception 'Không tìm thấy thông báo.';
  end if;
end;
$$;

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

revoke update on table public.notifications from authenticated;
revoke update (read_at) on table public.notifications from authenticated;

revoke all on function public.mark_notification_read(uuid)
  from public, anon, authenticated;
revoke all on function public.mark_all_notifications_read()
  from public, anon, authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.mark_all_notifications_read() to authenticated;

comment on function public.mark_notification_read(uuid) is
  'QuestReal migration 025: marks one owned notification read using server time.';
comment on function public.mark_all_notifications_read() is
  'QuestReal migration 025: marks all owned notifications read using server time.';

notify pgrst, 'reload schema';
