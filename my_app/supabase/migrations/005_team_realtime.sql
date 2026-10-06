-- Phát thay đổi yêu cầu và thành viên để trang chi tiết đội tự cập nhật.
-- RLS hiện có vẫn quyết định từng tài khoản được phép thấy dòng nào.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'team_requests'
  ) then
    alter publication supabase_realtime add table public.team_requests;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'team_members'
  ) then
    alter publication supabase_realtime add table public.team_members;
  end if;
end $$;
