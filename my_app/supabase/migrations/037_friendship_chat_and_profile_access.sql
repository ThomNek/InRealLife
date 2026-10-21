-- Migration 037: Friendship RPCs, Notifications, and Profile Viewing Integration

-- 1. Cập nhật hàm kiểm tra quyền xem hồ sơ bao gồm quan hệ bạn bè
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
        or exists (
          select 1 from public.friendships f
          where f.status = 'accepted'
            and (
              (f.user_id = auth.uid() and f.friend_id = target_profile.id)
              or (f.friend_id = auth.uid() and f.user_id = target_profile.id)
            )
        )
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

-- 2. Hàm gửi lời mời kết bạn an toàn
create or replace function public.send_friend_request(p_target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_allow_friends boolean;
  reverse_exists boolean;
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

  -- Kiểm tra nếu người kia đã gửi lời mời cho mình từ trước -> Tự động chấp nhận thành bạn bè
  select exists (
    select 1 from public.friendships
    where user_id = p_target_user_id and friend_id = current_user_id and status = 'pending'
  ) into reverse_exists;

  if reverse_exists then
    update public.friendships
    set status = 'accepted', updated_at = now()
    where user_id = p_target_user_id and friend_id = current_user_id;

    -- Thêm bản ghi chiều ngược lại để cả 2 bên đều tra cứu nhanh
    insert into public.friendships (user_id, friend_id, status)
    values (current_user_id, p_target_user_id, 'accepted')
    on conflict (user_id, friend_id) do update set status = 'accepted', updated_at = now();

    -- Tạo thông báo kết bạn thành công
    insert into public.notifications (user_id, title, body, type, metadata)
    values (
      p_target_user_id,
      'Kết bạn mới',
      'Đã trở thành bạn bè với bạn!',
      'friend_accepted',
      jsonb_build_object('friend_id', current_user_id)
    );

    return jsonb_build_object('status', 'accepted', 'message', 'Đã trở thành bạn bè!');
  end if;

  -- Gửi lời mời kết bạn mới
  insert into public.friendships (user_id, friend_id, status)
  values (current_user_id, p_target_user_id, 'pending')
  on conflict (user_id, friend_id) do update set status = 'pending', updated_at = now();

  -- Gửi thông báo đến người nhận
  insert into public.notifications (user_id, title, body, type, metadata)
  values (
    p_target_user_id,
    'Lời mời kết bạn mới',
    'Bạn nhận được một lời mời kết bạn mới.',
    'friend_request',
    jsonb_build_object('requester_id', current_user_id)
  );

  return jsonb_build_object('status', 'pending', 'message', 'Đã gửi lời mời kết bạn.');
end;
$$;

-- 3. Hàm chấp nhận lời mời kết bạn
create or replace function public.accept_friend_request(p_requester_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
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

  -- Đảm bảo có cả chiều ngược lại
  insert into public.friendships (user_id, friend_id, status)
  values (current_user_id, p_requester_id, 'accepted')
  on conflict (user_id, friend_id) do update set status = 'accepted', updated_at = now();

  -- Thông báo cho người gửi lời mời
  insert into public.notifications (user_id, title, body, type, metadata)
  values (
    p_requester_id,
    'Lời mời kết bạn được chấp nhận',
    'Đã đồng ý lời mời kết bạn của bạn.',
    'friend_accepted',
    jsonb_build_object('friend_id', current_user_id)
  );

  return jsonb_build_object('status', 'accepted', 'message', 'Đã chấp nhận kết bạn.');
end;
$$;

-- 4. Hàm từ chối, hủy lời mời hoặc hủy kết bạn
create or replace function public.remove_or_reject_friend(p_other_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;

  delete from public.friendships
  where (user_id = current_user_id and friend_id = p_other_user_id)
     or (user_id = p_other_user_id and friend_id = current_user_id);

  return jsonb_build_object('status', 'removed', 'message', 'Đã hủy quan hệ bạn bè/lời mời.');
end;
$$;

-- 5. Quyền gọi hàm cho người dùng đã đăng nhập
grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;
grant execute on function public.remove_or_reject_friend(uuid) to authenticated;

notify pgrst, 'reload schema';
