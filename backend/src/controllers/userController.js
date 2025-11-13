const pool = require("../config/db");

exports.listUsers = async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, user_id, name, email, avatar, role FROM users ORDER BY name"
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 2) {
      return res.json({ success: true, data: [] });
    }
    const searchTerm = `%${q.trim()}%`;
    const [rows] = await pool.query(
      "SELECT id, user_id, name, email, avatar, role FROM users WHERE name LIKE ? OR email LIKE ? OR user_id LIKE ? ORDER BY name LIMIT 20",
      [searchTerm, searchTerm, searchTerm]
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.getUserById = async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, user_id, name, email, avatar, role FROM users WHERE id = ?",
      [req.params.id]
    );
    if (rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }
    res.json({ success: true, data: rows[0] });
  } catch (error) {
    next(error);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const { name, avatar } = req.body;
    await pool.query("UPDATE users SET name = ?, avatar = ? WHERE id = ?", [
      name,
      avatar,
      req.user.id,
    ]);
    res.json({ success: true, message: "Profile updated" });
  } catch (error) {
    next(error);
  }
};

exports.uploadAvatar = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file uploaded",
      });
    }

    // Tạo URL cho avatar
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;

    // Cập nhật avatar trong database
    await pool.query("UPDATE users SET avatar = ? WHERE id = ?", [
      avatarUrl,
      req.user.id,
    ]);

    // Xóa avatar cũ nếu có
    const [users] = await pool.query("SELECT avatar FROM users WHERE id = ?", [
      req.user.id,
    ]);

    res.json({
      success: true,
      message: "Avatar uploaded successfully",
      data: { avatarUrl },
    });
  } catch (error) {
    next(error);
  }
};

exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Current password and new password are required",
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: "New password must be at least 6 characters",
      });
    }

    // Get current user with password
    const [users] = await pool.query(
      "SELECT password FROM users WHERE id = ?",
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Verify current password
    const bcrypt = require("bcrypt");
    const isMatch = await bcrypt.compare(currentPassword, users[0].password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await pool.query("UPDATE users SET password = ? WHERE id = ?", [
      hashedPassword,
      req.user.id,
    ]);

    res.json({ success: true, message: "Password changed successfully" });
  } catch (error) {
    next(error);
  }
};
