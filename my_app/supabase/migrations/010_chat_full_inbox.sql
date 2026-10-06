-- Hộp thư hợp nhất: chat trực tiếp và chat đội.
-- Không xóa dữ liệu hội thoại/tin nhắn hiện có.

drop function if exists public.fetch_chat_inbox();

create function public.fetch_chat_inbox()
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
security definer
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

revoke all on function public.fetch_chat_inbox() from public;
grant execute on function public.fetch_chat_inbox() to authenticated;

notify pgrst, 'reload schema';
