-- now() cố định trong suốt một transaction. Với thao tác tạo phòng rồi gửi tin
-- rất nhanh, message.created_at có thể bằng last_read_at và bị bỏ khỏi unread.
-- clock_timestamp() phản ánh thời gian thực tại từng câu lệnh.

alter table public.conversation_members
  alter column last_read_at set default clock_timestamp();
alter table public.messages
  alter column created_at set default clock_timestamp();
alter table public.notifications
  alter column created_at set default clock_timestamp();

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  read_time timestamptz := clock_timestamp();
begin
  update public.conversation_members
  set last_read_at = read_time
  where conversation_id = p_conversation_id
    and user_id = auth.uid();

  if not found then
    raise exception 'Bạn không thuộc cuộc trò chuyện này.';
  end if;

  update public.notifications
  set read_at = read_time
  where user_id = auth.uid()
    and entity_type = 'conversation'
    and entity_id = p_conversation_id
    and read_at is null;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

notify pgrst, 'reload schema';
