const express = require("express");
const pool = require("../config/db");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.use(authMiddleware);

// Get notifications for current user
router.get("/", async (req, res, next) => {
  try {
    const [notifications] = await pool.query(
      `SELECT n.*, t.title AS task_title 
       FROM notifications n
       LEFT JOIN tasks t ON t.id = n.task_id
       WHERE n.user_id = ?
       ORDER BY n.created_at DESC
       LIMIT 50`,
      [req.user.id]
    );
    res.json({ success: true, data: notifications });
  } catch (error) {
    next(error);
  }
});

// Mark notification as read
router.put("/:notificationId/read", async (req, res, next) => {
  try {
    await pool.query(
      "UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?",
      [req.params.notificationId, req.user.id]
    );
    res.json({ success: true, message: "Notification marked as read" });
  } catch (error) {
    next(error);
  }
});

// Mark all notifications as read
router.put("/read-all", async (req, res, next) => {
  try {
    await pool.query(
      "UPDATE notifications SET is_read = TRUE WHERE user_id = ?",
      [req.user.id]
    );
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
