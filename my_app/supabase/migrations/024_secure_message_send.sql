-- Gửi tin nhắn qua RPC để client không thể giả sender_id, created_at hoặc các
-- cột snapshot phục vụ inbox/notification.

create or replace function public.send_message(
  p_conversation_id uuid,
  p_content text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_content text := trim(p_content);
  new_message_id uuid;
begin
  if current_user_id is null then
    raise exception 'Bạn chưa đăng nhập.';
  end if;
  if normalized_content is null or normalized_content = '' then
    raise exception 'Tin nhắn không được để trống.';
  end if;
  if char_length(normalized_content) > 2000 then
    raise exception 'Tin nhắn không được vượt quá 2.000 ký tự.';
  end if;
  if not public.is_conversation_member(p_conversation_id) then
    raise exception 'Bạn không thuộc cuộc trò chuyện này.';
  end if;

  insert into public.messages(
    conversation_id,
    sender_id,
    content,
    created_at
  ) values (
    p_conversation_id,
    current_user_id,
    normalized_content,
    clock_timestamp()
  )
  returning id into new_message_id;

  return new_message_id;
end;
$$;

revoke all on function public.send_message(uuid, text) from public;
grant execute on function public.send_message(uuid, text) to authenticated;

-- Mọi ghi message của ứng dụng phải đi qua send_message(). RLS vẫn được giữ
-- như lớp phòng thủ bổ sung cho schema cũ và các thao tác đọc.
revoke insert on table public.messages from anon, authenticated;

comment on function public.send_message(uuid, text) is
  'QuestReal migration 024: trusted sender and server timestamp for messages.';

notify pgrst, 'reload schema';
