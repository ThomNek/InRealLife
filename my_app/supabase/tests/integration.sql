-- Runs after bootstrap.sql and all migrations, against a disposable database.
-- Every data mutation is rolled back at the end.

begin;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    raise exception 'profiles is missing from the Realtime publication.';
  end if;
end;
$$;

-- Không tài khoản nào được đọc/ghi trực tiếp dữ liệu ứng dụng dưới role anon.
do $$
declare
  table_name text;
  privilege_name text;
begin
  foreach table_name in array array[
    'profiles', 'activities', 'activity_members', 'teams', 'team_members',
    'team_requests', 'conversations', 'conversation_members', 'messages',
    'notifications'
  ]
  loop
    foreach privilege_name in array array['select', 'insert', 'update', 'delete']
    loop
      if has_table_privilege(
        'anon',
        'public.' || table_name,
        privilege_name
      ) then
        raise exception 'Anonymous role has % on public.%',
          privilege_name, table_name;
      end if;
    end loop;
  end loop;
end;
$$;

-- RPC nâng quyền phải yêu cầu JWT authenticated. PostgreSQL mặc định cấp
-- EXECUTE cho PUBLIC khi tạo function, nên assertion này chống hồi quy nếu một
-- migration mới quên REVOKE trước khi GRANT.
do $$
declare
  signature text;
begin
  foreach signature in array array[
    'create_activity_with_team(text,text,text,text,timestamp with time zone,integer,text,text)',
    'create_team(text,text,integer,text,text,timestamp with time zone)',
    'request_to_join_team(uuid,text)',
    'approve_team_request(uuid)',
    'reject_team_request(uuid)',
    'kick_team_member(uuid,uuid)',
    'cancel_team_request(uuid)',
    'leave_team(uuid)',
    'get_or_create_direct_conversation(uuid)',
    'get_or_create_team_conversation(uuid)',
    'fetch_chat_inbox()',
    'mark_conversation_read(uuid)',
    'send_message(uuid,text)',
    'mark_notification_read(uuid)',
    'mark_all_notifications_read()',
    'can_current_user_view_profile(uuid)'
  ]
  loop
    if has_function_privilege(
      'anon',
      'public.' || signature,
      'execute'
    ) then
      raise exception 'Anonymous role can execute privileged RPC: %', signature;
    end if;

    if not has_function_privilege(
      'authenticated',
      'public.' || signature,
      'execute'
    ) then
      raise exception 'Authenticated role cannot execute required RPC: %',
        signature;
    end if;
  end loop;
end;
$$;

do $$
begin
  if (
    select p.prosecdef
    from pg_proc p
    where p.oid = 'public.fetch_chat_inbox()'::regprocedure
  ) then
    raise exception 'fetch_chat_inbox must remain SECURITY INVOKER.';
  end if;

  if obj_description(
    'public.is_conversation_member(uuid)'::regprocedure,
    'pg_proc'
  ) <> 'QuestReal migration 023: team chat access requires current joined membership.' then
    raise exception 'Team chat membership hardening marker is missing.';
  end if;
end;
$$;

insert into auth.users(id, email, raw_user_meta_data) values
  ('10000000-0000-0000-0000-000000000001', 'host@example.test',
   '{"display_name":"Host Test"}'::jsonb),
  ('10000000-0000-0000-0000-000000000002', 'member@example.test',
   '{"display_name":"Member Test"}'::jsonb),
  ('10000000-0000-0000-0000-000000000003', 'outsider@example.test',
   '{"display_name":"Outsider Test"}'::jsonb);

do $$
begin
  if (select count(*) from public.profiles
      where id in (
        '10000000-0000-0000-0000-000000000001'::uuid,
        '10000000-0000-0000-0000-000000000002'::uuid,
        '10000000-0000-0000-0000-000000000003'::uuid
      )) <> 3 then
    raise exception 'Auth trigger did not create all profiles.';
  end if;
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

select
  (created ->> 'activity_id')::uuid as activity_id,
  (created ->> 'team_id')::uuid as team_id
from (
  select public.create_activity_with_team(
    'Migration Integration Test',
    'Temporary activity',
    'treasure_hunt',
    'Public test location',
    now() + interval '1 day',
    4,
    'intermediate',
    'Mang nước uống; chỉ gặp tại địa điểm công cộng.'
  ) as created
) result
\gset

select set_config('questreal_test.team_id', :'team_id', true);
select set_config('questreal_test.activity_id', :'activity_id', true);

do $$
begin
  if not exists (
    select 1 from public.activities a
    where a.id = current_setting('questreal_test.activity_id')::uuid
      and a.skill_level = 'intermediate'
      and a.preparation_notes =
        'Mang nước uống; chỉ gặp tại địa điểm công cộng.'
  ) then
    raise exception 'Activity requirements were not persisted.';
  end if;
end;
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

select public.request_to_join_team(:'team_id'::uuid, repeat('m', 700))
  as request_id
\gset

select set_config('questreal_test.request_id', :'request_id', true);

do $$
begin
  if (
    select char_length(message)
    from public.team_requests
    where id = current_setting('questreal_test.request_id')::uuid
  ) <> 500 then
    raise exception 'Team request message was not normalized to 500 chars.';
  end if;
end;
$$;

-- Người dùng có thể chọn chỉ hiển thị hồ sơ cho người có quan hệ hoạt động.
update public.profiles
set profile_visibility = 'shared'
where id = auth.uid();

-- Request tự chế vẫn phải bị PostgreSQL chặn, dù bỏ qua validator Flutter.
do $$
declare
  rejected boolean;
begin
  rejected := false;
  begin
    update public.profiles
    set display_name = repeat('x', 81)
    where id = auth.uid();
  exception when check_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'Oversized profile display name was accepted.';
  end if;

  rejected := false;
  begin
    update public.profiles
    set username = 'INVALID USERNAME'
    where id = auth.uid();
  exception when check_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'Invalid profile username was accepted.';
  end if;

  rejected := false;
  begin
    update public.profiles
    set bio = repeat('b', 501)
    where id = auth.uid();
  exception when check_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'Oversized profile bio was accepted.';
  end if;
end;
$$;

-- RPC tạo hoạt động cũng phải chịu constraint server, không chỉ validator UI.
do $$
declare
  rejected boolean := false;
begin
  begin
    perform public.create_activity_with_team(
      repeat('x', 121),
      'Mô tả hợp lệ',
      'coffee',
      'Địa điểm công cộng',
      now() + interval '2 days',
      4,
      'all',
      ''
    );
  exception when check_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'Oversized activity title was accepted.';
  end if;
end;
$$;

-- Client không được giả thời gian cập nhật hồ sơ.
do $$
declare
  changed_rows integer;
begin
  begin
    update public.profiles
    set updated_at = now() + interval '10 years'
    where id = auth.uid();
    get diagnostics changed_rows = row_count;
  exception
    when insufficient_privilege then changed_rows := 0;
  end;

  if changed_rows <> 0 then
    raise exception 'Profile updated_at was directly writable.';
  end if;
end;
$$;

update public.profiles
set bio = 'Server timestamp integration test'
where id = auth.uid();

do $$
begin
  if not exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.bio = 'Server timestamp integration test'
      and p.updated_at <= clock_timestamp()
      and p.updated_at > clock_timestamp() - interval '1 minute'
  ) then
    raise exception 'Profile update trigger did not use server time.';
  end if;
end;
$$;

-- A client must not be able to forge progression/verification fields.
do $$
begin
  begin
    update public.profiles
    set exp = 999999, level = 99, is_verified = true
    where id = auth.uid();
    raise exception 'Protected profile columns were writable.';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

-- A requester must not be able to self-approve through a direct table update.
do $$
declare
  changed_rows integer;
begin
  begin
    update public.team_requests
    set status = 'approved'
    where id = current_setting('questreal_test.request_id')::uuid;
    get diagnostics changed_rows = row_count;
  exception
    when insufficient_privilege then changed_rows := 0;
  end;
  if changed_rows <> 0 then
    raise exception 'Requester could self-approve.';
  end if;
end;
$$;

-- Không được bỏ qua RPC để tạo đội mồ côi hoặc tự chèn membership joined.
do $$
begin
  begin
    insert into public.teams(host_id, name)
    values (auth.uid(), 'Orphan forged team');
    raise exception 'Client could insert a team directly.';
  exception
    when insufficient_privilege then null;
  end;

  begin
    insert into public.team_members(team_id, user_id, role, status)
    values (
      current_setting('questreal_test.team_id')::uuid,
      auth.uid(),
      'member',
      'joined'
    );
    raise exception 'Client could insert joined membership directly.';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

select public.get_or_create_direct_conversation(
  '10000000-0000-0000-0000-000000000001'::uuid
) as direct_conversation_id
\gset

select set_config(
  'questreal_test.direct_conversation_id',
  :'direct_conversation_id',
  true
);

do $$
begin
  begin
    insert into public.messages(conversation_id, sender_id, content, created_at)
    values (
      current_setting('questreal_test.direct_conversation_id')::uuid,
      auth.uid(),
      'Tin giả timestamp',
      clock_timestamp() + interval '10 years'
    );
    raise exception 'Client could insert a message directly.';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.send_message(
      current_setting('questreal_test.direct_conversation_id')::uuid,
      '   '
    );
    raise exception 'Empty message was accepted.';
  exception
    when raise_exception then
      if sqlerrm <> 'Tin nhắn không được để trống.' then raise; end if;
  end;

  begin
    perform public.send_message(
      current_setting('questreal_test.direct_conversation_id')::uuid,
      null
    );
    raise exception 'Null message was accepted.';
  exception
    when raise_exception then
      if sqlerrm <> 'Tin nhắn không được để trống.' then raise; end if;
  end;

  begin
    perform public.send_message(
      current_setting('questreal_test.direct_conversation_id')::uuid,
      repeat('x', 2001)
    );
    raise exception 'Oversized message was accepted.';
  exception
    when raise_exception then
      if sqlerrm <> 'Tin nhắn không được vượt quá 2.000 ký tự.' then raise; end if;
  end;
end;
$$;

select public.send_message(
  :'direct_conversation_id'::uuid,
  'Tin nhắn trực tiếp integration test'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000003',
  true
);

select public.request_to_join_team(
  current_setting('questreal_test.team_id')::uuid,
  null
) as outsider_request_id
\gset

select set_config(
  'questreal_test.outsider_request_id',
  :'outsider_request_id',
  true
);

do $$
begin
  if not exists (
    select 1
    from public.team_requests tr
    where tr.id = current_setting('questreal_test.outsider_request_id')::uuid
      and tr.user_id = auth.uid()
      and tr.status = 'pending'
      and tr.message = ''
  ) then
    raise exception 'Null team request message was not normalized.';
  end if;
end;
$$;

do $$
declare
  visible_messages integer;
  visible_shared_profile integer;
begin
  select count(*) into visible_shared_profile
  from public.profiles p
  where p.id = '10000000-0000-0000-0000-000000000002'::uuid;
  if visible_shared_profile <> 0 then
    raise exception 'Unrelated user can view a shared-only profile.';
  end if;

  begin
    perform public.get_or_create_direct_conversation(
      '10000000-0000-0000-0000-000000000002'::uuid
    );
    raise exception 'Unrelated user could open a direct chat to shared profile.';
  exception
    when raise_exception then
      if sqlerrm <> 'Không tìm thấy người dùng hoặc hồ sơ không cho phép liên hệ.' then
        raise;
      end if;
  end;

  select count(*) into visible_messages
  from public.messages m
  where m.conversation_id =
    current_setting('questreal_test.direct_conversation_id')::uuid;
  if visible_messages <> 0 then
    raise exception 'Outsider can read another direct conversation.';
  end if;

  begin
    insert into public.messages(conversation_id, sender_id, content)
    values (
      current_setting('questreal_test.direct_conversation_id')::uuid,
      auth.uid(),
      'Tin giả từ outsider'
    );
    raise exception 'Outsider could send to another direct conversation.';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

select public.reject_team_request(
  current_setting('questreal_test.outsider_request_id')::uuid
);

do $$
begin
  begin
    perform public.reject_team_request(
      current_setting('questreal_test.outsider_request_id')::uuid
    );
    raise exception 'A rejected request was rejected twice.';
  exception
    when raise_exception then
      if sqlerrm <> 'Yêu cầu này không còn ở trạng thái chờ duyệt.' then
        raise;
      end if;
  end;
end;
$$;

do $$
declare
  same_conversation_id uuid;
  direct_unread bigint;
  visible_requester integer;
begin
  select count(*) into visible_requester
  from public.profiles p
  where p.id = '10000000-0000-0000-0000-000000000002'::uuid;
  if visible_requester <> 1 then
    raise exception 'Host cannot view profile of a pending requester.';
  end if;

  select public.get_or_create_direct_conversation(
    '10000000-0000-0000-0000-000000000002'::uuid
  ) into same_conversation_id;

  if same_conversation_id <>
      current_setting('questreal_test.direct_conversation_id')::uuid then
    raise exception 'Direct conversation was duplicated.';
  end if;

  select inbox.unread_count into direct_unread
  from public.fetch_chat_inbox() inbox
  where inbox.conversation_id = same_conversation_id;

  if direct_unread <> 1 then
    raise exception 'Expected one unread direct message, got %.', direct_unread;
  end if;

  if not exists (
    select 1 from public.notifications n
    where n.user_id = auth.uid()
      and n.type = 'direct_message'
      and n.entity_id = same_conversation_id
      and n.read_at is null
  ) then
    raise exception 'Direct message did not create a notification.';
  end if;

  if not exists (
    select 1 from public.notifications n
    where n.user_id = auth.uid()
      and n.type = 'team_request'
      and n.entity_id = current_setting('questreal_test.team_id')::uuid
  ) then
    raise exception 'Join request did not notify the host.';
  end if;
end;
$$;

-- Chỉ RPC được phép sửa trạng thái đã đọc; client không được tự đặt timestamp.
do $$
declare
  changed_rows integer;
begin
  begin
    update public.notifications
    set read_at = now() + interval '10 years'
    where user_id = auth.uid();
    get diagnostics changed_rows = row_count;
  exception
    when insufficient_privilege then changed_rows := 0;
  end;

  if changed_rows <> 0 then
    raise exception 'Notification read timestamp was directly writable.';
  end if;
end;
$$;

select public.mark_notification_read(
  (
    select n.id
    from public.notifications n
    where n.user_id = auth.uid()
      and n.type = 'direct_message'
    limit 1
  )
);

do $$
begin
  if exists (
    select 1 from public.notifications n
    where n.user_id = auth.uid()
      and n.type = 'direct_message'
      and n.read_at is null
  ) then
    raise exception 'mark_notification_read did not update the notification.';
  end if;
end;
$$;

select public.mark_all_notifications_read();

do $$
begin
  if exists (
    select 1 from public.notifications n
    where n.user_id = auth.uid()
      and n.read_at is null
  ) then
    raise exception 'mark_all_notifications_read left unread notifications.';
  end if;
end;
$$;

select public.mark_conversation_read(
  current_setting('questreal_test.direct_conversation_id')::uuid
);

do $$
declare
  direct_unread bigint;
begin
  select inbox.unread_count into direct_unread
  from public.fetch_chat_inbox() inbox
  where inbox.conversation_id =
    current_setting('questreal_test.direct_conversation_id')::uuid;
  if direct_unread <> 0 then
    raise exception 'Direct unread count was not cleared.';
  end if;
end;
$$;

-- Quyền quản trị đội phải được kiểm tra trong RPC, không dựa vào việc giao
-- diện có ẩn nút hay không.
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000003',
  true
);

do $$
begin
  begin
    perform public.approve_team_request(
      current_setting('questreal_test.request_id')::uuid
    );
    raise exception 'Non-host approved a team request.';
  exception
    when raise_exception then
      if sqlerrm <> 'Chỉ chủ đội được duyệt.' then
        raise;
      end if;
  end;

  begin
    perform public.kick_team_member(
      current_setting('questreal_test.team_id')::uuid,
      '10000000-0000-0000-0000-000000000001'::uuid
    );
    raise exception 'Non-host kicked a team member.';
  exception
    when raise_exception then
      if sqlerrm <> 'Chỉ chủ đội được kích thành viên.' then
        raise;
      end if;
  end;
end;
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

do $$
begin
  begin
    perform public.kick_team_member(
      current_setting('questreal_test.team_id')::uuid,
      auth.uid()
    );
    raise exception 'Host kicked itself.';
  exception
    when raise_exception then
      if sqlerrm <> 'Không thể kích chủ đội.' then
        raise;
      end if;
  end;
end;
$$;

select public.approve_team_request(:'request_id'::uuid);

do $$
declare
  joined_count integer;
begin
  if not exists (
    select 1 from public.team_members tm
    where tm.team_id = current_setting('questreal_test.team_id')::uuid
      and tm.user_id = '10000000-0000-0000-0000-000000000002'::uuid
      and tm.status = 'joined'
  ) then
    raise exception 'Approved requester was not added as a joined member.';
  end if;

  select count(*) into joined_count
  from public.team_members tm
  where tm.team_id = current_setting('questreal_test.team_id')::uuid
    and tm.status = 'joined';
  if joined_count <> 2 then
    raise exception 'Expected 2 joined members after approval, got %.',
      joined_count;
  end if;
end;
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

select public.get_or_create_team_conversation(:'team_id'::uuid)
  as conversation_id
\gset

select set_config(
  'questreal_test.conversation_id',
  :'conversation_id',
  true
);

select public.send_message(
  :'conversation_id'::uuid,
  'Tin nhắn integration test'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

do $$
begin
  if not exists (
    select 1 from public.notifications n
    where n.user_id = auth.uid()
      and n.type = 'team_message'
      and n.entity_id = current_setting('questreal_test.conversation_id')::uuid
      and n.read_at is null
  ) then
    raise exception 'Team message did not create an unread notification.';
  end if;
end;
$$;

select public.mark_conversation_read(:'conversation_id'::uuid);

do $$
begin
  if exists (
    select 1 from public.notifications n
    where n.user_id = auth.uid()
      and n.entity_id = current_setting('questreal_test.conversation_id')::uuid
      and n.read_at is null
  ) then
    raise exception 'Opening conversation did not mark notification read.';
  end if;
end;
$$;

select public.kick_team_member(
  :'team_id'::uuid,
  '10000000-0000-0000-0000-000000000002'::uuid
);

do $$
declare
  joined_count integer;
begin
  select count(*) into joined_count
  from public.team_members tm
  where tm.team_id = current_setting('questreal_test.team_id')::uuid
    and tm.status = 'joined';
  if joined_count <> 1 then
    raise exception 'Expected 1 joined member after kick, got %.', joined_count;
  end if;
end;
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

do $$
declare
  visible_messages integer;
begin
  select count(*) into visible_messages
  from public.messages m
  where m.conversation_id =
    current_setting('questreal_test.conversation_id')::uuid;
  if visible_messages <> 0 then
    raise exception 'Kicked member can still read team messages.';
  end if;
end;
$$;

-- Mô phỏng dữ liệu cache conversation_members cũ bị lệch sau khi kick.
-- Quyền chat đội vẫn phải bị chặn bởi team_members.status hiện hành.
reset role;
insert into public.conversation_members(conversation_id, user_id)
values (
  current_setting('questreal_test.conversation_id')::uuid,
  '10000000-0000-0000-0000-000000000002'::uuid
)
on conflict do nothing;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

do $$
declare
  visible_messages integer;
  visible_inbox_rows integer;
begin
  select count(*) into visible_messages
  from public.messages m
  where m.conversation_id =
    current_setting('questreal_test.conversation_id')::uuid;
  if visible_messages <> 0 then
    raise exception 'Stale conversation membership restored team message access.';
  end if;

  select count(*) into visible_inbox_rows
  from public.fetch_chat_inbox() inbox
  where inbox.conversation_id =
    current_setting('questreal_test.conversation_id')::uuid;
  if visible_inbox_rows <> 0 then
    raise exception 'Stale conversation membership leaked a team inbox row.';
  end if;

  begin
    perform public.mark_conversation_read(
      current_setting('questreal_test.conversation_id')::uuid
    );
    raise exception 'Stale conversation member could mark team chat read.';
  exception
    when raise_exception then
      if sqlerrm <> 'Bạn không thuộc cuộc trò chuyện này.' then
        raise;
      end if;
  end;
end;
$$;

select public.request_to_join_team(
  current_setting('questreal_test.team_id')::uuid,
  'Yêu cầu sẽ hủy'
) as cancelled_request_id
\gset

select public.cancel_team_request(
  current_setting('questreal_test.team_id')::uuid
);

do $$
begin
  if not exists (
    select 1 from public.team_requests tr
    where tr.team_id = current_setting('questreal_test.team_id')::uuid
      and tr.user_id = auth.uid()
      and tr.status = 'cancelled'
  ) then
    raise exception 'Join request was not cancelled.';
  end if;
end;
$$;

select public.request_to_join_team(
  current_setting('questreal_test.team_id')::uuid,
  'Xin tham gia lại'
) as second_request_id
\gset

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);
select public.approve_team_request(:'second_request_id'::uuid);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);
select public.leave_team(current_setting('questreal_test.team_id')::uuid);

do $$
begin
  if not exists (
    select 1 from public.team_members tm
    where tm.team_id = current_setting('questreal_test.team_id')::uuid
      and tm.user_id = auth.uid()
      and tm.status = 'left'
  ) then
    raise exception 'Member status was not changed to left.';
  end if;

  if exists (
    select 1 from public.messages m
    where m.conversation_id =
      current_setting('questreal_test.conversation_id')::uuid
  ) then
    raise exception 'Member who left can still read team messages.';
  end if;
end;
$$;

reset role;
rollback;
