-- Chặn request tự chế đưa nội dung quá lớn/không hợp lệ vào hoạt động và đội.
-- NOT VALID bảo toàn dữ liệu cũ nhưng vẫn kiểm tra mọi INSERT/UPDATE mới.

alter table public.activities
  drop constraint if exists activities_title_length_check,
  add constraint activities_title_length_check
    check (char_length(trim(title)) between 2 and 120) not valid,
  drop constraint if exists activities_description_length_check,
  add constraint activities_description_length_check
    check (
      description is not null
      and char_length(trim(description)) between 1 and 2000
    ) not valid,
  drop constraint if exists activities_location_name_length_check,
  add constraint activities_location_name_length_check
    check (char_length(trim(location_name)) between 2 and 160) not valid;

alter table public.teams
  drop constraint if exists teams_description_length_check,
  add constraint teams_description_length_check
    check (char_length(description) <= 2000) not valid,
  drop constraint if exists teams_meeting_area_length_check,
  add constraint teams_meeting_area_length_check
    check (char_length(meeting_area) <= 160) not valid;

alter table public.team_requests
  drop constraint if exists team_requests_message_length_check,
  add constraint team_requests_message_length_check
    check (char_length(message) <= 500) not valid;

notify pgrst, 'reload schema';
