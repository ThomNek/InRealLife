# Treasure IRL

> **Kết nối qua điều cùng làm, không chỉ qua điều cùng đăng.**

Treasure IRL là mạng xã hội hoạt động ngoài đời, nơi người dùng tìm những người
phù hợp thông qua các hoạt động có mục tiêu như săn kho báu, đi bộ khám phá,
thể thao và sự kiện cộng đồng.

---

## Cấu trúc dự án

```
treasureIRL/
├── docs/
│   ├── specs/                        # Đặc tả sản phẩm & UX
│   │   ├── TREASURE_IRL_PRODUCT_THEORY.txt
│   │   └── TREASURE_IRL_PRODUCT_UX_SPEC.txt
│   └── business/                     # Tài liệu kinh doanh
│       └── BMC_RuNhau_NguyenVanThom.docx
├── my_app/                           # Ứng dụng Flutter chính
│   ├── lib/                          # Mã nguồn Dart (Feature-First Architecture)
│   │   ├── app/                      # Entry point, routing, AuthListener
│   │   ├── core/                     # Theme, config, shared widgets, utils
│   │   └── features/                 # Các tính năng nghiệp vụ độc lập
│   │       ├── auth/                 #   Đăng ký, đăng nhập, AuthGate
│   │       ├── home/                 #   Trang chủ responsive
│   │       ├── activities/           #   Danh sách, chi tiết, săn cá nhân
│   │       ├── teams/                #   Đội săn, yêu cầu gia nhập
│   │       ├── chat/                 #   Chat trực tiếp & chat đội (Realtime)
│   │       ├── notifications/        #   Thông báo trong ứng dụng (Realtime)
│   │       ├── profile/              #   Hồ sơ năng lực & quyền riêng tư
│   │       ├── inventory/            #   Kho vật phẩm & chợ mảnh ghép
│   │       ├── radar/                #   Khám phá hoạt động gần bạn
│   │       ├── safety/               #   Trung tâm an toàn & báo cáo
│   │       └── posts/                #   Bài đăng có mục đích
│   ├── supabase/
│   │   ├── migrations/               # 33 migration SQL (đánh số tuần tự)
│   │   ├── preflight.sql             # Kiểm tra schema trước khi deploy
│   │   └── PRODUCTION_AUDIT_*.md    # Báo cáo kiểm toán bảo mật
│   └── test/
│       └── widget_test.dart          # Bộ test widget & tích hợp
└── README.md                         # Tệp này
```

## Chạy ứng dụng

```powershell
cd my_app
flutter pub get
flutter run -d chrome
```

Xem hướng dẫn chi tiết tại my_app/README.md.

## Tài liệu

| Tài liệu | Mô tả |
| --- | --- |
| docs/specs/TREASURE_IRL_PRODUCT_THEORY.txt | Lý thuyết sản phẩm, giả thuyết thiết kế, lộ trình |
| docs/specs/TREASURE_IRL_PRODUCT_UX_SPEC.txt | Đặc tả 18 màn hình, vòng lặp cốt lõi, luồng an toàn |
| docs/business/BMC_RuNhau_NguyenVanThom.docx | Business Model Canvas (9 khối) |
| my_app/supabase/README.md | Schema, thứ tự migration, preflight & bảo mật |
