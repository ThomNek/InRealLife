-- Lưu tên hiển thị tại thời điểm gửi để dòng Realtime đủ dữ liệu render chat đội.
-- Trigger luôn ghi đè giá trị từ client nên người gửi không thể giả tên.

alter table public.messages
  add column if not exists sender_display_name text;

update public.messages m
set sender_display_name = p.display_name
from public.profiles p
where p.id = m.sender_id
  and m.sender_display_name is null;

create or replace function public.fill_message_sender_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select p.display_name into new.sender_display_name
  from public.profiles p
  where p.id = new.sender_id;

  new.sender_display_name := coalesce(new.sender_display_name, 'Người dùng');
  return new;
end;
$$;

drop trigger if exists fill_message_sender_name_trigger on public.messages;
create trigger fill_message_sender_name_trigger
before insert or update of sender_id on public.messages
for each row execute function public.fill_message_sender_name();

comment on column public.messages.sender_display_name is
  'Tên người gửi do trigger server chụp tại thời điểm gửi; không dùng để phân quyền.';

notify pgrst, 'reload schema';
