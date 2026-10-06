-- Minimal Supabase-like schema used only to syntax/integration-test migrations
-- against a disposable local PostgreSQL database.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end $$;

create schema auth;

create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  raw_user_meta_data jsonb not null default '{}'::jsonb
);

-- Mô phỏng một project đã có trigger Auth khác cùng tên phổ biến. Migration
-- QuestReal vẫn phải cài trigger riêng, không được suy đoán trigger này tạo profile.
create or replace function auth.existing_user_hook()
returns trigger
language plpgsql
as $$
begin
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function auth.existing_user_hook();

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

create type public.activity_type as enum (
  'coffee', 'sport', 'treasure_hunt', 'walking', 'board_game', 'other'
);

create type public.activity_status as enum (
  'open', 'full', 'ongoing', 'completed', 'cancelled'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  username text unique,
  avatar_url text,
  bio text,
  city text,
  interests text[] not null default '{}',
  level integer not null default 1 check (level >= 1),
  exp integer not null default 0 check (exp >= 0),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  type public.activity_type not null,
  status public.activity_status not null default 'open',
  location_name text not null,
  address text,
  latitude double precision,
  longitude double precision,
  starts_at timestamptz not null,
  max_members integer not null default 4 check (max_members between 2 and 100),
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.activities enable row level security;

create policy "Authenticated users can view profiles"
  on public.profiles for select to authenticated using (true);
create policy "Users can create own profile"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);
create policy "Users can update own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

create policy "Authenticated users can view public activities"
  on public.activities for select to authenticated
  using (is_public or creator_id = auth.uid());
create policy "Users can create activities"
  on public.activities for insert to authenticated
  with check (creator_id = auth.uid());
create policy "Creators can update activities"
  on public.activities for update to authenticated
  using (creator_id = auth.uid()) with check (creator_id = auth.uid());
create policy "Creators can delete activities"
  on public.activities for delete to authenticated
  using (creator_id = auth.uid());

grant usage on schema public, auth to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;

create publication supabase_realtime;
