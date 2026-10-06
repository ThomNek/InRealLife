-- RLS giới hạn dòng; column privileges dưới đây giới hạn thêm cột được sửa.
-- Ngăn client tự tăng EXP/level, tự xác minh hoặc sửa nội dung thông báo.

revoke insert, update on table public.profiles from authenticated;

grant insert (
  id,
  display_name,
  username,
  avatar_url,
  bio,
  city,
  interests,
  updated_at
) on table public.profiles to authenticated;

grant update (
  display_name,
  username,
  avatar_url,
  bio,
  city,
  interests,
  updated_at
) on table public.profiles to authenticated;

revoke update on table public.notifications from authenticated;
grant update (read_at) on table public.notifications to authenticated;

comment on column public.profiles.level is
  'Cột tin cậy: client không được tự sửa; chỉ backend/RPC quản trị cấp.';
comment on column public.profiles.exp is
  'Cột tin cậy: client không được tự cộng EXP.';
comment on column public.profiles.is_verified is
  'Cột tin cậy: client không được tự xác minh tài khoản.';
