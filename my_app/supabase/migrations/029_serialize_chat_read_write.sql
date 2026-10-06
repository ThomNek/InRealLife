-- Serialize gửi/đọc theo từng conversation để unread không bị sai khi hai
-- transaction chạy đồng thời. Membership cũng được khóa trong lúc kiểm tra.

create or replace function public.send_message(
  p_conversation_id uuid,
  p_content text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_content text := trim(p_content);
  conversation_type text;
  conversation_team_id uuid;
  new_message_id uuid;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;
  if normalized_content is null or normalized_content = '' then
    raise exception 'Tin nhắn không được để trống.';
  end if;
  if char_length(normalized_content) > 2000 then
    raise exception 'Tin nhắn không được vượt quá 2.000 ký tự.';
  end if;

  -- Mọi send/mark-read của cùng một phòng đi qua cùng khóa này.
  select c.type, c.team_id
  into conversation_type, conversation_team_id
  from public.conversations c
  where c.id = p_conversation_id
  for update;

  if not found then raise exception 'Không tìm thấy cuộc trò chuyện.'; end if;

  if conversation_type = 'team' then
    perform 1
    from public.team_members tm
    where tm.team_id = conversation_team_id
      and tm.user_id = current_user_id
      and tm.status = 'joined'
    for update;
    if not found then
      raise exception 'Bạn không thuộc cuộc trò chuyện này.';
    end if;
  end if;

  perform 1
  from public.conversation_members cm
  where cm.conversation_id = p_conversation_id
    and cm.user_id = current_user_id
  for update;
  if not found then raise exception 'Bạn không thuộc cuộc trò chuyện này.'; end if;

  insert into public.messages(
    conversation_id,
    sender_id,
    content,
    created_at
  ) values (
    p_conversation_id,
    current_user_id,
    normalized_content,
    clock_timestamp()
  )
  returning id into new_message_id;

  return new_message_id;
end;
$$;

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  conversation_type text;
  conversation_team_id uuid;
  read_time timestamptz;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  select c.type, c.team_id
  into conversation_type, conversation_team_id
  from public.conversations c
  where c.id = p_conversation_id
  for update;

  if not found then raise exception 'Không tìm thấy cuộc trò chuyện.'; end if;

  if conversation_type = 'team' then
    perform 1
    from public.team_members tm
    where tm.team_id = conversation_team_id
      and tm.user_id = current_user_id
      and tm.status = 'joined'
    for update;
    if not found then
      raise exception 'Bạn không thuộc cuộc trò chuyện này.';
    end if;
  end if;

  perform 1
  from public.conversation_members cm
  where cm.conversation_id = p_conversation_id
    and cm.user_id = current_user_id
  for update;
  if not found then raise exception 'Bạn không thuộc cuộc trò chuyện này.'; end if;

  -- Lấy thời gian sau khi đã giữ khóa conversation, không phải trước lúc chờ.
  read_time := clock_timestamp();

  update public.conversation_members
  set last_read_at = read_time
  where conversation_id = p_conversation_id
    and user_id = current_user_id;

  update public.notifications
  set read_at = read_time
  where user_id = current_user_id
    and entity_type = 'conversation'
    and entity_id = p_conversation_id
    and read_at is null;
end;
$$;

revoke all on function public.send_message(uuid, text)
  from public, anon, authenticated;
revoke all on function public.mark_conversation_read(uuid)
  from public, anon, authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

comment on function public.send_message(uuid, text) is
  'QuestReal migration 029: serialized send with locked current membership.';
comment on function public.mark_conversation_read(uuid) is
  'QuestReal migration 029: serialized read marker with locked current membership.';

notify pgrst, 'reload schema';
