-- Phòng chat đội phải kiểm tra trạng thái team_members tại thời điểm truy cập.
-- Trigger đồng bộ conversation_members vẫn được giữ để tối ưu, nhưng bảng cache
-- này không còn là nguồn quyết định quyền duy nhất nếu dữ liệu cũ bị lệch.

create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.conversation_members cm
    join public.conversations c on c.id = cm.conversation_id
    where cm.conversation_id = p_conversation_id
      and cm.user_id = auth.uid()
      and (
        c.type = 'direct'
        or (
          c.type = 'team'
          and c.team_id is not null
          and exists (
            select 1
            from public.team_members tm
            where tm.team_id = c.team_id
              and tm.user_id = auth.uid()
              and tm.status = 'joined'
          )
        )
      )
  );
$$;

revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;
comment on function public.is_conversation_member(uuid) is
  'QuestReal migration 023: team chat access requires current joined membership.';

-- Giữ SECURITY INVOKER từ migration 020 để JOIN profiles/messages tiếp tục
-- tuân theo RLS. Điều kiện bên dưới bổ sung kiểm tra membership đội hiện hành.
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
    and (
      c.type = 'direct'
      or exists (
        select 1
        from public.team_members tm
        where tm.team_id = c.team_id
          and tm.user_id = auth.uid()
          and tm.status = 'joined'
      )
    )
  order by last_message.created_at desc nulls last, c.created_at desc;
$$;

revoke all on function public.fetch_chat_inbox() from public;
grant execute on function public.fetch_chat_inbox() to authenticated;
comment on function public.fetch_chat_inbox() is
  'QuestReal migration 023: RLS-aware inbox with current team membership enforcement.';

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  read_time timestamptz := clock_timestamp();
begin
  if not public.is_conversation_member(p_conversation_id) then
    raise exception 'Bạn không thuộc cuộc trò chuyện này.';
  end if;

  update public.conversation_members
  set last_read_at = read_time
  where conversation_id = p_conversation_id
    and user_id = auth.uid();

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

-- Không gửi thông báo chat đội cho một conversation_members cũ nếu trigger
-- đồng bộ từng bị gián đoạn. Chat trực tiếp vẫn dùng membership của phòng.
create or replace function public.notify_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_type text;
  conversation_team_id uuid;
  sender_name text;
begin
  select c.type, c.team_id into conversation_type, conversation_team_id
  from public.conversations c where c.id = new.conversation_id;
  select p.display_name into sender_name
  from public.profiles p where p.id = new.sender_id;

  insert into public.notifications(
    user_id, actor_id, type, title, body, entity_type, entity_id
  )
  select
    cm.user_id,
    new.sender_id,
    case when conversation_type = 'team'
      then 'team_message' else 'direct_message' end,
    coalesce(sender_name, 'Một người dùng') || ' đã gửi tin nhắn',
    left(new.content, 160),
    'conversation',
    new.conversation_id
  from public.conversation_members cm
  where cm.conversation_id = new.conversation_id
    and cm.user_id <> new.sender_id
    and (
      conversation_type = 'direct'
      or exists (
        select 1
        from public.team_members tm
        where tm.team_id = conversation_team_id
          and tm.user_id = cm.user_id
          and tm.status = 'joined'
      )
    );

  return new;
end;
$$;

notify pgrst, 'reload schema';
