# 🌸 Tasky - Team Task Management App

## 🚀 Cách chạy ứng dụng

### Phương pháp 1: Sử dụng file .bat (Khuyến nghị - Dễ nhất!)

1. **Đảm bảo đã cài đặt:**

   - MySQL/Laragon (đang chạy)
   - Node.js
   - Flutter SDK
   - Visual Studio Code (tùy chọn)

2. **Chạy ứng dụng:**

   - Double-click file `start_tasky.bat`
   - Script sẽ tự động:
     - Cài dependencies cho backend (nếu chưa có)
     - Khởi tạo database MySQL
     - Cài dependencies cho Flutter
     - Mở 2 terminal: Backend API và Flutter App

3. **Dừng ứng dụng:**
   - Double-click file `stop_tasky.bat`
   - Hoặc đóng các terminal window

### Phương pháp 2: Chạy thủ công

#### Bước 1: Khởi động Backend API

```bash
cd backend
npm install
npm run db:init
npm run dev
```

Backend sẽ chạy tại `http://localhost:4000`

#### Bước 2: Chạy Flutter App

```bash
cd tasky_app
flutter pub get
flutter run -d edge
```

App sẽ mở trong Edge browser.

## 📁 Cấu trúc dự án

```
Tasky/
├── backend/              # Node.js REST API
│   ├── src/
│   │   ├── controllers/  # Business logic
│   │   ├── routes/       # API endpoints
│   │   ├── config/       # Database config
│   │   └── middleware/   # Auth & error handling
│   ├── database/         # SQL schema
│   └── scripts/          # Database setup
├── tasky_app/            # Flutter mobile app
│   ├── lib/
│   │   ├── models/       # Data models
│   │   ├── providers/    # State management
│   │   ├── screens/      # UI screens
│   │   ├── services/     # API service
│   │   └── theme/        # App theme
│   └── pubspec.yaml
├── start_tasky.bat       # 🚀 Khởi động toàn bộ app
└── stop_tasky.bat        # 🛑 Dừng toàn bộ app
```

## 🔧 Cấu hình

### Backend (.env)

Tạo file `backend/.env` với nội dung:

```env
PORT=4000
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=tasky_db
JWT_SECRET=your_super_secret_key_here
```

### Database

Script sẽ tự động tạo database `tasky_db` với các bảng:

- users
- teams
- team_members
- tasks
- comments
- notifications

## 🎨 Tính năng

- ✅ Đăng ký/Đăng nhập với JWT
- ✅ Tạo và quản lý teams
- ✅ Phân công và theo dõi tasks
- ✅ Timeline với calendar view
- ✅ Comment và thảo luận nội bộ
- ✅ Pastel UI theme (Gen Z style)
- ✅ Real-time cập nhật trạng thái

## 🐛 Xử lý lỗi

**Lỗi: "Unable to find suitable Visual Studio toolchain"**

- Cài Visual Studio với workload "Desktop development with C++"
- Hoặc chạy trên Edge browser: `flutter run -d edge`

**Lỗi: "Database connection failed"**

- Đảm bảo MySQL/Laragon đang chạy
- Kiểm tra file `.env` trong thư mục `backend`
- Chạy lại `npm run db:init`

**Lỗi: "flutter not found"**

- Thêm Flutter vào PATH environment variable
- Hoặc dùng đường dẫn đầy đủ: `D:\Setup\flutter_windows_3.35.7-stable\flutter\bin\flutter`

## 📱 API Endpoints

### Authentication

- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `GET /api/auth/me` - Lấy thông tin user

### Teams

- `GET /api/teams` - Danh sách teams
- `POST /api/teams` - Tạo team mới
- `GET /api/teams/:id` - Chi tiết team
- `POST /api/teams/:id/members` - Thêm thành viên

### Tasks

- `GET /api/tasks` - Danh sách tasks
- `POST /api/tasks` - Tạo task mới
- `GET /api/tasks/:id` - Chi tiết task
- `PUT /api/tasks/:id` - Cập nhật task
- `DELETE /api/tasks/:id` - Xóa task

### Comments

- `POST /api/tasks/:taskId/comments` - Thêm comment
- `DELETE /api/tasks/:taskId/comments/:commentId` - Xóa comment

## 🎯 Tips

- Nhấn `r` trong Flutter terminal để hot reload
- Nhấn `R` để hot restart
- Nhấn `q` để thoát app
- Backend tự động reload khi sửa code (nodemon)

## 📞 Hỗ trợ

Nếu gặp vấn đề, kiểm tra:

1. MySQL/Laragon đang chạy
2. Port 4000 không bị chiếm bởi app khác
3. Flutter SDK đã được cài đúng cách
4. Dependencies đã được cài đầy đủ

---

Made with 💖 and Flutter
