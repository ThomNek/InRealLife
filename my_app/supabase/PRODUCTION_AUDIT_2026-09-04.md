# QuestReal Supabase production audit — 2026-09-04

Audit chỉ dùng các request `GET ...?limit=0` với publishable key của ứng dụng.
Không đọc hàng dữ liệu, không gọi RPC ghi và không thay đổi production.

Đã kiểm tra và cập nhật production ngày 2026-09-04. Các phần tương thích cần
ngay cho form tạo hoạt động, inbox/chat đội và thông báo Realtime đã được áp
dụng, sau đó xác minh lại trực tiếp trong SQL Editor với kết quả 8/8 `true`.

## Bảng

| Bảng | Trạng thái |
| --- | --- |
| `profiles` | Có |
| `activities` | Có |
| `activity_members` | Có |
| `teams` | Có |
| `team_members` | Có |
| `team_requests` | Có |
| `conversations` | Có |
| `conversation_members` | Có |
| `messages` | Có |
| `notifications` | Có; đã bật Realtime |

## Cột/tính năng còn thiếu

| Kiểm tra | Kết quả production |
| --- | --- |
| `profiles.birth_year`, `profiles.profile_visibility` | Thiếu |
| `activities.skill_level`, `activities.preparation_notes` | Có |
| `conversation_members.last_read_at` | Có |
| `conversations.team_id`, `conversations.title` | Có |
| `messages.sender_display_name` | Thiếu |

## Kết luận

Production hiện đã có schema tương thích cho form hoạt động mới, inbox/tin chưa
đọc, chat đội và thông báo Realtime. Các phần quyền riêng tư hồ sơ, snapshot tên
người gửi và chuỗi hardening 023–033 vẫn cần được đối chiếu/triển khai trước khi
coi production là hoàn tất toàn bộ migration.

## Thay đổi production đã áp dụng

- Phần tương thích của `006_chat_inbox_and_team_chat.sql`.
- `007_notifications_realtime.sql` (bảng, policy, trigger và publication).
- `005_team_realtime.sql` và `013_activity_team_lists_realtime.sql` (publication
  cho yêu cầu/thành viên đội và danh sách hoạt động/đội).
- `022_activity_requirements.sql` (hai cột hoạt động và RPC 8 tham số).
- Đã xác minh: hai cột hoạt động, RPC tạo hoạt động, RPC inbox, RPC chat đội,
  bảng notifications, Realtime messages và Realtime notifications đều tồn tại.
- Đã xác minh riêng cả sáu bảng `activities`, `teams`, `team_members`,
  `team_requests`, `messages`, `notifications` đều thuộc publication
  `supabase_realtime`.

Local hiện có migration đến `033_activity_team_input_constraints.sql`. Audit REST với
publishable key không thể xác định production đã có logic mới của migration 023
(membership chat hiện hành), 024 (khóa INSERT message trực tiếp) hoặc 025
(khóa UPDATE trạng thái thông báo trực tiếp), 026 (transition yêu cầu đội) hoặc
027 (khóa toàn bộ ghi trực tiếp vào bảng chat/thông báo), 028 (timestamp hồ sơ
do server quản lý), 029 (serialize gửi/đọc chat chống race unread) hoặc 030
(thu hồi quyền bảng ứng dụng khỏi role `anon`) hoặc 031 (đồng bộ hồ sơ qua
Realtime), 032 (validation hồ sơ tại PostgreSQL) hoặc 033 (validation hoạt
động/đội tại PostgreSQL).
Sau khi được phép triển khai,
phải chạy `preflight.sql` và chỉ chấp nhận khi các cột
`team_chat_membership_hardened`, `authenticated_direct_message_insert_blocked`
`anon_direct_message_insert_blocked` và
`direct_notification_update_blocked`, `team_request_input_hardened` và
`team_request_transition_hardened` đều là `true`.

Trước khi triển khai:

1. Sao lưu project và xác nhận đúng project Supabase.
2. Chạy [`preflight.sql`](preflight.sql) trong SQL Editor.
3. Đối chiếu migration history hiện có; không chạy mù các file cũ nếu schema
   production từng được tạo thủ công.
4. Chỉ áp dụng migration sau khi người dùng cho phép thay đổi production.
5. Chạy lại preflight và checklist hai tài khoản sau triển khai.

Audit qua publishable key không thể chứng minh policy/trigger/publication hoặc
column privilege nội bộ. Các mục đó chỉ được xác nhận khi chạy `preflight.sql`
trong SQL Editor với quyền quản trị project.
