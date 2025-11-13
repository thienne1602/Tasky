# Cập nhật tính năng Team Leader & Chi tiết Task

## Tóm tắt các thay đổi

### 1. Database

- Thêm vai trò `leader` vào bảng `team_members`
- Người tạo team tự động trở thành leader
- Migration đã được chạy thành công

### 2. Backend API

#### Cập nhật Controllers

**taskController.js:**

- ✅ Thêm kiểm tra quyền leader khi tạo task
- ✅ Thêm kiểm tra quyền leader khi giao task (update assigned_to)
- ✅ Trả về thông tin chi tiết: người tạo, người được giao (tên, email, avatar)

**teamController.js:**

- ✅ Người tạo team tự động có vai trò `leader` (thay vì `owner`)
- ✅ Thêm endpoint `POST /teams/:teamId/transfer-leadership` để chuyển quyền leader

#### Routes mới

```javascript
POST /teams/:teamId/transfer-leadership
Body: { newLeaderId: <user_id> }
```

### 3. Flutter App

#### Models

**task.dart:**

- ✅ Thêm các trường: `createdBy`, `creatorName`, `creatorEmail`, `creatorAvatar`
- ✅ Thêm các trường: `assigneeEmail`, `assigneeAvatar`

#### Providers

**team_provider.dart:**

- ✅ Thêm method `transferLeadership(teamId, newLeaderId)`

#### UI Components

**task_detail_screen.dart:**

- ✅ Thêm card hiển thị thông tin task với:
  - 🎨 Icon người tạo (coral color)
  - 👤 Icon người được giao (mint color)
  - 🚩 Icon trạng thái với emoji
- ✅ Layout đẹp hơn với `_TaskInfoCard` và `_InfoRow`

**team_detail_sheet.dart:**

- ✅ Hiển thị badge ⭐ cho leader
- ✅ Thành viên leader có background màu mint
- ✅ Long press vào thành viên để chuyển quyền leader
- ✅ Dialog xác nhận chuyển quyền
- ✅ Thông báo thành công/thất bại

## Tính năng mới

### 1. Phân quyền Leader

- ❌ Chỉ leader mới được tạo task
- ❌ Chỉ leader mới được giao task cho thành viên
- ✅ Thành viên thường không thể giao task

### 2. Chuyển quyền Leader

- Leader có thể chuyển quyền cho thành viên khác
- Cách sử dụng: **Long press** vào chip thành viên
- Sau khi chuyển, người cũ trở thành thành viên thường

### 3. Hiển thị chi tiết Task

- Người tạo task
- Người được giao task
- Trạng thái với icon trực quan
- Thông tin đầy đủ: tên, email, avatar

## Hướng dẫn sử dụng

### Tạo Team

1. Tạo team mới → Bạn tự động là leader (có dấu ⭐)
2. Thêm thành viên vào team
3. Chỉ bạn (leader) mới có thể tạo và giao task

### Chuyển quyền Leader

1. Mở Team Detail
2. **Long press** vào chip của thành viên muốn chuyển quyền
3. Xác nhận trong dialog
4. ✅ Thành viên đó trở thành leader mới
5. ✅ Bạn trở thành thành viên thường

### Tạo/Giao Task

1. Chỉ leader mới thấy được nút tạo task
2. Leader chọn người được giao từ danh sách thành viên
3. Thông tin người tạo tự động được lưu
4. Xem chi tiết task để thấy đầy đủ thông tin

## API Error Handling

Khi thành viên thường cố gắng tạo/giao task:

```json
{
  "success": false,
  "message": "Only team leader can create and assign tasks"
}
```

Khi người không phải leader cố chuyển quyền:

```json
{
  "success": false,
  "message": "Only team leader can transfer leadership"
}
```

## Testing

### Test Cases cần kiểm tra:

1. ✅ Tạo team mới → Kiểm tra creator là leader
2. ⏳ Leader tạo task → Thành công
3. ⏳ Thành viên thường tạo task → Bị từ chối
4. ⏳ Leader giao task → Thành công
5. ⏳ Thành viên thường giao task → Bị từ chối
6. ⏳ Chuyển quyền leader → Kiểm tra role thay đổi
7. ⏳ Xem chi tiết task → Hiển thị đầy đủ thông tin

## Lưu ý kỹ thuật

### Database

- Vai trò `owner` vẫn được hỗ trợ để backward compatible
- `leader` và `owner` được xử lý như nhau trong code

### Security

- Tất cả endpoints đều kiểm tra quyền leader trước khi thực hiện
- Sử dụng middleware `authMiddleware` để xác thực user

### UI/UX

- Long press gesture để chuyển quyền (tránh nhầm lẫn)
- Badge ⭐ rõ ràng cho leader
- Màu sắc phân biệt: mint (leader), lavender (member)
- Dialog xác nhận trước khi chuyển quyền

## Cần cải thiện thêm (Optional)

1. Thêm kiểm tra frontend - ẩn nút tạo task nếu không phải leader
2. Hiển thị tooltip "Chỉ leader mới tạo được task"
3. Thêm trang quản lý quyền trong settings
4. Log lịch sử chuyển quyền leader
5. Cho phép nhiều leader (admin role)

---

**Ngày cập nhật:** 11/11/2025
**Version:** 2.0.0
