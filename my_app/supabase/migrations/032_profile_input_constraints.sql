-- Validation trong Flutter chỉ phục vụ trải nghiệm và có thể bị request giả
-- bỏ qua. Các CHECK dưới đây bảo vệ dữ liệu ngay tại PostgreSQL.
-- NOT VALID giữ nguyên dữ liệu lịch sử: PostgreSQL áp dụng rule cho mọi dòng
-- mới/cập nhật nhưng không quét và không sửa các dòng đang tồn tại.

alter table public.profiles
  drop constraint if exists profiles_display_name_length_check,
  add constraint profiles_display_name_length_check
    check (char_length(trim(display_name)) between 2 and 80) not valid,
  drop constraint if exists profiles_username_format_check,
  add constraint profiles_username_format_check
    check (
      username is null
      or username ~ '^[a-z0-9_]{3,30}$'
    ) not valid,
  drop constraint if exists profiles_avatar_url_length_check,
  add constraint profiles_avatar_url_length_check
    check (avatar_url is null or char_length(avatar_url) <= 2048) not valid,
  drop constraint if exists profiles_bio_length_check,
  add constraint profiles_bio_length_check
    check (bio is null or char_length(bio) <= 500) not valid,
  drop constraint if exists profiles_city_length_check,
  add constraint profiles_city_length_check
    check (city is null or char_length(city) <= 120) not valid,
  drop constraint if exists profiles_interests_shape_check,
  add constraint profiles_interests_shape_check
    check (
      cardinality(interests) <= 20
      and array_position(interests, null) is null
      and char_length(array_to_string(interests, '')) <= 800
    ) not valid;

notify pgrst, 'reload schema';
