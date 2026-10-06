-- Thông báo trong ứng dụng. Không chứa push notification ra ngoài thiết bị.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  type text not null check (type in (
    'team_request', 'team_request_approved', 'team_request_rejected',
    'team_kicked', 'direct_message', 'team_message', 'system'
  )),
  title text not null,
  body text,
  entity_type text,
  entity_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications(user_id, created_at desc);
create index if not exists notifications_user_unread_idx
  on public.notifications(user_id, created_at desc) where read_at is null;

alter table public.notifications enable row level security;

drop policy if exists "users can view own notifications" on public.notifications;
create policy "users can view own notifications"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "users can mark own notifications read" on public.notifications;
create policy "users can mark own notifications read"
  on public.notifications for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Khi mở một cuộc trò chuyện, đồng thời đánh dấu các thông báo của phòng đó.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversation_members
  set last_read_at = now()
  where conversation_id = p_conversation_id
    and user_id = auth.uid();

  if not found then
    raise exception 'Bạn không thuộc cuộc trò chuyện này.';
  end if;

  update public.notifications
  set read_at = now()
  where user_id = auth.uid()
    and entity_type = 'conversation'
    and entity_id = p_conversation_id
    and read_at is null;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- Không có INSERT policy cho client. Thông báo chỉ được tạo bởi trigger tin cậy.
create or replace function public.notify_team_request_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_host_id uuid;
  team_name text;
  actor_name text;
begin
  select t.host_id, t.name into target_host_id, team_name
  from public.teams t where t.id = new.team_id;
  select p.display_name into actor_name
  from public.profiles p where p.id = new.user_id;

  if tg_op = 'INSERT' and new.status = 'pending' then
    insert into public.notifications(
      user_id, actor_id, type, title, body, entity_type, entity_id
    ) values (
      target_host_id, new.user_id, 'team_request',
      coalesce(actor_name, 'Một người dùng') || ' muốn tham gia đội',
      coalesce(team_name, 'Đội của bạn'), 'team', new.team_id
    );
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status
    and new.status in ('approved', 'rejected') then
    insert into public.notifications(
      user_id, actor_id, type, title, body, entity_type, entity_id
    ) values (
      new.user_id, target_host_id,
      case when new.status = 'approved'
        then 'team_request_approved' else 'team_request_rejected' end,
      case when new.status = 'approved'
        then 'Yêu cầu tham gia đã được duyệt'
        else 'Yêu cầu tham gia chưa được chấp nhận' end,
      coalesce(team_name, 'Đội'), 'team', new.team_id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_team_request_change_trigger on public.team_requests;
create trigger notify_team_request_change_trigger
after insert or update of status on public.team_requests
for each row execute function public.notify_team_request_change();

create or replace function public.notify_team_member_removed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  team_name text;
begin
  if old.status = 'joined' and new.status = 'left'
    and auth.uid() is distinct from new.user_id then
    select t.name into team_name from public.teams t where t.id = new.team_id;
    insert into public.notifications(
      user_id, actor_id, type, title, body, entity_type, entity_id
    ) values (
      new.user_id, auth.uid(), 'team_kicked', 'Bạn đã được đưa khỏi đội',
      coalesce(team_name, 'Đội'), 'team', new.team_id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_team_member_removed_trigger on public.team_members;
create trigger notify_team_member_removed_trigger
after update of status on public.team_members
for each row execute function public.notify_team_member_removed();

create or replace function public.notify_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_type text;
  sender_name text;
begin
  select c.type into conversation_type
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
    and cm.user_id <> new.sender_id;

  return new;
end;
$$;

drop trigger if exists notify_new_message_trigger on public.messages;
create trigger notify_new_message_trigger
after insert on public.messages
for each row execute function public.notify_new_message();

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

notify pgrst, 'reload schema';
