# 🚀 Quick Start Guide - Tasky 2.0

## Các thay đổi chính cần biết

### 🎯 Phân quyền mới

#### Leader (Người tạo/Quản lý team)

- ✅ Chỉnh sửa task: Tiêu đề, mô tả, assignee, deadline
- ❌ KHÔNG cập nhật status của task
- ✅ Xóa task
- ✅ Quản lý members

#### Member (Thành viên)

- ❌ KHÔNG chỉnh sửa thông tin task
- ✅ Chỉ cập nhật status: todo → doing → done
- ✅ Viết comment

### 🐢 Icon Deadline mới

Khi xem task, bạn sẽ thấy icon động vật:

| Icon | Ý nghĩa     | Thời gian còn lại |
| ---- | ----------- | ----------------- |
| 🦥   | Thư thái    | > 7 ngày          |
| 🐢   | Bình thường | 3-7 ngày          |
| 🐰   | Hơi gấp     | 1-3 ngày          |
| 🐕   | Rất gấp!    | < 24 giờ          |
| 💀   | Quá hạn     | Đã trễ            |

### 📊 Progress Bar

Mỗi task có progress bar:

- 🌤️ **Chưa làm** - 0% (màu Coral)
- 🌱 **Đang làm** - 50% (màu Lavender)
- 🌸 **Hoàn thành** - 100% (màu Mint)

### 👤 Profile mới

- **Trước**: Tab "Profile" ở bottom navigation
- **Bây giờ**: Avatar tròn góc phải → tap vào để xem profile

### 🔍 Tạo Team mới

1. Tap nút "Tạo team"
2. Nhập tên và mô tả
3. **Tìm thành viên**:
   - Gõ tên hoặc email (min 2 ký tự)
   - Chọn từ danh sách kết quả
   - Tap + để thêm
4. Tap "Tạo team"
5. → Popup animated 🎉 xuất hiện!

### 🔔 Banner Task đang có

Ở **Timeline tab**, bạn sẽ thấy:

- Banner hiện task gần deadline nhất
- Số lượng task đang active
- Tap vào để mở chi tiết

### 🎊 Notifications thú vị

App giờ có popup animations khi:

- ✅ Hoàn thành task → "Bạn giỏi quá! 🌟"
- 🎉 Tạo team → "Cùng nhau chinh phục task! 💪"
- 🗑️ Xóa task → "Tạm biệt task này nhé! 👋"
- ❌ Lỗi → Thông báo dễ thương hơn

## 💡 Tips

### Cho Member

```
1. Nhận được task → Chuyển sang "Đang làm" 🌱
2. Làm xong → Chuyển sang "Hoàn thành" 🌸
3. Popup "Bạn giỏi quá!" sẽ xuất hiện!
```

### Cho Leader

```
1. Tạo task → Assign cho member
2. Set deadline → Theo dõi icon động vật
3. Chỉnh sửa nếu cần (không đụng status)
4. Member tự update status
```

### Cho Team

```
1. Leader tạo team
2. Tìm và thêm members qua search
3. Tạo tasks cho team
4. Members tự cập nhật tiến độ
5. Theo dõi banner task đang có
```

## 🐛 Troubleshooting

### Không tìm được user khi tạo team?

- Đảm bảo gõ ít nhất 2 ký tự
- Kiểm tra backend đang chạy
- API: `GET /users/search?q=<query>`

### Icon deadline không hiện?

- Task cần có deadline
- Kiểm tra `task.deadline != null`

### Popup không tự đóng?

- Đợi 2 giây
- Hoặc tap nút "Tuyệt vời! 🚀"

### Avatar không hiện chữ?

- Cần đăng nhập với user có name
- Check `user.name.substring(0, 1)`

## 🎨 Color Reference

```dart
TaskyPalette.mint     = #B4E9D3 (Success, Complete)
TaskyPalette.lavender = #D4C5F9 (In Progress)
TaskyPalette.coral    = #FFB4A3 (Todo, Warning)
TaskyPalette.aqua     = #A8E6CF (Accent)
TaskyPalette.cream    = #FFF9F0 (Background)
TaskyPalette.midnight = #2D3142 (Text)
```

## 📱 Navigation

```
Home Screen
├── 🌈 Timeline (có banner task đang có)
├── 📋 Task của tôi
└── 🧑‍🤝‍🧑 Team

AppBar
├── "Xin chào [name] 🌸"
├── 🌙 Dark mode toggle
└── 👤 Avatar (tap → Profile)
```

## ⚡ Shortcuts

- **Tạo task nhanh**: Tap FAB button ở Timeline/My Tasks
- **Xem task gấp**: Xem banner ở Timeline
- **Update status**: Tap vào task → Chọn chip status → Save
- **Tìm user**: Tạo team → Gõ tên → Select

---

**Happy tasking! 🚀**
