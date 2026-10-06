-- Các luồng tạo/tham gia/duyệt/rời đội đã có SECURITY DEFINER RPC kiểm tra
-- đầy đủ. Thu hồi ghi trực tiếp để client không thể bỏ qua transaction và tạo
-- trạng thái mồ côi/không đồng bộ bằng request tự chế.

revoke insert, update, delete
  on table public.activities,
    public.activity_members,
    public.teams,
    public.team_members,
    public.team_requests
  from authenticated;

-- Khai báo rõ quyền đọc cần cho giao diện và Realtime; RLS vẫn lọc từng dòng.
grant select
  on table public.activities,
    public.activity_members,
    public.teams,
    public.team_members,
    public.team_requests
  to authenticated;

comment on table public.teams is
  'Đội hoạt động; client chỉ đọc trực tiếp, mọi ghi phải qua RPC QuestReal.';
comment on table public.team_requests is
  'Yêu cầu tham gia; client chỉ đọc trực tiếp, gửi/duyệt/hủy qua RPC.';

notify pgrst, 'reload schema';
