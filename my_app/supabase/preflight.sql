-- QuestReal production preflight (READ ONLY).
-- Có thể chạy trong Supabase SQL Editor trước khi triển khai migration.

-- 1. Bảng bắt buộc.
select required.object_name,
       to_regclass('public.' || required.object_name) is not null as installed
from (values
  ('profiles'), ('activities'), ('activity_members'), ('teams'),
  ('team_members'), ('team_requests'), ('conversations'),
  ('conversation_members'), ('messages'), ('notifications')
) as required(object_name)
order by required.object_name;

-- 2. RPC bắt buộc (false nghĩa là migration tương ứng chưa được áp dụng).
select required.signature,
       to_regprocedure('public.' || required.signature) is not null as installed
from (values
  ('create_activity_with_team(text,text,text,text,timestamp with time zone,integer,text,text)'),
  ('create_team(text,text,integer,text,text,timestamp with time zone)'),
  ('request_to_join_team(uuid,text)'),
  ('approve_team_request(uuid)'),
  ('reject_team_request(uuid)'),
  ('kick_team_member(uuid,uuid)'),
  ('cancel_team_request(uuid)'),
  ('leave_team(uuid)'),
  ('get_or_create_direct_conversation(uuid)'),
  ('get_or_create_team_conversation(uuid)'),
  ('fetch_chat_inbox()'),
  ('mark_conversation_read(uuid)'),
  ('send_message(uuid,text)'),
  ('mark_notification_read(uuid)'),
  ('mark_all_notifications_read()'),
  ('can_current_user_view_profile(uuid)')
) as required(signature)
order by required.signature;

-- 3. RLS phải bật trên mọi bảng client truy cập.
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'profiles', 'activities', 'activity_members', 'teams', 'team_members',
    'team_requests', 'conversations', 'conversation_members', 'messages',
    'notifications'
  )
order by c.relname;

-- 4. Các bảng phải phát sự kiện Realtime.
select required.table_name,
       published.tablename is not null as realtime_enabled
from (values
  ('messages'), ('notifications'), ('team_requests'), ('team_members'),
  ('activities'), ('teams')
) as required(table_name)
left join pg_publication_tables published
  on published.pubname = 'supabase_realtime'
 and published.schemaname = 'public'
 and published.tablename = required.table_name
order by required.table_name;

-- 5. Trigger quan trọng.
select required.trigger_name,
       trigger_info.tgname is not null as installed
from (values
  ('questreal_auth_profile_created'),
  ('sync_team_chat_membership_trigger'),
  ('notify_team_request_change_trigger'),
  ('notify_team_member_removed_trigger'),
  ('notify_new_message_trigger'),
  ('fill_message_sender_name_trigger'),
  ('set_profile_updated_at_trigger')
) as required(trigger_name)
left join pg_trigger trigger_info
  on trigger_info.tgname = required.trigger_name
 and not trigger_info.tgisinternal
order by required.trigger_name;

-- 6. Sau migration 021/027, authenticated chỉ được SELECT trực tiếp các bảng
-- nghiệp vụ, chat và thông báo. Các cột ghi phải đều false.
select table_name,
       has_table_privilege('authenticated', 'public.' || table_name, 'insert')
         as can_insert,
       has_table_privilege('authenticated', 'public.' || table_name, 'update')
         as can_update,
       has_table_privilege('authenticated', 'public.' || table_name, 'delete')
         as can_delete
from (values
  ('activities'), ('activity_members'), ('teams'),
  ('team_members'), ('team_requests'), ('conversations'),
  ('conversation_members'), ('messages'), ('notifications')
) as protected(table_name)
order by table_name;

-- 7. Danh sách policy hiện hữu để phát hiện policy lạ/quá rộng trước deploy.
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles', 'activities', 'activity_members', 'teams', 'team_members',
    'team_requests', 'conversations', 'conversation_members', 'messages',
    'notifications'
  )
order by tablename, policyname;

-- 8. RPC SECURITY DEFINER chỉ được mở cho người đã đăng nhập. Với mỗi dòng,
-- authenticated_can_execute phải true và anon_can_execute phải false.
select required.signature,
       has_function_privilege(
         'authenticated',
         'public.' || required.signature,
         'execute'
       ) as authenticated_can_execute,
       has_function_privilege(
         'anon',
         'public.' || required.signature,
         'execute'
       ) as anon_can_execute
from (values
  ('create_activity_with_team(text,text,text,text,timestamp with time zone,integer,text,text)'),
  ('create_team(text,text,integer,text,text,timestamp with time zone)'),
  ('request_to_join_team(uuid,text)'),
  ('approve_team_request(uuid)'),
  ('reject_team_request(uuid)'),
  ('kick_team_member(uuid,uuid)'),
  ('cancel_team_request(uuid)'),
  ('leave_team(uuid)'),
  ('get_or_create_direct_conversation(uuid)'),
  ('get_or_create_team_conversation(uuid)'),
  ('fetch_chat_inbox()'),
  ('mark_conversation_read(uuid)'),
  ('send_message(uuid,text)'),
  ('mark_notification_read(uuid)'),
  ('mark_all_notifications_read()'),
  ('can_current_user_view_profile(uuid)')
) as required(signature)
order by required.signature;

-- 9. Xác nhận bản hardening chat đội mới, không chỉ kiểm tra tên RPC tồn tại.
-- Cả hai cột phải true sau khi migration 023 được áp dụng.
select
  not coalesce(
    (
      select p.prosecdef
      from pg_proc p
      where p.oid = to_regprocedure('public.fetch_chat_inbox()')
    ),
    true
  ) as inbox_uses_caller_rls,
  coalesce(
    obj_description(
      to_regprocedure('public.is_conversation_member(uuid)'),
      'pg_proc'
    ) = 'QuestReal migration 023: team chat access requires current joined membership.',
    false
  ) as team_chat_membership_hardened;

-- 10. Sau migration 024, client không được tự chèn sender/timestamp message.
-- Cả hai cột phải true; gửi tin chỉ qua public.send_message().
select
  not has_table_privilege(
    'authenticated',
    'public.messages',
    'insert'
  ) as authenticated_direct_message_insert_blocked,
  not has_table_privilege(
    'anon',
    'public.messages',
    'insert'
  ) as anon_direct_message_insert_blocked;

-- 11. Sau migration 025, trạng thái đã đọc chỉ được cập nhật qua RPC dùng
-- thời gian server. Cột direct_notification_update_blocked phải true.
select
  not has_column_privilege(
    'authenticated',
    'public.notifications',
    'read_at',
    'update'
  ) as direct_notification_update_blocked;

-- 12. Marker xác nhận RPC yêu cầu đội đã dùng phiên bản transition chặt chẽ.
select
  coalesce(
    obj_description(
      to_regprocedure('public.request_to_join_team(uuid,text)'),
      'pg_proc'
    ) = 'QuestReal migration 026: normalized message and locked request creation.',
    false
  ) as team_request_input_hardened,
  coalesce(
    obj_description(
      to_regprocedure('public.reject_team_request(uuid)'),
      'pg_proc'
    ) = 'QuestReal migration 026: only pending requests can transition to rejected.',
    false
  ) as team_request_transition_hardened;

-- 13. Hồ sơ dùng timestamp server và client không được ghi trực tiếp cột này.
select
  coalesce(
    obj_description(
      to_regprocedure('public.set_profile_updated_at()'),
      'pg_proc'
    ) = 'QuestReal migration 028: profiles.updated_at is generated by the server.',
    false
  ) as profile_timestamp_trigger_hardened,
  not has_column_privilege(
    'authenticated',
    'public.profiles',
    'updated_at',
    'update'
  ) as profile_timestamp_update_blocked;

-- 14. Gửi tin và đánh dấu đọc phải dùng cùng khóa conversation.
select
  coalesce(
    obj_description(
      to_regprocedure('public.send_message(uuid,text)'),
      'pg_proc'
    ) = 'QuestReal migration 029: serialized send with locked current membership.',
    false
  ) as chat_send_serialized,
  coalesce(
    obj_description(
      to_regprocedure('public.mark_conversation_read(uuid)'),
      'pg_proc'
    ) = 'QuestReal migration 029: serialized read marker with locked current membership.',
    false
  ) as chat_read_serialized;

-- 15. Ứng dụng không cung cấp dữ liệu công khai trước đăng nhập. Mọi ô phải
-- false; authenticated vẫn đọc qua RLS và ghi các bảng nhạy cảm qua RPC.
select table_name,
       has_table_privilege('anon', 'public.' || table_name, 'select')
         as anon_can_select,
       has_table_privilege('anon', 'public.' || table_name, 'insert')
         as anon_can_insert,
       has_table_privilege('anon', 'public.' || table_name, 'update')
         as anon_can_update,
       has_table_privilege('anon', 'public.' || table_name, 'delete')
         as anon_can_delete
from (values
  ('profiles'), ('activities'), ('activity_members'), ('teams'),
  ('team_members'), ('team_requests'), ('conversations'),
  ('conversation_members'), ('messages'), ('notifications')
) as application_tables(table_name)
order by table_name;

-- 16. Hồ sơ là nguồn tên/avatar/EXP chuẩn của giao diện và phải có Realtime.
select exists (
  select 1
  from pg_publication_tables
  where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'profiles'
) as profiles_realtime_enabled;

-- 17. Sáu constraint chống request giả ghi nội dung hồ sơ không hợp lệ.
-- NOT VALID vẫn áp dụng cho mọi INSERT/UPDATE mới và không sửa dữ liệu cũ.
select count(*) = 6 as profile_input_constraints_installed
from pg_constraint
where conrelid = 'public.profiles'::regclass
  and conname in (
    'profiles_display_name_length_check',
    'profiles_username_format_check',
    'profiles_avatar_url_length_check',
    'profiles_bio_length_check',
    'profiles_city_length_check',
    'profiles_interests_shape_check'
  );

-- 18. Sáu constraint bảo vệ nội dung hoạt động, đội và lời nhắn yêu cầu.
select count(*) = 6 as activity_team_input_constraints_installed
from pg_constraint
where conname in (
    'activities_title_length_check',
    'activities_description_length_check',
    'activities_location_name_length_check',
    'teams_description_length_check',
    'teams_meeting_area_length_check',
    'team_requests_message_length_check'
  )
  and conrelid in (
    'public.activities'::regclass,
    'public.teams'::regclass,
    'public.team_requests'::regclass
  );
