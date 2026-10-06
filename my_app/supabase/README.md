# Supabase setup for QuestReal

Các file trong `migrations/` được thiết kế chạy tăng dần theo thứ tự tên file.
Không bỏ qua file ở giữa và không chạy file mới trên production trước khi sao lưu
hoặc kiểm tra đúng project đang chọn.

Trước khi triển khai, chạy `preflight.sql`. File này chỉ đọc và cho biết bảng,
RPC, RLS, trigger, publication Realtime hoặc quyền thực thi nào đang thiếu/sai;
nó không sửa dữ liệu. Ở phần quyền RPC, trạng thái an toàn là
`authenticated_can_execute = true` và `anon_can_execute = false` cho mọi dòng.

Để kiểm tra toàn bộ migration mà không chạm production, chạy từ thư mục dự án:

```powershell
powershell -ExecutionPolicy Bypass -File supabase/tests/run_local.ps1
```

Script tạo PostgreSQL tạm bên trong `.tmp`, chạy integration/preflight và luôn
dọn cluster khi hoàn tất. Có thể truyền `-PgBin` hoặc `-Port` nếu máy dùng cấu
hình PostgreSQL khác. Thêm `-Quiet` để ghi kết quả chi tiết của `psql` vào log
tạm và chỉ giữ tiến độ/lỗi trên terminal; log này cũng được dọn trong `finally`.

Kết quả audit production gần nhất được lưu tại
[`PRODUCTION_AUDIT_2026-09-04.md`](PRODUCTION_AUDIT_2026-09-04.md).

## Thứ tự triển khai

1. `001_activities_teams.sql` – bảng đội/thành viên/yêu cầu.
2. `002_create_activity_with_team_rpc.sql` – tạo hoạt động và đội mặc định trong một transaction.
3. `003_team_management_rpc.sql` – RPC duyệt và kích ban đầu.
4. `004_chat_realtime.sql` – chat trực tiếp và RLS.
5. `005_team_realtime.sql` – Realtime cho yêu cầu/thành viên.
6. `006_chat_inbox_and_team_chat.sql` – hộp thư, đã đọc và chat đội.
7. `007_notifications_realtime.sql` – thông báo trong ứng dụng.
8. `008_harden_team_rls.sql` – khóa đường tự duyệt/tự nâng quyền.
9. `009_team_state_integrity.sql` – đồng bộ sức chứa và trạng thái đội.
10. `010_chat_full_inbox.sql` – hợp nhất chat trực tiếp/chat đội trong hộp thư.
11. `011_auth_profile_bootstrap.sql` – tự tạo profile khi đăng ký.
12. `012_team_leave_and_cancel.sql` – hủy yêu cầu và rời đội an toàn.
13. `013_activity_team_lists_realtime.sql` – Realtime cho danh sách hoạt động/đội.
14. `014_profile_and_notification_column_security.sql` – cấm client tự sửa EXP, level, xác minh.
15. `015_message_sender_snapshot.sql` – tên người gửi cho tin nhắn Realtime.
16. `016_create_team_atomic.sql` – tạo đội và host membership trong một transaction.
17. `017_conversation_read_clock.sql` – sửa biên thời gian khiến tin mới không được đếm.
18. `018_ensure_auth_profile_trigger.sql` – bảo đảm trigger tạo profile luôn tồn tại dù project có trigger Auth khác.
19. `019_profile_details.sql` – lưu năm sinh và thực thi quyền xem hồ sơ bằng RLS.
20. `020_profile_visibility_enforcement.sql` – chặn RPC/inbox bỏ qua quyền riêng tư hồ sơ.
21. `021_rpc_only_activity_team_writes.sql` – bắt buộc mọi ghi hoạt động/đội đi qua RPC an toàn.
22. `022_activity_requirements.sql` – lưu trình độ, vật dụng và quy tắc từ form tạo hoạt động.
23. `023_team_chat_membership_enforcement.sql` – kiểm tra membership đội hiện hành ở mọi đường đọc/gửi thông báo chat, kể cả khi cache hội thoại bị lệch.
24. `024_secure_message_send.sql` – gửi tin qua RPC với sender/thời gian do server đặt và khóa INSERT trực tiếp.
25. `025_secure_notification_read.sql` – đánh dấu thông báo đã đọc bằng thời gian server và khóa UPDATE trực tiếp.
26. `026_harden_team_request_transitions.sql` – chuẩn hóa lời nhắn và chặn từ chối/duyệt lại yêu cầu đã xử lý.
27. `027_rpc_only_chat_notification_writes.sql` – khóa toàn bộ ghi trực tiếp vào bảng chat/thông báo; chỉ RPC/trigger được ghi.
28. `028_profile_server_timestamp.sql` – đặt `profiles.updated_at` bằng đồng hồ server và chặn client giả timestamp.
29. `029_serialize_chat_read_write.sql` – serialize gửi/đọc theo phòng và khóa membership để unread đúng khi có transaction đồng thời.
30. `030_lock_anonymous_table_access.sql` – thu hồi toàn bộ quyền bảng ứng dụng khỏi `anon`; người đã đăng nhập chỉ đọc qua RLS và ghi luồng nhạy cảm qua RPC.
31. `031_profile_realtime.sql` – đưa `profiles` vào Realtime để tên, avatar và tiến độ cập nhật thống nhất trên Home.
32. `032_profile_input_constraints.sql` – giới hạn tên, username, avatar URL, bio, thành phố và sở thích ngay trên server; dùng `NOT VALID` để không sửa dữ liệu lịch sử.
33. `033_activity_team_input_constraints.sql` – giới hạn tiêu đề, mô tả, địa điểm và lời nhắn tham gia tại PostgreSQL mà không sửa dữ liệu cũ.

## Cấu hình Auth bắt buộc

Trong Supabase Dashboard, mở **Authentication → URL Configuration** và thêm:

- URL Web đang triển khai (và URL localhost dùng để phát triển).
- `io.questreal.app://login-callback/` cho Android/iOS.

Nếu chưa thêm Redirect URL, email đặt lại mật khẩu có thể mở trình duyệt nhưng
không quay lại đúng ứng dụng.

## Kiểm tra sau khi triển khai

- Tài khoản A gửi yêu cầu; host B thấy yêu cầu mà không cần tải lại trang.
- A không thể tự ghi `approved` hoặc tự thêm mình vào `team_members`.
- B duyệt A; A thấy thông báo và vào được chat đội.
- B kích A; A mất quyền đọc/gửi chat đội và sĩ số giảm.
- Tin nhắn mới tăng badge; mở phòng sẽ xóa badge của đúng phòng.
- Request giả sửa `profiles.level`, `profiles.exp`, `profiles.is_verified` bị từ chối.
- Tài khoản chưa đăng nhập (`anon`) không gọi được bất kỳ RPC nâng quyền nào.
- Client không `INSERT` trực tiếp `messages`; `send_message()` đặt sender và thời gian server.
- Client không `UPDATE` trực tiếp `notifications.read_at`; hai RPC đánh dấu đã đọc dùng thời gian server.
- `conversations`, `conversation_members`, `messages` và `notifications` chỉ cho client đọc trực tiếp.
- Đổi tên hồ sơ cập nhật cả profile và menu tài khoản sau khi quay lại.
- Chỉnh hồ sơ cập nhật `updated_at` bằng trigger server, không dùng thời gian thiết bị.
- Request bỏ qua Flutter với tên/username/bio quá giới hạn bị PostgreSQL từ chối.
- Request tạo hoạt động/đội với nội dung quá giới hạn bị PostgreSQL từ chối.

Không đặt `service_role` key trong ứng dụng Flutter. Flutter chỉ sử dụng
publishable/anon key; RLS và RPC trên Supabase mới là ranh giới bảo mật.
