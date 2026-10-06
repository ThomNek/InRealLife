-- Hộp thư, trạng thái đã đọc và chat nhóm theo đội.
-- Migration tăng dần: không xóa conversations/messages hiện có.

alter table public.conversation_members
  add column if not exists last_read_at timestamptz not null default now();

alter table public.conversations
  drop constraint if exists conversations_type_check;
alter table public.conversations
  add constraint conversations_type_check check (type in ('direct', 'team'));
alter table public.conversations
  add column if not exists team_id uuid references public.teams(id) on delete cascade;
alter table public.conversations
  add column if not exists title text;
create unique index if not exists conversations_team_id_key
  on public.conversations(team_id) where team_id is not null;

create or replace function public.fetch_chat_inbox()
returns table (
  conversation_id uuid,
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
    c.id,
    other_member.user_id,
    p.display_name,
    p.username,
    p.avatar_url,
    last_message.content,
    last_message.created_at,
    (
      select count(*)
      from public.messages unread
      where unread.conversation_id = c.id
        and unread.sender_id <> auth.uid()
        and unread.created_at > cm.last_read_at
    )::bigint
  from public.conversation_members cm
  join public.conversations c
    on c.id = cm.conversation_id and c.type = 'direct'
  join public.conversation_members other_member
    on other_member.conversation_id = c.id
   and other_member.user_id <> auth.uid()
  join public.profiles p on p.id = other_member.user_id
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
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

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

revoke all on function public.get_or_create_team_conversation(uuid) from public;
grant execute on function public.get_or_create_team_conversation(uuid) to authenticated;

-- Đồng bộ quyền chat khi duyệt, kick, rời hoặc quay lại đội.
create or replace function public.sync_team_chat_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_team_id uuid := coalesce(new.team_id, old.team_id);
  target_user_id uuid := coalesce(new.user_id, old.user_id);
  target_conversation_id uuid;
begin
  select id into target_conversation_id
  from public.conversations
  where team_id = target_team_id;

  if target_conversation_id is null then
    return coalesce(new, old);
  end if;

  if tg_op <> 'DELETE' and new.status = 'joined' then
    insert into public.conversation_members(conversation_id, user_id)
    values (target_conversation_id, target_user_id)
    on conflict do nothing;
  else
    delete from public.conversation_members
    where conversation_id = target_conversation_id
      and user_id = target_user_id;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists sync_team_chat_membership_trigger on public.team_members;
create trigger sync_team_chat_membership_trigger
after insert or update of status or delete on public.team_members
for each row execute function public.sync_team_chat_membership();

notify pgrst, 'reload schema';
