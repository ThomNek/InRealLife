-- Đồng bộ tên/avatar/EXP trên các vùng giao diện đang mở mà không cần F5.
-- RLS của profiles vẫn quyết định từng tài khoản được nhận dòng nào.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end $$;

notify pgrst, 'reload schema';
