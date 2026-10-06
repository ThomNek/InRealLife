-- Tự tạo public.profiles sau khi người dùng đăng ký qua Supabase Auth.
-- Migration chỉ bổ sung trigger và các profile còn thiếu, không xóa dữ liệu.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  fallback_name text;
begin
  fallback_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Người dùng'
  );

  insert into public.profiles(id, display_name)
  values (new.id, fallback_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Dùng tên riêng để không ghi đè trigger handle_new_user mà project có thể
-- đã thiết lập trước đây. Nếu cả hai tồn tại, ON CONFLICT bên trên vẫn an toàn.
drop trigger if exists questreal_auth_profile_created on auth.users;
do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'auth.users'::regclass
      and tgname = 'on_auth_user_created'
      and not tgisinternal
  ) then
    create trigger questreal_auth_profile_created
    after insert on auth.users
    for each row execute function public.handle_new_auth_user();
  end if;
end $$;

insert into public.profiles(id, display_name)
select
  u.id,
  coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'Người dùng'
  )
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
);

comment on function public.handle_new_auth_user() is
  'Tạo profile cùng UUID với auth.users khi đăng ký tài khoản mới.';

notify pgrst, 'reload schema';
