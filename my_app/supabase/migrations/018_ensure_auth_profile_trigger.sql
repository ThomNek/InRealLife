-- Luôn cài trigger riêng của QuestReal để mọi Auth user mới có public.profile.
-- Một project có thể đã có trigger tên on_auth_user_created cho mục đích khác;
-- điều đó không đảm bảo trigger ấy tạo profile theo schema của QuestReal.

drop trigger if exists questreal_auth_profile_created on auth.users;

create trigger questreal_auth_profile_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

comment on trigger questreal_auth_profile_created on auth.users is
  'Tạo public.profiles cho Auth user mới; độc lập với trigger khác của project.';

notify pgrst, 'reload schema';
