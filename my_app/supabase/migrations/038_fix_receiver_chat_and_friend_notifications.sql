-- Migration 038: Fix receiver chat, RLS recursion prevention, and friendship notification integrity

-- ============================================================================
-- 1. CẬP NHẬT BẢNG NOTIFICATIONS: BỔ SUNG CỘT METADATA & CHO PHÉP TYPE BẠN BÈ
-- ============================================================================

alter table public.notifications
  add column if not exists metadata jsonb default '{}'::jsonb;

alter table public.notifications
  drop constraint if exists notifications_type_check,
  add constraint notifications_type_check check (type in (
    'team_request', 'team_request_approved', 'team_request_rejected',
    'team_kicked', 'direct_message', 'team_message', 'system',
    'friend_request', 'friend_accepted'
  ));

-- ============================================================================
-- 2. KHẮC PHỤC RLS RECURSION TRONG IS_CONVERSATION_MEMBER (PLPGSQL + ROW_SECURITY OFF)
-- ============================================================================

create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
set row_security = off
as $$
declare
  is_member boolean;
begin
  if auth.uid() is null or p_conversation_id is null then
    return false;
  end if;

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
  ) into is_member;

  return coalesce(is_member, false);
end;
$$;

revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;

-- ============================================================================
-- 3. CẬP NHẬT QUYỀN XEM HỒ SƠ: CHO PHÉP XEM HỒ SƠ CỦA BẠN CHAT & LỜI MỜI ĐANG CHỜ
-- ============================================================================

create or replace function public.can_current_user_view_profile(
  p_profile_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
set row_security = off
as $$
declare
  can_view boolean;
begin
  if auth.uid() is null or p_profile_id is null then
    return false;
  end if;

  select exists (
    select 1
    from public.profiles target_profile
    where target_profile.id = p_profile_id
      and (
        target_profile.id = auth.uid()
        or target_profile.profile_visibility = 'public'
        -- Đã là bạn bè
        or exists (
          select 1 from public.friendships f
          where f.status = 'accepted'
            and (
              (f.user_id = auth.uid() and f.friend_id = target_profile.id)
              or (f.friend_id = auth.uid() and f.user_id = target_profile.id)
            )
        )
        -- Có lời mời kết bạn đang chờ giữa 2 người (để người nhận xem được tên/avatar người gửi)
        or exists (
          select 1 from public.friendships f
          where f.status = 'pending'
            and (
              (f.user_id = auth.uid() and f.friend_id = target_profile.id)
              or (f.friend_id = auth.uid() and f.user_id = target_profile.id)
            )
        )
        -- Đang trong cùng phòng chat trực tiếp 1-1
        or exists (
          select 1
          from public.conversation_members cm1
          join public.conversation_members cm2
            on cm1.conversation_id = cm2.conversation_id
          join public.conversations c
            on c.id = cm1.conversation_id
          where cm1.user_id = auth.uid()
            and cm2.user_id = target_profile.id
            and c.type = 'direct'
        )
        -- Hồ sơ chia sẻ trong đội
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
  ) into can_view;

  return coalesce(can_view, false);
end;
$$;

revoke all on function public.can_current_user_view_profile(uuid) from public;
grant execute on function public.can_current_user_view_profile(uuid) to authenticated;

-- ============================================================================
-- 4. HỘP THƯ CHAT: SECURITY DEFINER + ROW_SECURITY OFF (TRÁNH LỖI PHÍA NGƯỜI NHẬN)
-- ============================================================================

drop function if exists public.fetch_chat_inbox();

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
language plpgsql
stable
security definer
set search_path = public, pg_temp
set row_security = off
as $$
begin
  return query
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
        and unread.created_at > coalesce(cm.last_read_at, '1970-01-01'::timestamptz)
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
end;
$$;

revoke all on function public.fetch_chat_inbox() from public;
grant execute on function public.fetch_chat_inbox() to authenticated;

-- ============================================================================
-- 5. CẬP NHẬT SEND & ACCEPT FRIEND REQUEST VỚI NOTIFICATION CHUẨN SCHEMA
-- ============================================================================

create or replace function public.send_friend_request(p_target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
set row_security = off
as $$
declare
  current_user_id uuid := auth.uid();
  target_allow_friends boolean;
  reverse_exists boolean;
  sender_name text;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  if current_user_id = p_target_user_id then
    raise exception 'Không thể gửi lời mời kết bạn cho chính mình.';
  end if;

  select allow_friend_requests into target_allow_friends
  from public.profiles
  where id = p_target_user_id;

  if target_allow_friends is false then
    raise exception 'Người dùng này đã tắt nhận lời mời kết bạn.';
  end if;

  select display_name into sender_name
  from public.profiles
  where id = current_user_id;

  -- Nếu người kia đã gửi lời mời cho mình -> Tự động chấp nhận
  select exists (
    select 1 from public.friendships
    where user_id = p_target_user_id and friend_id = current_user_id and status = 'pending'
  ) into reverse_exists;

  if reverse_exists then
    update public.friendships
    set status = 'accepted', updated_at = now()
    where user_id = p_target_user_id and friend_id = current_user_id;

    insert into public.friendships (user_id, friend_id, status)
    values (current_user_id, p_target_user_id, 'accepted')
    on conflict (user_id, friend_id) do update set status = 'accepted', updated_at = now();

    insert into public.notifications (
      user_id, actor_id, type, title, body, entity_type, entity_id, metadata
    ) values (
      p_target_user_id,
      current_user_id,
      'friend_accepted',
      'Kết bạn mới',
      coalesce(sender_name, 'Một người dùng') || ' đã trở thành bạn bè với bạn!',
      'friend',
      current_user_id,
      jsonb_build_object('friend_id', current_user_id)
    );

    return jsonb_build_object('status', 'accepted', 'message', 'Đã trở thành bạn bè!');
  end if;

  -- Gửi lời mời mới
  insert into public.friendships (user_id, friend_id, status)
  values (current_user_id, p_target_user_id, 'pending')
  on conflict (user_id, friend_id) do update set status = 'pending', updated_at = now();

  insert into public.notifications (
    user_id, actor_id, type, title, body, entity_type, entity_id, metadata
  ) values (
    p_target_user_id,
    current_user_id,
    'friend_request',
    'Lời mời kết bạn mới',
    coalesce(sender_name, 'Một người dùng') || ' đã gửi cho bạn một lời mời kết bạn.',
    'friend',
    current_user_id,
    jsonb_build_object('requester_id', current_user_id)
  );

  return jsonb_build_object('status', 'pending', 'message', 'Đã gửi lời mời kết bạn.');
end;
$$;

create or replace function public.accept_friend_request(p_requester_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
set row_security = off
as $$
declare
  current_user_id uuid := auth.uid();
  accepter_name text;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  update public.friendships
  set status = 'accepted', updated_at = now()
  where user_id = p_requester_id and friend_id = current_user_id;

  if not found then
    raise exception 'Không tìm thấy lời mời kết bạn.';
  end if;

  insert into public.friendships (user_id, friend_id, status)
  values (current_user_id, p_requester_id, 'accepted')
  on conflict (user_id, friend_id) do update set status = 'accepted', updated_at = now();

  select display_name into accepter_name
  from public.profiles
  where id = current_user_id;

  insert into public.notifications (
    user_id, actor_id, type, title, body, entity_type, entity_id, metadata
  ) values (
    p_requester_id,
    current_user_id,
    'friend_accepted',
    'Lời mời kết bạn được chấp nhận',
    coalesce(accepter_name, 'Một người dùng') || ' đã đồng ý lời mời kết bạn của bạn.',
    'friend',
    current_user_id,
    jsonb_build_object('friend_id', current_user_id)
  );

  return jsonb_build_object('status', 'accepted', 'message', 'Đã chấp nhận kết bạn.');
end;
$$;

grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;

notify pgrst, 'reload schema';
