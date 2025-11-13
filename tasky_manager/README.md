# 🌸 Tasky Manager - Multi-Client Testing Tool

Windows Forms application để quản lý và test nhiều Flutter client đồng thời.

## ✨ Tính năng

- ✅ Start/Stop Backend Server (Node.js)
- ✅ Chọn số lượng client (1-5)
- ✅ Tự động đăng ký tài khoản test (user1@test.com → user5@test.com)
- ✅ Chạy nhiều Flutter client trên các port khác nhau
- ✅ Monitor trạng thái từng client
- ✅ Backend log realtime
- ✅ Pastel Gen Z UI theme

## 🚀 Cách sử dụng

### 1. Build và chạy (Visual Studio)

```bash
cd tasky_manager
dotnet restore
dotnet run
```

Hoặc mở `TaskyManager.csproj` trong Visual Studio 2022 và nhấn F5.

### 2. Build executable

```bash
dotnet publish -c Release -r win-x64 --self-contained
```

File `.exe` sẽ nằm trong `bin\Release\net6.0-windows\win-x64\publish\`

### 3. Sử dụng App

1. **Start Backend**: Nhấn "🚀 Start Backend" để khởi động API server
2. **Chọn số client**: Chọn 1-5 clients
3. **Start Clients**: Nhấn "▶️ Start Clients"

   - App sẽ tự động:
     - Đăng ký các tài khoản test (user1@test.com → user5@test.com, password: test123)
     - Mở Flutter app trong Chrome với các port khác nhau (9000, 9001, 9002...)
     - Hiển thị trạng thái trong bảng

4. **Tương tác giữa các client**:

   - Đăng nhập vào mỗi client với tài khoản tương ứng
   - User 1 tạo team → User 2 có thể join
   - User 1 assign task cho User 2
   - Test realtime notifications, comments, etc.

5. **Stop**: Nhấn "⏹️ Stop All Clients" để dừng tất cả

## 📋 Yêu cầu

- Windows 10/11
- .NET 6.0 Runtime
- Flutter SDK
- Node.js (cho backend)
- MySQL/Laragon (cho database)

## 🎨 Tài khoản test mặc định

| Email          | Password | Tên         |
| -------------- | -------- | ----------- |
| user1@test.com | test123  | Test User 1 |
| user2@test.com | test123  | Test User 2 |
| user3@test.com | test123  | Test User 3 |
| user4@test.com | test123  | Test User 4 |
| user5@test.com | test123  | Test User 5 |

## 🔧 Troubleshooting

- **"Backend không start được"**: Kiểm tra MySQL/Laragon đang chạy
- **"Flutter not found"**: App tự động tìm Flutter tại `D:\Setup\flutter_windows_3.35.7-stable\flutter`
- **"Port already in use"**: Đóng các Chrome instance đang chạy port 9000-9004

## 📝 TODO

- [ ] Auto-login feature (cần Flutter app hỗ trợ deeplink)
- [ ] Interaction scripts (tự động tạo team, assign task, comment)
- [ ] Performance monitoring
- [ ] Export test reports
