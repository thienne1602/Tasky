# Hướng dẫn sử dụng Tasky - Full CRUD Features

## 📋 Tổng quan tính năng

### ✅ Hoàn thiện CRUD cho Team

- **Create**: Tạo team mới (tự động trở thành leader)
- **Read**: Xem danh sách team, chi tiết team
- **Update**: Chỉnh sửa tên và mô tả team (chỉ leader)
- **Delete**: Xóa team (chỉ leader, sẽ xóa tất cả task)

### ✅ Hoàn thiện CRUD cho Task

- **Create**: Tạo task mới (chỉ leader)
- **Read**: Xem danh sách task, chi tiết task
- **Update**: Cập nhật task (tất cả thành viên có thể update status, chỉ leader giao task)
- **Delete**: Xóa task (tất cả thành viên)

### ✅ Quản lý thành viên

- **Add**: Thêm thành viên vào team (chỉ leader)
- **Remove**: Xóa thành viên khỏi team (chỉ leader)
- **Transfer Leadership**: Chuyển quyền leader (chỉ leader hiện tại)

---

## 🎯 Hướng dẫn chi tiết

### 1. Quản lý Team

#### 1.1 Tạo Team mới

1. Vào tab "Team"
2. Nhấn nút "+" hoặc "Tạo Team"
3. Nhập tên team (bắt buộc)
4. Nhập mô tả (tùy chọn)
5. Nhấn "Tạo"
6. ✅ Bạn tự động trở thành Leader của team

#### 1.2 Xem chi tiết Team

1. Nhấn vào card team trong danh sách
2. Màn hình hiển thị:
   - Tên và mô tả team
   - Danh sách thành viên (leader có dấu ⭐)
   - Danh sách task của team
   - Menu 3 chấm (nếu bạn là leader)

#### 1.3 Chỉnh sửa Team (chỉ Leader)

1. Mở chi tiết team
2. Nhấn menu 3 chấm (⋮) góc phải
3. Chọn "Chỉnh sửa"
4. Cập nhật tên/mô tả
5. Nhấn "Lưu"

#### 1.4 Xóa Team (chỉ Leader)

1. Mở chi tiết team
2. Nhấn menu 3 chấm (⋮)
3. Chọn "Xóa team" (màu đỏ)
4. Xác nhận trong dialog
5. ⚠️ **Lưu ý**: Tất cả task trong team sẽ bị xóa!

---

### 2. Quản lý Thành viên

#### 2.1 Thêm thành viên (chỉ Leader)

1. Mở chi tiết team
2. Nhấn nút "Thêm" ở phần Thành viên
3. Nhập email của người muốn thêm
4. Nhấn "Mời"
5. ✅ Người đó sẽ thấy team trong danh sách của họ

#### 2.2 Xóa thành viên (chỉ Leader)

1. Mở chi tiết team
2. **Long press** (giữ) vào chip thành viên muốn xóa
3. Chọn "Xóa khỏi team"
4. Xác nhận trong dialog
5. ⚠️ **Lưu ý**:
   - Không thể xóa leader
   - Task đã giao cho người này vẫn giữ nguyên

#### 2.3 Chuyển quyền Leader (chỉ Leader hiện tại)

1. Mở chi tiết team
2. **Long press** vào chip thành viên muốn chuyển quyền
3. Chọn "Chuyển quyền Leader"
4. Xác nhận trong dialog
5. ✅ Người đó trở thành leader mới
6. ✅ Bạn trở thành thành viên thường

---

### 3. Quản lý Task

#### 3.1 Tạo Task mới (chỉ Leader)

1. Vào tab "Nhiệm vụ" hoặc mở team
2. Nhấn nút "+" tạo task
3. Nhập thông tin:
   - Tiêu đề (bắt buộc)
   - Mô tả (tùy chọn)
   - Deadline (tùy chọn)
   - Trạng thái: Todo/Doing/Done
   - **Giao cho**: Chọn thành viên trong team
   - Chọn team
4. Nhấn "Tạo"
5. ✅ Task được tạo, bạn là người tạo

#### 3.2 Xem chi tiết Task

1. Nhấn vào task trong danh sách
2. Màn hình hiển thị:
   - **Người tạo**: Ai đã tạo task này
   - **Được giao cho**: Task giao cho ai
   - **Trạng thái**: Todo/Doing/Done
   - **Mô tả**: Nội dung chi tiết
   - **Deadline**: Thời hạn hoàn thành
   - **Ghi chú nội bộ**: Comments

#### 3.3 Cập nhật Task

**Tất cả thành viên có thể:**

- Thay đổi trạng thái (Todo → Doing → Done)
- Sửa mô tả
- Chỉnh deadline
- Thêm/xóa comment

**Chỉ Leader có thể:**

- Giao/chuyển giao task cho thành viên khác
- Thay đổi người được giao task

#### 3.4 Xóa Task

1. Mở chi tiết task
2. Nhấn icon thùng rác (🗑️) trên toolbar
3. Task bị xóa ngay lập tức
4. ⚠️ **Lưu ý**: Tất cả comment cũng bị xóa

---

## 🔐 Phân quyền

### Leader có thể:

✅ Tạo task mới  
✅ Giao task cho thành viên  
✅ Chuyển giao task  
✅ Thêm thành viên vào team  
✅ Xóa thành viên khỏi team  
✅ Chỉnh sửa thông tin team  
✅ Xóa team  
✅ Chuyển quyền leader  
✅ Tất cả quyền của thành viên thường

### Thành viên thường có thể:

✅ Xem tất cả task trong team  
✅ Cập nhật trạng thái task  
✅ Chỉnh sửa mô tả/deadline task  
✅ Thêm/xóa comment  
✅ Xóa task  
❌ Không thể tạo task mới  
❌ Không thể giao task cho người khác  
❌ Không thể thêm/xóa thành viên  
❌ Không thể chỉnh sửa/xóa team

---

## 💡 Tips & Tricks

### Quản lý hiệu quả

1. **Tạo team theo dự án**: Mỗi dự án một team riêng
2. **Giao task rõ ràng**: Chọn đúng người và deadline
3. **Cập nhật trạng thái thường xuyên**: Giúp theo dõi tiến độ
4. **Sử dụng comment**: Trao đổi ngay trong task

### Gesture shortcuts

- **Long press** vào thành viên → Menu hành động nhanh
- **Swipe** trên task card → Các tùy chọn nhanh
- **Pull to refresh** → Cập nhật dữ liệu mới

### Màu sắc trạng thái

- 🌤️ **Todo** (Lavender): Chưa bắt đầu
- 🌱 **Doing** (Coral): Đang thực hiện
- 🌸 **Done** (Mint): Hoàn thành

### Icon quan trọng

- ⭐ **Leader**: Người quản lý team
- 🎨 **Người tạo**: Ai tạo task
- 👤 **Được giao**: Task giao cho ai
- ⏰ **Sắp deadline**: Task cần chú ý

---

## 🐛 Xử lý lỗi

### "Only team leader can create and assign tasks"

- **Nguyên nhân**: Bạn không phải leader
- **Giải pháp**: Yêu cầu leader tạo task hoặc chuyển quyền cho bạn

### "Cannot remove team leader"

- **Nguyên nhân**: Cố xóa leader khỏi team
- **Giải pháp**: Chuyển quyền leader trước, sau đó mới xóa

### "User not found"

- **Nguyên nhân**: Email không tồn tại trong hệ thống
- **Giải pháp**: Kiểm tra lại email hoặc yêu cầu người đó đăng ký

### Lỗi UI overflow

- **Nguyên nhân**: Nội dung quá dài
- **Giải pháp**: Đã fix bằng cách giới hạn chiều cao card

---

## 📱 API Endpoints

### Team Management

```
POST   /api/teams                    - Tạo team mới
GET    /api/teams                    - Danh sách team
GET    /api/teams/:id                - Chi tiết team
PUT    /api/teams/:id                - Cập nhật team
DELETE /api/teams/:id                - Xóa team
POST   /api/teams/:id/members        - Thêm thành viên
DELETE /api/teams/:id/members        - Xóa thành viên
POST   /api/teams/:id/transfer-leadership - Chuyển quyền leader
```

### Task Management

```
POST   /api/tasks                    - Tạo task (chỉ leader)
GET    /api/tasks                    - Danh sách task
GET    /api/tasks/:id                - Chi tiết task
PUT    /api/tasks/:id                - Cập nhật task
DELETE /api/tasks/:id                - Xóa task
```

---

## 🎉 Tính năng đã hoàn thiện

✅ Full CRUD cho Team  
✅ Full CRUD cho Task  
✅ Phân quyền Leader/Member  
✅ Chuyển quyền Leader  
✅ Quản lý thành viên  
✅ Hiển thị chi tiết task (người tạo, người được giao)  
✅ UI/UX thân thiện với emoji và màu sắc  
✅ Error handling đầy đủ  
✅ Confirm dialogs cho các hành động quan trọng  
✅ Fix lỗi UI overflow  
✅ API documentation

---

**Phiên bản:** 2.0.0  
**Cập nhật:** 11/11/2025  
**Tác giả:** Tasky Team 🚀
