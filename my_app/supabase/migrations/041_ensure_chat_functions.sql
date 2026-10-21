-- Migration 041: Ensure chat functions are properly registered and granted in PostgREST schema cache
-- Khắc phục lỗi PGRST202: "Could not find the function public.send_message(p_content, p_conversation_id) in the schema cache"

-- ─── 1. send_message ────────────────────────────────────────────────────────
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

  -- Khóa phòng trò chuyện để tránh race condition
  select c.type, c.team_id
  into conversation_type, conversation_team_id
  from public.conversations c
  where c.id = p_conversation_id
  for update;

  if not found then
    raise exception 'Không tìm thấy cuộc trò chuyện.';
  end if;

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
  if not found then
    raise exception 'Bạn không thuộc cuộc trò chuyện này.';
  end if;

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

revoke all on function public.send_message(uuid, text) from public, anon, authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;

-- ─── 2. mark_conversation_read ──────────────────────────────────────────────
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

  if not found then
    raise exception 'Không tìm thấy cuộc trò chuyện.';
  end if;

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
  if not found then
    raise exception 'Bạn không thuộc cuộc trò chuyện này.';
  end if;

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

revoke all on function public.mark_conversation_read(uuid) from public, anon, authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- ─── 3. get_or_create_direct_conversation ───────────────────────────────────
create or replace function public.get_or_create_direct_conversation(
  p_other_user_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  conversation_key text;
  conversation_id uuid;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;
  if p_other_user_id = current_user_id then
    raise exception 'Không thể tự nhắn tin cho chính mình.';
  end if;
  if not public.can_current_user_view_profile(p_other_user_id) then
    raise exception 'Không tìm thấy người dùng hoặc hồ sơ không cho phép liên hệ.';
  end if;

  conversation_key := least(current_user_id::text, p_other_user_id::text)
    || ':' || greatest(current_user_id::text, p_other_user_id::text);

  insert into public.conversations(type, direct_key)
  values ('direct', conversation_key)
  on conflict (direct_key) do update set direct_key = excluded.direct_key
  returning id into conversation_id;

  insert into public.conversation_members(conversation_id, user_id)
  values
    (conversation_id, current_user_id),
    (conversation_id, p_other_user_id)
  on conflict do nothing;

  return conversation_id;
end;
$$;

revoke all on function public.get_or_create_direct_conversation(uuid) from public, anon, authenticated;
grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;

-- ─── 4. get_or_create_team_conversation ─────────────────────────────────────
create or replace function public.get_or_create_team_conversation(p_team_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  result_id uuid;
  team_name text;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  if not exists (
    select 1 from public.team_members tm
    where tm.team_id = p_team_id
      and tm.user_id = current_user_id
      and tm.status = 'joined'
  ) then
    raise exception 'Chỉ thành viên đang tham gia mới được vào chat đội.';
  end if;

  select t.name into team_name from public.teams t where t.id = p_team_id;
  if team_name is null then raise exception 'Không tìm thấy đội.'; end if;

  insert into public.conversations(type, team_id, title)
  values ('team', p_team_id, team_name)
  on conflict (team_id) where team_id is not null
  do update set title = excluded.title
  returning id into result_id;

  insert into public.conversation_members(conversation_id, user_id)
  select result_id, tm.user_id
  from public.team_members tm
  where tm.team_id = p_team_id and tm.status = 'joined'
  on conflict do nothing;

  return result_id;
end;
$$;

revoke all on function public.get_or_create_team_conversation(uuid) from public, anon, authenticated;
grant execute on function public.get_or_create_team_conversation(uuid) to authenticated;

-- ─── 5. fetch_chat_inbox ────────────────────────────────────────────────────
create or replace function public.fetch_chat_inbox()
returns table (
  conversation_id uuid,
  conversation_type text,
  team_id uuid,
  other_user_id uuid,
  display_name text,
  username text,
  avatar_url text,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    c.id as conversation_id,
    c.type as conversation_type,
    c.team_id,
    case when c.type = 'direct' then other_member.user_id end as other_user_id,
    case
      when c.type = 'team' then coalesce(c.title, t.name, 'Chat đội')
      else coalesce(p.display_name, 'Người dùng')
    end as display_name,
    case when c.type = 'direct' then p.username end as username,
    case when c.type = 'direct' then p.avatar_url end as avatar_url,
    last_message.content as last_message,
    last_message.created_at as last_message_at,
    (
      select count(*)
      from public.messages unread
      where unread.conversation_id = c.id
        and unread.sender_id <> auth.uid()
        and unread.created_at > cm.last_read_at
    )::bigint as unread_count
  from public.conversation_members cm
  join public.conversations c on c.id = cm.conversation_id
  left join public.conversation_members other_member
    on c.type = 'direct'
   and other_member.conversation_id = c.id
   and other_member.user_id <> auth.uid()
  left join public.profiles p on p.id = other_member.user_id
  left join public.teams t on t.id = c.team_id
  left join lateral (
    select m.content, m.created_at
    from public.messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) last_message on true
  where cm.user_id = auth.uid()
  order by last_message.created_at desc nulls last, c.created_at desc;
$$;

revoke all on function public.fetch_chat_inbox() from public, anon, authenticated;
grant execute on function public.fetch_chat_inbox() to authenticated;

-- ─── 6. Reload schema cache ─────────────────────────────────────────────────
notify pgrst, 'reload schema';
