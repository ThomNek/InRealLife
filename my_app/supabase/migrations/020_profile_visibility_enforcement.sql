-- Dùng một phép kiểm tra duy nhất cho RLS và RPC để không có đường vòng đọc
-- hồ sơ private/shared qua hàm SECURITY DEFINER.

create or replace function public.can_current_user_view_profile(
  p_profile_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles target_profile
    where target_profile.id = p_profile_id
      and auth.uid() is not null
      and (
        target_profile.id = auth.uid()
        or target_profile.profile_visibility = 'public'
        or (
          target_profile.profile_visibility = 'shared'
          and (
            exists (
              select 1
              from public.team_members viewer
              join public.team_members target
                on target.team_id = viewer.team_id
               and target.user_id = target_profile.id
               and target.status = 'joined'
              where viewer.user_id = auth.uid()
                and viewer.status = 'joined'
            )
            or exists (
              select 1
              from public.team_requests request
              join public.teams team on team.id = request.team_id
              where request.status = 'pending'
                and (
                  (team.host_id = auth.uid()
                    and request.user_id = target_profile.id)
                  or (request.user_id = auth.uid()
                    and team.host_id = target_profile.id)
                )
            )
          )
        )
      )
  );
$$;

revoke all on function public.can_current_user_view_profile(uuid) from public;
grant execute on function public.can_current_user_view_profile(uuid)
  to authenticated;

drop policy if exists "Authenticated users can view allowed profiles"
  on public.profiles;
create policy "Authenticated users can view allowed profiles"
  on public.profiles for select to authenticated
  using (public.can_current_user_view_profile(id));

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

revoke all on function public.get_or_create_direct_conversation(uuid)
  from public;
grant execute on function public.get_or_create_direct_conversation(uuid)
  to authenticated;

-- SECURITY INVOKER khiến JOIN profiles/messages/conversation_members tuân theo
-- RLS của chính người đang gọi thay vì quyền của chủ sở hữu function.
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

revoke all on function public.fetch_chat_inbox() from public;
grant execute on function public.fetch_chat_inbox() to authenticated;

notify pgrst, 'reload schema';
