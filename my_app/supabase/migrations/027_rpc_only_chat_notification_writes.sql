-- RLS là ranh giới chính; column/table privileges là lớp phòng thủ thứ hai.
-- Client chỉ đọc trực tiếp dữ liệu chat/thông báo. Mọi ghi đi qua RPC/trigger.

revoke insert, update, delete
  on table public.conversations,
    public.conversation_members,
    public.messages,
    public.notifications
  from public, anon, authenticated;

grant select
  on table public.conversations,
    public.conversation_members,
    public.messages,
    public.notifications
  to authenticated;

comment on table public.messages is
  'Tin nhắn chỉ được tạo qua public.send_message(); client không ghi bảng trực tiếp.';
comment on table public.notifications is
  'Thông báo do trigger tạo; trạng thái đã đọc chỉ cập nhật qua RPC QuestReal.';

notify pgrst, 'reload schema';
