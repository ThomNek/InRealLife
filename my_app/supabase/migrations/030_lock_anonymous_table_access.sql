-- QuestReal yêu cầu đăng nhập trước khi xem hoặc thay đổi dữ liệu ứng dụng.
-- RLS đã chặn anon theo từng dòng; migration này khóa thêm lớp table grant để
-- một policy mới viết sai trong tương lai cũng không vô tình mở dữ liệu.

revoke all privileges
  on table public.profiles,
    public.activities,
    public.activity_members,
    public.teams,
    public.team_members,
    public.team_requests,
    public.conversations,
    public.conversation_members,
    public.messages,
    public.notifications
  from public, anon;

-- Khai báo lại quyền đọc của người dùng đã đăng nhập. RLS vẫn quyết định họ
-- được nhìn thấy dòng nào; các bảng nghiệp vụ/chat chỉ ghi qua RPC bảo mật.
grant select
  on table public.profiles,
    public.activities,
    public.activity_members,
    public.teams,
    public.team_members,
    public.team_requests,
    public.conversations,
    public.conversation_members,
    public.messages,
    public.notifications
  to authenticated;

notify pgrst, 'reload schema';
