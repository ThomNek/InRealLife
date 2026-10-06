# QuestReal Flutter

Ứng dụng kết nối người dùng qua hoạt động ngoài đời, đội nhóm và hành trình săn
kho báu. Backend sử dụng Supabase Auth, Postgres, RLS và Realtime.

## Tính năng cốt lõi

- Đăng ký, xác nhận email, đăng nhập, khôi phục mật khẩu và AuthGate.
- Hồ sơ cá nhân, quyền riêng tư và đồng bộ tên/avatar với Auth metadata.
- Tạo hoạt động kèm đội host, xin tham gia, duyệt, từ chối, kích và rời đội.
- Chat trực tiếp/chat đội Realtime, hộp thư và bộ đếm chưa đọc.
- Thông báo trong ứng dụng cho yêu cầu đội, kết quả duyệt và tin nhắn.
- Giao diện responsive cho Android, iOS và Web.

## Chạy ứng dụng

```powershell
flutter pub get
flutter run -d chrome
```

`lib/core/config/supabase_config.dart` đang có publishable key dành cho client.
Không đặt `service_role` key, mật khẩu database hoặc secret backend trong Flutter.
Khi dùng project Supabase khác, ưu tiên truyền cấu hình lúc build:

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## Kiểm thử và build

```powershell
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

APK được tạo tại `build/app/outputs/flutter-apk/app-release.apk`.

## Supabase

Hướng dẫn schema, thứ tự migration, preflight và checklist bảo mật nằm tại
[`supabase/README.md`](supabase/README.md). Chạy migration tăng dần đúng thứ tự;
không chạy lại mù trên production đã được tạo thủ công.

Trước khi thay đổi production:

1. Sao lưu và xác nhận đúng project Supabase.
2. Chạy `supabase/preflight.sql` (chỉ đọc).
3. Đối chiếu migration history với schema hiện có.
4. Chỉ áp dụng migration sau khi đã duyệt phạm vi thay đổi.
5. Test hai tài khoản bằng hai Chrome Profile/thiết bị khác nhau; hai tab trong
   cùng một browser profile dùng chung Supabase session.
