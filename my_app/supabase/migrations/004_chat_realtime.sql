-- Chat trực tiếp 1-1. Chạy toàn bộ file này trong Supabase SQL Editor.

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'direct' check (type in ('direct')),
  direct_key text unique,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(trim(content)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists conversation_members_user_idx
  on public.conversation_members(user_id);
create index if not exists messages_conversation_created_idx
  on public.messages(conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- SECURITY DEFINER tránh policy conversation_members tự gọi lại chính nó.
create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = p_conversation_id
      and cm.user_id = auth.uid()
  );
$$;

revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;

drop policy if exists "members can view conversations" on public.conversations;
create policy "members can view conversations"
  on public.conversations for select to authenticated
  using (public.is_conversation_member(id));

drop policy if exists "members can view conversation members" on public.conversation_members;
create policy "members can view conversation members"
  on public.conversation_members for select to authenticated
  using (public.is_conversation_member(conversation_id));

drop policy if exists "members can view messages" on public.messages;
create policy "members can view messages"
  on public.messages for select to authenticated
  using (public.is_conversation_member(conversation_id));

drop policy if exists "members can send own messages" on public.messages;
create policy "members can send own messages"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_member(conversation_id)
  );

-- Tìm hoặc tạo duy nhất một phòng giữa hai user. Client không được tự ý
-- thêm thành viên vào phòng của người khác.
create or replace function public.get_or_create_direct_conversation(p_other_user_id uuid)
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
  if not exists (select 1 from public.profiles where id = p_other_user_id) then
    raise exception 'Không tìm thấy người dùng.';
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

revoke all on function public.get_or_create_direct_conversation(uuid) from public;
grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;

-- Bật phát sự kiện INSERT/UPDATE/DELETE của messages cho Supabase Realtime.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

notify pgrst, 'reload schema';
